# frozen_string_literal: true

require_relative 'lexer'
require_relative 'ast'

module Emolang
  # Pratt parser producing Emolang::AST nodes. Statements are separated by
  # newlines; expressions use precedence climbing.
  class Parser
    LOWEST = 0
    PREFIX_PRECEDENCE = 9

    PRECEDENCES = {
      TT::OR => 2,
      TT::AND => 3,
      TT::EQ => 4, TT::NEQ => 4,
      TT::LT => 5, TT::GT => 5, TT::LE => 5, TT::GE => 5,
      TT::PLUS => 6, TT::MINUS => 6,
      TT::ASTERISK => 7, TT::SLASH => 7, TT::PERCENT => 7,
      TT::POW => 8,
      TT::LPAREN => 10, TT::LBRACKET => 11
    }.freeze

    PREFIX = {
      TT::IDENT => :parse_identifier,
      TT::INT => :parse_integer,
      TT::FLOAT => :parse_float,
      TT::TRUE => :parse_boolean,
      TT::FALSE => :parse_boolean,
      TT::STRING => :parse_string,
      TT::MARK => :parse_symbol_literal,
      TT::BANG => :parse_prefix_expression,
      TT::MINUS => :parse_prefix_expression,
      TT::SQRT => :parse_prefix_expression,
      TT::LPAREN => :parse_grouped_expression,
      TT::LBRACKET => :parse_array_literal,
      TT::IF => :parse_if_expression,
      TT::WHILE => :parse_while_expression,
      TT::BREAK => :parse_break,
      TT::FUNC => :parse_function_literal,
      TT::RETURN => :parse_return, # ↩️ is also allowed in expression position
      TT::PRINT => :parse_print, # 💬 is also allowed in expression position (macros/quotes)
      TT::QUOTE => :parse_quote,
      TT::QUASIQUOTE => :parse_quote,
      TT::TILDE => :parse_unquote,
      TT::TILDE_AT => :parse_unquote
    }.freeze

    INFIX = {
      TT::LPAREN => :parse_call_expression,
      TT::LBRACKET => :parse_index_expression
    }.freeze

    ESCAPES = { '"' => '"', '\\' => '\\', 'n' => "\n", 't' => "\t" }.freeze

    attr_reader :errors

    def initialize(lexer)
      @tokens = lexer.respond_to?(:tokens) ? lexer.tokens : lexer
      @pos = 0
      @errors = []
    end

    def parse_program
      statements = []
      until cur_type?(TT::EOF)
        skip_newlines
        break if cur_type?(TT::EOF)

        stmt = parse_statement
        statements << stmt if stmt
        advance if stmt.nil? # ensure progress on unparseable input
      end
      AST::Program.new(statements)
    end

    # Exposed for interpolation snippets and REPL helpers.
    def skip_newlines
      advance while cur_type?(TT::NEWLINE)
    end

    def cur_type?(type)
      cur.type == type
    end

    # Parses one expression from a source snippet; nil unless the snippet is
    # exactly one clean expression (used by string interpolation).
    def self.parse_expression_source(source)
      parser = new(Lexer.new(source))
      parser.skip_newlines
      expr = parser.send(:parse_expression)
      parser.skip_newlines
      expr && parser.errors.empty? && parser.cur_type?(TT::EOF) ? expr : nil
    end

    private

    def cur
      @tokens[@pos]
    end

    def advance
      tok = cur
      @pos += 1 unless tok.type == TT::EOF
      tok
    end

    def eat(type)
      return advance if cur_type?(type)

      error("expected #{type}, got #{cur.literal.inspect}")
    end

    def error(message)
      @errors << "line #{cur.line}: #{message}"
      nil
    end

    # ---- statements ----

    def parse_statement
      case cur.type
      when TT::LET then parse_let_statement
      when TT::RETURN then parse_return
      when TT::PRINT then parse_print
      when TT::BREAK then parse_break
      when TT::FUNC then parse_callable_statement(AST::FunctionLiteral)
      when TT::MACRO then parse_callable_statement(AST::MacroLiteral)
      else parse_expression_statement
      end
    end

    def parse_let_statement
      advance
      name = eat(TT::IDENT)
      return nil unless name && eat(TT::ASSIGN)

      value = parse_expression
      value && AST::LetStatement.new(AST::Identifier.new(name.literal), value)
    end

    def parse_return
      advance
      value = parse_expression
      value && AST::ReturnStatement.new(value)
    end

    def parse_print
      advance
      value = parse_expression
      value && AST::PrintStatement.new(value)
    end

    def parse_expression_statement
      expr = parse_expression
      expr && AST::ExpressionStatement.new(expr)
    end

    # Definition statement: "🧮 name |params| body" binds a name; with no
    # trailing identifier it is an anonymous callable as an expression.
    def parse_callable_statement(klass)
      advance
      if cur_type?(TT::IDENT)
        name = advance.literal
        literal = parse_callable(klass)
        return nil unless literal

        return AST::LetStatement.new(AST::Identifier.new(name), literal)
      end

      literal = parse_callable(klass)
      literal && AST::ExpressionStatement.new(literal)
    end

    # ---- expressions ----

    def parse_expression(precedence = LOWEST)
      handler = PREFIX[cur.type]
      return error("unexpected #{cur.literal.inspect}") unless handler

      left = send(handler)
      return nil unless left

      while (prec = PRECEDENCES[cur.type]) && precedence < prec
        left = send(INFIX.fetch(cur.type, :parse_infix_expression), left)
        return nil unless left
      end
      left
    end

    def parse_identifier
      AST::Identifier.new(advance.literal)
    end

    def parse_integer
      AST::IntegerLiteral.new(advance.literal.to_i)
    end

    def parse_float
      AST::FloatLiteral.new(advance.literal.to_f)
    end

    def parse_boolean
      AST::BooleanLiteral.new(advance.type == TT::TRUE)
    end

    def parse_symbol_literal
      advance # 🔖
      AST::SymbolLiteral.new(advance.literal.to_sym)
    end

    def parse_grouped_expression
      advance
      expr = parse_expression
      return nil if expr.nil? || eat(TT::RPAREN).nil?

      expr
    end

    def parse_prefix_expression
      op = advance.type
      right = parse_expression(PREFIX_PRECEDENCE)
      right && AST::PrefixExpression.new(op, right)
    end

    # Operators are stored canonically by token type ("×" becomes "*"), so
    # emoji math symbols evaluate identically to their ASCII spellings.
    # "**" is right-associative: parse its right side one level looser.
    def parse_infix_expression(left)
      op = advance.type
      precedence = op == TT::POW ? PRECEDENCES[op] - 1 : PRECEDENCES[op]
      right = parse_expression(precedence)
      right && AST::InfixExpression.new(op, left, right)
    end

    def parse_while_expression
      advance
      condition = parse_expression
      return nil unless condition

      body = parse_block
      body && AST::WhileExpression.new(condition, body)
    end

    def parse_break
      advance
      AST::BreakStatement.new(nil)
    end

    def parse_if_expression
      advance
      condition = parse_expression
      return nil unless condition

      consequence = parse_block
      return nil unless consequence

      boundary = @pos
      skip_newlines
      alternative = nil
      if cur_type?(TT::ELSE)
        advance
        alternative = block_or_compact_body
        return nil unless alternative
      else
        @pos = boundary
      end
      AST::IfExpression.new(condition, consequence, alternative)
    end

    def parse_block
      return nil if eat(TT::BLOCK_BEGIN).nil?

      parse_block_body
    end

    def parse_block_body
      statements = []
      loop do
        skip_newlines
        break if cur_type?(TT::BLOCK_END) || cur_type?(TT::EOF)

        stmt = parse_statement
        statements << stmt if stmt
        advance if stmt.nil?
      end
      return nil if eat(TT::BLOCK_END).nil?

      AST::BlockStatement.new(statements)
    end

    def parse_function_literal
      advance
      parse_callable(AST::FunctionLiteral)
    end

    # "🧮 |params| ▶️ body ⏹️" or the compact "🧮 |params| expr".
    def parse_callable(klass)
      params = cur_type?(TT::PIPE) ? parse_parameters : []
      return nil unless params

      body = block_or_compact_body
      body && klass.new(params, body)
    end

    # A ▶️...⏹️ block, or a single expression wrapped into one.
    def block_or_compact_body
      return parse_block if cur_type?(TT::BLOCK_BEGIN)

      expr = parse_expression
      expr && AST::BlockStatement.new([AST::ExpressionStatement.new(expr)])
    end

    def parse_parameters
      advance # |
      params = []
      until cur_type?(TT::PIPE) || cur_type?(TT::EOF)
        name = eat(TT::IDENT)
        return nil unless name

        params << AST::Identifier.new(name.literal)
        break if cur_type?(TT::PIPE)

        return nil if eat(TT::COMMA).nil?
      end
      return nil if eat(TT::PIPE).nil?

      params
    end

    def parse_call_expression(callee)
      advance # (
      args = parse_comma_list(TT::RPAREN)
      return nil if args.nil? || eat(TT::RPAREN).nil?

      AST::CallExpression.new(callee, args)
    end

    def parse_index_expression(left)
      advance # [
      index = parse_expression
      return nil if index.nil? || eat(TT::RBRACKET).nil?

      AST::IndexExpression.new(left, index)
    end

    def parse_array_literal
      advance # [
      elements = parse_comma_list(TT::RBRACKET)
      return nil if elements.nil? || eat(TT::RBRACKET).nil?

      AST::ArrayLiteral.new(elements)
    end

    def parse_comma_list(closing)
      items = []
      return items if cur_type?(closing) || cur_type?(TT::EOF)

      loop do
        item = parse_expression
        return nil unless item

        items << item
        break if cur_type?(closing)

        return nil if eat(TT::COMMA).nil?

        break if cur_type?(closing) || cur_type?(TT::EOF)
      end
      items
    end

    # ---- strings, interpolation, quoting ----

    def parse_string
      raw = advance.literal
      parts = string_parts(raw)
      parts && AST::StringLiteral.new(parts)
    end

    def string_parts(raw)
      parts = [+'']
      i = 0
      while i < raw.length
        ch = raw[i]
        if ch == '\\' && ESCAPES.key?(raw[i + 1])
          parts.last << ESCAPES[raw[i + 1]]
          i += 2
        elsif ch == '\\' && raw[i + 1] == '#' && raw[i + 2] == '{'
          parts.last << '#{'
          i += 3
        elsif ch == '#' && raw[i + 1] == '{'
          return nil unless add_interpolation(parts, raw, i)

          i = raw.index('}', i + 2) + 1
        else
          parts.last << ch
          i += 1
        end
      end
      parts
    end

    def add_interpolation(parts, raw, start)
      closing = raw.index('}', start + 2)
      return error('unterminated interpolation') unless closing

      snippet = raw[(start + 2)...closing]
      expr = self.class.parse_expression_source(snippet)
      return error("invalid interpolation: #{snippet.inspect}") unless expr

      parts << expr << +''
    end

    def parse_quote
      template = advance.type == TT::QUASIQUOTE
      expr = parse_expression(PREFIX_PRECEDENCE)
      expr && AST::QuoteExpression.new(expr, template)
    end

    def parse_unquote
      splice = advance.type == TT::TILDE_AT
      expr = parse_expression(PREFIX_PRECEDENCE)
      expr && AST::UnquoteExpression.new(expr, splice)
    end
  end
end
