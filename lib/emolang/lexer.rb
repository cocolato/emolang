# frozen_string_literal: true

require_relative 'token'

module Emolang
  # Tokenizes emolang source.
  #
  # Emoji variation selectors (U+FE0F) are ignored between tokens, so both
  # "▶" and "▶️" lex as BLOCK_BEGIN. Line comments start with 💭.
  # Julia-inspired math operators (≤ ≥ ≠ × ÷ √) are keywords mapping onto
  # the canonical operator token types.
  class Lexer
    KEYWORDS = {
      '📦' => TT::LET,
      '↩' => TT::RETURN,
      '❓' => TT::IF,
      '❗' => TT::ELSE,
      '✅' => TT::TRUE,
      '❎' => TT::FALSE,
      '🧮' => TT::FUNC,
      '🔧' => TT::MACRO,
      '💬' => TT::PRINT,
      '📖' => TT::QUASIQUOTE,
      '🔁' => TT::WHILE,
      '🛑' => TT::BREAK,
      '🔖' => TT::MARK,
      '▶' => TT::BLOCK_BEGIN,
      '⏹' => TT::BLOCK_END,
      '≤' => TT::LE,
      '≥' => TT::GE,
      '≠' => TT::NEQ,
      '×' => TT::ASTERISK,
      '÷' => TT::SLASH,
      '√' => TT::SQRT
    }.freeze

    SINGLES = %w[= ! < > + - * / % ( ) [ ] , |].freeze
    VARIATION_SELECTOR = "\uFE0F"
    # Non-ASCII word characters: emoji identifiers/keywords. U+FE0F is
    # excluded so "▶️" lexes as the keyword "▶" plus a skipped selector.
    EMOJI_WORD = /[^ -~\s\uFE0F]/

    def initialize(source)
      @src = source.tr("\r", '')
      @pos = 0
      @line = 1
    end

    def tokens
      list = []
      loop do
        token = next_token
        list << token
        break if token.type == TT::EOF
      end
      list
    end

    def next_token
      loop do
        case (char = @src[@pos])
        when nil then return token(TT::EOF, '')
        when ' ', "\t", VARIATION_SELECTOR then @pos += 1
        when '💭' then skip_comment
        when "\n" then return newline_token
        else
          type, literal = read_token(char)
          return token(type, literal)
        end
      end
    end

    private

    def token(type, literal)
      Token.new(type, literal, @line)
    end

    def newline_token
      tok = token(TT::NEWLINE, "\n")
      @pos += 1
      @line += 1
      tok
    end

    def skip_comment
      @pos += 1 while (char = @src[@pos]) && char != "\n"
    end

    def read_token(char)
      case char
      when '"' then [TT::STRING, read_string]
      when /[0-9]/ then read_number
      when /[a-zA-Z_]/ then [TT::IDENT, read_while(/[a-zA-Z0-9_]/)]
      when EMOJI_WORD then read_emoji_word
      when "'" then [TT::QUOTE, bump]
      when '~' then peek_char == '@' ? [TT::TILDE_AT, bump2] : [TT::TILDE, bump]
      when '*' then peek_char == '*' ? [TT::POW, bump2] : [TT::ASTERISK, bump]
      when '&' then peek_char == '&' ? [TT::AND, bump2] : raise_lex_error(char)
      when '|' then peek_char == '|' ? [TT::OR, bump2] : [TT::PIPE, bump]
      when '=' then peek_char == '=' ? [TT::EQ, bump2] : [TT::ASSIGN, bump]
      when '!' then peek_char == '=' ? [TT::NEQ, bump2] : [TT::BANG, bump]
      when '<' then peek_char == '=' ? [TT::LE, bump2] : [TT::LT, bump]
      when '>' then peek_char == '=' ? [TT::GE, bump2] : [TT::GT, bump]
      else SINGLES.include?(char) ? [char, bump] : raise_lex_error(char)
      end
    end

    def read_emoji_word
      # 🔖 always stands alone so "🔖🚢" lexes as MARK + IDENT("🚢").
      return [TT::MARK, bump] if @src[@pos] == '🔖'

      word = read_while(EMOJI_WORD)
      [KEYWORDS.fetch(word, TT::IDENT), word]
    end

    def read_number
      whole = read_while(/[0-9]/)
      return [TT::INT, whole] if @src[@pos] != '.' || !@src[@pos + 1]&.match?(/[0-9]/)

      fraction = read_while(/[0-9]/, @pos + 1)
      [TT::FLOAT, "#{whole}.#{fraction}"]
    end

    def read_string
      @pos += 1 # opening quote
      out = +''
      until (char = @src[@pos]) == '"'
        raise LexError, "line #{@line}: unterminated string" if char.nil? || char == "\n"

        out << char
        @pos += 1
        next unless char == '\\' && (esc = @src[@pos])

        out << esc
        @pos += 1
      end
      @pos += 1 # closing quote
      out
    end

    def read_while(regex, start = @pos)
      @pos = start
      @pos += 1 while (char = @src[@pos]) && char.match?(regex)
      @src[start...@pos]
    end

    def peek_char
      @src[@pos + 1]
    end

    def bump
      char = @src[@pos]
      @pos += 1
      char
    end

    def bump2
      pair = @src[@pos, 2]
      @pos += 2
      pair
    end

    def raise_lex_error(char)
      raise LexError, "line #{@line}: unexpected character #{char.inspect}"
    end
  end
end
