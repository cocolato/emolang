# frozen_string_literal: true

require_relative 'ast'
require_relative 'obj'

module Emolang
  # Lexical environment with parent chain (closures capture their Env).
  class Env
    def initialize(outer = nil)
      @store = {}
      @outer = outer
    end

    def get(name)
      @store.fetch(name) { @outer ? @outer.get(name) : Obj::Error.new("identifier not found: #{name}") }
    end

    def set(name, value)
      @store[name] = value
    end

    # Global environment with builtin functions (🔮 eval, 🚀 apply).
    def self.root
      env = new
      env.set('🔮', Obj::Builtin.new('eval', lambda { |e, data|
        Evaluator.eval_data(data, e)
      }))
      env.set('🚀', Obj::Builtin.new('apply', lambda { |e, fn, args|
        if args.is_a?(Array)
          Evaluator.apply(fn, args, e)
        else
          Obj::Error.new("apply expects an array, got #{Obj.display(args)}")
        end
      }))
      env
    end
  end

  # Tree-walking evaluator. Errors are values (Obj::Error) that propagate
  # up, Monkey-style; no Ruby exceptions escape for language-level errors.
  module Evaluator
    module_function

    def eval_node(node, env)
      case node
      when AST::Program then finish_scope(eval_statements(node.statements, env))
      when AST::BlockStatement then eval_statements(node.statements, env)
      when AST::ExpressionStatement then eval_node(node.expression, env)
      when AST::LetStatement
        value = eval_node(node.value, env)
        return value if stopped?(value)

        env.set(node.name.name, value)
        nil
      when AST::ReturnStatement
        value = eval_node(node.value, env)
        return value if stopped?(value)

        Obj::ReturnValue.new(value)
      when AST::PrintStatement
        value = eval_node(node.value, env)
        return value if stopped?(value)

        puts Obj.display(value)
        nil
      when AST::Identifier then env.get(node.name)
      when AST::IntegerLiteral, AST::FloatLiteral, AST::BooleanLiteral, AST::SymbolLiteral then node.value
      when AST::StringLiteral then eval_string(node, env)
      when AST::ArrayLiteral then map_values(node.elements) { |element| eval_node(element, env) }
      when AST::FunctionLiteral then Obj::Function.new(node.parameters, node.body, env)
      when AST::MacroLiteral then Obj::Macro.new(node.parameters, node.body, env)
      when AST::PrefixExpression then eval_prefix(node, env)
      when AST::InfixExpression then eval_infix(node, env)
      when AST::IfExpression then eval_if(node, env)
      when AST::WhileExpression then eval_while(node, env)
      when AST::BreakStatement then Obj::Break.new(nil)
      when AST::CallExpression then eval_call(node, env)
      when AST::IndexExpression then eval_index(node, env)
      when AST::QuoteExpression then ast_to_data(node.expression, env, template: node.template)
      when AST::UnquoteExpression then Obj::Error.new('unquote outside quasiquote')
      else Obj::Error.new("cannot evaluate #{node.class}")
      end
    end

    def eval_statements(statements, env)
      result = nil
      statements.each do |stmt|
        result = eval_node(stmt, env)
        return result if stopped?(result)
      end
      result
    end

    def eval_while(node, env)
      loop do
        condition = eval_node(node.condition, env)
        break if condition.is_a?(Obj::Break)
        return condition if stopped?(condition)
        break unless truthy?(condition)

        result = eval_node(node.body, env)
        break if result.is_a?(Obj::Break)
        return result if stopped?(result)
      end
      nil
    end

    def eval_if(node, env)
      condition = eval_node(node.condition, env)
      return condition if stopped?(condition)

      if truthy?(condition)
        eval_node(node.consequence, env)
      elsif node.alternative
        eval_node(node.alternative, env)
      end
    end

    def eval_call(node, env)
      callee = eval_node(node.callee, env)
      return callee if stopped?(callee)

      args = map_values(node.arguments) do |arg|
        callee.is_a?(Obj::Macro) ? ast_to_data(arg, env) : eval_node(arg, env)
      end
      return args if stopped?(args)

      apply(callee, args, env)
    end

    def apply(function, args, env)
      case function
      when Obj::Builtin then call_builtin(function, env, args)
      when Obj::Function, Obj::Macro
        if args.length != function.parameters.length
          expected = function.parameters.length
          return Obj::Error.new("wrong number of arguments: given #{args.length}, expected #{expected}")
        end

        scope = Env.new(function.env)
        function.parameters.zip(args).each { |param, value| scope.set(param.name, value) }
        result = finish_scope(eval_node(function.body, scope))
        return result if stopped?(result) || function.is_a?(Obj::Function)

        eval_data(result, env)
      else Obj::Error.new("not a function: #{Obj.display(function)}")
      end
    end

    def call_builtin(builtin, env, args)
      builtin.fn.call(env, *args)
    rescue ArgumentError => e
      Obj::Error.new("#{builtin.name}: #{e.message}")
    end

    # Both eval and macro expansion run decoded code in the caller's environment.
    def eval_data(data, env)
      ast = data_to_ast(data)
      stopped?(ast) ? ast : eval_node(ast, env)
    end

    def finish_scope(result)
      return Obj::Error.new('break outside loop') if result.is_a?(Obj::Break)

      result.is_a?(Obj::ReturnValue) ? result.value : result
    end

    def eval_prefix(node, env)
      value = eval_node(node.right, env)
      return value if stopped?(value)

      case node.operator
      when '!' then !truthy?(value)
      when '-'
        return type_unsupported("operator '-'", value) unless value.is_a?(Numeric)

        -value
      when '√'
        return type_unsupported('operator √', value) unless value.is_a?(Numeric)
        return Obj::Error.new('√ of negative number') if value.negative?

        Math.sqrt(value)
      end
    end

    # && and || short-circuit and yield booleans; other operators evaluate
    # both sides first.
    def eval_infix(node, env)
      operator = node.operator
      left = eval_node(node.left, env)
      return left if stopped?(left)

      return false if operator == '&&' && !truthy?(left)
      return true if operator == '||' && truthy?(left)

      right = eval_node(node.right, env)
      return right if stopped?(right)

      case operator
      when '&&', '||' then truthy?(right)
      when '==' then left == right
      when '!=' then left != right
      when '+'
        if pair_of?(left, right, Numeric) || pair_of?(left, right, String) || pair_of?(left, right, Array)
          left + right
        else
          type_mismatch(operator, left, right)
        end
      when '-', '*', '/', '%', '**', '<', '>', '<=', '>='
        return type_mismatch(operator, left, right) unless pair_of?(left, right, Numeric)
        if ['/', '%'].include?(operator) && right.is_a?(Integer) && right.zero?
          return Obj::Error.new('division by zero')
        end

        begin
          result = left.public_send(operator, right)
          result.is_a?(Complex) ? Obj::Error.new('complex numbers are not supported') : result
        rescue ZeroDivisionError
          Obj::Error.new('division by zero')
        end
      else
        type_mismatch(operator, left, right)
      end
    end

    def eval_index(node, env)
      left = eval_node(node.left, env)
      return left if stopped?(left)

      index = eval_node(node.index, env)
      return index if stopped?(index)

      return left[index] if left.is_a?(Array) && index.is_a?(Integer)

      Obj::Error.new("index not supported: #{Obj.display(left)}[#{Obj.display(index)}]")
    end

    def eval_string(node, env)
      node.parts.map do |part|
        next part if part.is_a?(String)

        value = eval_node(part, env)
        return value if stopped?(value)

        Obj.display(value)
      end.join
    end

    def truthy?(value)
      !(value.nil? || value == false)
    end

    def stopped?(value)
      value.is_a?(Obj::Error) || value.is_a?(Obj::ReturnValue) || value.is_a?(Obj::Break)
    end

    # Stop before evaluating later items or embedding control/error values in data.
    def map_values(items)
      items.map do |item|
        value = yield item
        return value if stopped?(value)

        value
      end
    end

    def type_mismatch(operator, left, right)
      Obj::Error.new("type mismatch: #{Obj.display(left)} #{operator} #{Obj.display(right)}")
    end

    def type_unsupported(operator, value)
      Obj::Error.new("#{operator} not supported: #{Obj.display(value)}")
    end

    def pair_of?(left, right, klass)
      left.is_a?(klass) && right.is_a?(klass)
    end

    # ---- Lisp layer: AST ⇄ plain data ----
    #
    # Data language (what quote produces and eval/macros consume):
    #   atoms     Integer, String, true/false, Symbol
    #   lists     tagged arrays: [:+, a, b], [:call, f, args...],
    #             [:if, cond, then, else?], [:do, stmts...],
    #             [:let, :name, value], [:return, v], [:print, v],
    #             [:fn, [:params], body], [:macro, [:params], body],
    #             [:index, left, i], [:str, parts...], [:quote, expr]

    def ast_to_data(node, env, template: false)
      parts = case node
              when String, Symbol, Array then return node # literal tag/parameter metadata
              when AST::IntegerLiteral, AST::FloatLiteral, AST::BooleanLiteral, AST::SymbolLiteral
                return node.value
              when AST::Identifier then return node.name.to_sym
              when AST::StringLiteral
                return node.parts.join if node.parts.all?(String)

                [:str, *node.parts]
              when AST::ArrayLiteral then return array_to_data(node.elements, env, template: template)
              when AST::PrefixExpression then [node.operator.to_sym, node.right]
              when AST::InfixExpression then [node.operator.to_sym, node.left, node.right]
              when AST::ExpressionStatement then return ast_to_data(node.expression, env, template: template)
              when AST::ReturnStatement then [:return, node.value]
              when AST::PrintStatement then [:print, node.value]
              when AST::LetStatement then [:let, node.name.name.to_sym, node.value]
              when AST::BlockStatement then [:do, *node.statements]
              when AST::IfExpression then [:if, node.condition, node.consequence, *[node.alternative].compact]
              when AST::WhileExpression then [:while, node.condition, node.body]
              when AST::BreakStatement then [:break]
              when AST::FunctionLiteral, AST::MacroLiteral
                tag = node.is_a?(AST::FunctionLiteral) ? :fn : :macro
                [tag, node.parameters.map { |p| p.name.to_sym }, node.body]
              when AST::CallExpression then [:call, node.callee, *node.arguments]
              when AST::IndexExpression then [:index, node.left, node.index]
              when AST::QuoteExpression
                template = false
                [:quote, node.expression]
              when AST::UnquoteExpression then return unquote(node, env, template: template)
              else return Obj::Error.new("cannot quote #{node.class}")
              end
      map_values(parts) { |part| ast_to_data(part, env, template: template) }
    end

    def array_to_data(elements, env, template:)
      out = []
      elements.each do |element|
        if template && element.is_a?(AST::UnquoteExpression) && element.splice
          value = eval_node(element.expression, env)
          return value if stopped?(value)

          return Obj::Error.new('splice expects an array') unless value.is_a?(Array)

          out.concat(value)
        else
          item = ast_to_data(element, env, template: template)
          return item if stopped?(item)

          out << item
        end
      end
      out
    end

    def unquote(node, env, template:)
      return Obj::Error.new('unquote outside quasiquote') unless template
      return Obj::Error.new('splice outside array literal') if node.splice

      eval_node(node.expression, env)
    end

    INFIX_TAGS = %i[+ - * / % ** < > <= >= == != && ||].freeze
    PREFIX_TAGS = { :'!' => '!', :√ => '√', :sqrt => '√' }.freeze
    private_constant :INFIX_TAGS, :PREFIX_TAGS

    def data_to_ast(data)
      case data
      when Integer then AST::IntegerLiteral.new(data)
      when Float then AST::FloatLiteral.new(data)
      when String then AST::StringLiteral.new([data])
      when true, false then AST::BooleanLiteral.new(data)
      when Symbol then AST::Identifier.new(data.to_s)
      when Array then list_to_ast(data)
      else Obj::Error.new("cannot evaluate as code: #{Obj.display(data)}")
      end
    end

    def list_to_ast(list)
      head = list.first
      return tagged_node(head, list) if head.is_a?(Symbol)

      nodes = map_data(list)
      return nodes if stopped?(nodes)

      AST::ArrayLiteral.new(nodes)
    end

    def tagged_node(head, list)
      case head
      when :!, :√, :sqrt
        nodes = map_data(list[1..])
        return nodes if stopped?(nodes)

        return arity_error(head, 2, list) unless nodes.length == 1

        AST::PrefixExpression.new(PREFIX_TAGS[head], nodes.first)
      when *INFIX_TAGS
        nodes = map_data(list[1..])
        return nodes if stopped?(nodes)

        return AST::PrefixExpression.new('-', nodes.first) if head == :- && nodes.length == 1
        return arity_error(head, 3, list) unless nodes.length == 2

        AST::InfixExpression.new(head.to_s, nodes[0], nodes[1])
      when :call
        nodes = map_data(list[1..])
        return nodes if stopped?(nodes)

        return arity_error(head, 2, list) if nodes.empty?

        AST::CallExpression.new(nodes.first, nodes[1..])
      when :array, :do
        nodes = map_data(list[1..])
        return nodes if stopped?(nodes)

        head == :array ? AST::ArrayLiteral.new(nodes) : AST::BlockStatement.new(nodes)
      when :if
        return arity_error(head, '3 or 4', list) unless [3, 4].include?(list.length)

        nodes = map_data(list[1..])
        return nodes if stopped?(nodes)

        alternative = nodes.length == 3 ? block_from(nodes[2]) : nil
        AST::IfExpression.new(nodes[0], block_from(nodes[1]), alternative)
      when :let
        return Obj::Error.new('let expects [:let, :name, value]') unless list.length == 3 && list[1].is_a?(Symbol)

        value = data_to_ast(list[2])
        return value if stopped?(value)

        AST::LetStatement.new(AST::Identifier.new(list[1].to_s), value)
      when :return, :print
        return arity_error(head, 2, list) unless list.length == 2

        value = data_to_ast(list[1])
        return value if stopped?(value)

        head == :return ? AST::ReturnStatement.new(value) : AST::PrintStatement.new(value)
      when :while
        return arity_error(head, 3, list) unless list.length == 3

        nodes = map_data(list[1..])
        return nodes if stopped?(nodes)

        AST::WhileExpression.new(nodes[0], block_from(nodes[1]))
      when :break then AST::BreakStatement.new(nil)
      when :fn, :macro
        unless list.length == 3 && list[1].is_a?(Array) && list[1].all?(Symbol)
          return Obj::Error.new("#{head} expects [:#{head}, [:params], body]")
        end

        body = data_to_ast(list[2])
        return body if stopped?(body)

        params = list[1].map { |p| AST::Identifier.new(p.to_s) }
        klass = head == :fn ? AST::FunctionLiteral : AST::MacroLiteral
        klass.new(params, block_from(body))
      when :index
        nodes = map_data(list[1..])
        return nodes if stopped?(nodes)

        return arity_error(head, 3, list) unless nodes.length == 2

        AST::IndexExpression.new(nodes[0], nodes[1])
      when :str
        parts = map_values(list[1..]) { |d| d.is_a?(String) ? d : data_to_ast(d) }
        return parts if stopped?(parts)

        AST::StringLiteral.new(parts)
      when :quote
        return arity_error(head, 2, list) unless list.length == 2

        inner = data_to_ast(list[1])
        return inner if stopped?(inner)

        AST::QuoteExpression.new(inner, false)
      else
        Obj::Error.new("unknown list head: #{Obj.display(head)}")
      end
    end

    def map_data(list)
      map_values(list) { |data| data_to_ast(data) }
    end

    def arity_error(head, expected, list)
      Obj::Error.new("wrong arity for :#{head}: expected #{expected} elements, got #{list.length}")
    end

    def block_from(node)
      node.is_a?(AST::BlockStatement) ? node : AST::BlockStatement.new([node])
    end
  end
end
