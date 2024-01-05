# frozen_string_literal: true
# typed: true

require_relative 'token'

module Emolang
  # Lexer
  class Lexer
    extend T::Sig

    class << self
      # rubocop:disable Style/ClassVars
      @@keywords = {
        'let' => Emolang::TokenTypeEnum::LET,
        'func' => Emolang::TokenTypeEnum::FUNCTION,
        'if' => Emolang::TokenTypeEnum::IF,
        'else' => Emolang::TokenTypeEnum::ELSE,
        'true' => Emolang::TokenTypeEnum::TRUE,
        'false' => Emolang::TokenTypeEnum::FALSE,
        'return' => Emolang::TokenTypeEnum::RETURN
      }
      # rubocop:enable Style/ClassVars
    end

    attr_accessor :input, :position, :read_pos, :ch

    sig { params(input: String).void }
    def initialize(input)
      @input = T.let(input, String)
      @read_pos = T.let(0, Integer)
      @position = T.let(0, Integer)
      @ch = T.let('', String)
      read_char
    end

    sig { void }
    def read_char
      @position = @read_pos
      @ch = @read_pos >= @input.length ? '\0' : T.must(@input[@read_pos])

      @read_pos += 1
    end

    sig { returns(String) }
    def peek_char
      if @read_pos >= @input.length
        '\0'
      else
        T.must(@input[@read_pos])
      end
    end

    sig { returns(Emolang::Token) }
    def next_token
      read_char until (@ch =~ /\s/).nil? || @ch == '\0'

      if (token = pattern_match(@ch)).nil?
        if letter? @ch
          val = read_identifier
          return Emolang::Token.new(lookup_identifier(val), val)
        elsif digit? @ch
          val = read_interger
          return Emolang::Token.new(Emolang::TokenTypeEnum::INT, val)
        else
          raise "Error! Unexpected char: #{@ch}"
        end
      end
      read_char
      token
    end

    # rubocop:disable Metrics
    sig { params(char: String).returns(T.nilable(Emolang::Token)) }
    def pattern_match(char)
      case char
      when '='
        if peek_char == '='
          read_char
          Emolang::Token.new(Emolang::TokenTypeEnum::EQ, '==')
        else
          Emolang::Token.new(Emolang::TokenTypeEnum::ASSIGN, char)
        end
      when '('
        Emolang::Token.new(Emolang::TokenTypeEnum::LPAREN, char)
      when ')'
        Emolang::Token.new(Emolang::TokenTypeEnum::RPAREN, char)
      when '{'
        Emolang::Token.new(Emolang::TokenTypeEnum::LBRACE, char)
      when '}'
        Emolang::Token.new(Emolang::TokenTypeEnum::RBRACE, char)
      when ','
        Emolang::Token.new(Emolang::TokenTypeEnum::COMMA, char)
      when '+'
        Emolang::Token.new(Emolang::TokenTypeEnum::PLUS, char)
      when '-'
        Emolang::Token.new(Emolang::TokenTypeEnum::MINUS, char)
      when '*'
        Emolang::Token.new(Emolang::TokenTypeEnum::ASTERISK, char)
      when '/'
        Emolang::Token.new(Emolang::TokenTypeEnum::SLASH, char)
      when '%'
        Emolang::Token.new(Emolang::TokenTypeEnum::MOD, char)
      when '>'
        Emolang::Token.new(Emolang::TokenTypeEnum::GT, char)
      when '<'
        Emolang::Token.new(Emolang::TokenTypeEnum::LT, char)
      when '!'
        if peek_char == '='
          read_char
          Emolang::Token.new(Emolang::TokenTypeEnum::NEQ, '!=')
        else
          Emolang::Token.new(Emolang::TokenTypeEnum::BANG, char)
        end
      when '|'
        Emolang::Token.new(Emolang::TokenTypeEnum::PIPE, char)
      when ';'
        Emolang::Token.new(Emolang::TokenTypeEnum::SEMICOLON, char)
      when "\u0000"
        Emolang::Token.new(Emolang::TokenTypeEnum::EOF, char)
      when '\0'
        Emolang::Token.new(Emolang::TokenTypeEnum::EOF, char)
      end
    end
    # rubocop:enable Metrics

    sig { params(char: String).returns(T::Boolean) }
    def letter?(char)
      !(char =~ /[a-zA-Z_:👴🧮]/).nil? and char != '\0'
    end

    sig { params(char: String).returns(T::Boolean) }
    def digit?(char)
      !(char =~ /[0-9]/).nil? and char != '\0'
    end

    sig { returns(String) }
    def read_interger
      start_pos = @position
      read_char while digit? @ch
      T.must(@input[start_pos...@position])
    end

    sig { returns(String) }
    def read_identifier
      start_pos = @position
      read_char while letter? @ch
      T.must(@input[start_pos...@position])
    end

    sig { params(ident: String).returns(String) }
    def lookup_identifier(ident)
      return @@keywords[ident] if @@keywords.key? ident

      Emolang::TokenTypeEnum::IDENT
    end
  end
end
