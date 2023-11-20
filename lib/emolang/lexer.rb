# frozen_string_literal: true
# typed: true

require_relative 'token'

module Emolang

  class Lexer
    extend T::Sig

    @@keywords = {
      '👴' => Emolang::TOKEN_T::LET,
      '🧮' => Emolang::TOKEN_T::FUNCTION
    }

    attr_accessor :input, :position, :read_pos, :ch

    sig {params(input: String).void}
    def initialize(input)
      @input = T.let(input, String)
      @read_pos = T.let(0, Integer)
      @position = T.let(0, Integer)
      @ch = T.let('', T.any(String, Integer))
      self.read_char
      
    end

    sig {void}
    def read_char
      if @read_pos >= @input.length
        @ch = 0  # EOF
      else
        @ch = T.must(@input[@read_pos])
      end

      @position = @read_pos
      @read_pos += 1
    end

    sig { returns(Emolang::Token) }
    def next_token
      token = nil

      while @ch != 0 and (@ch =~ /\S/).nil?
        self.read_char
      end

      case @ch
      when '='
        token = Emolang::Token.new(Emolang::TOKEN_T::ASSIGN, @ch)
      when '('
        token = Emolang::Token.new(Emolang::TOKEN_T::LPAREN, @ch)
      when ')'
        token = Emolang::Token.new(Emolang::TOKEN_T::RPAREN, @ch)
      when '{'
        token = Emolang::Token.new(Emolang::TOKEN_T::LBRACE, @ch)
      when '}'
        token = Emolang::Token.new(Emolang::TOKEN_T::RBRACE, @ch)
      when ','
        token = Emolang::Token.new(Emolang::TOKEN_T::COMMA, @ch)
      when '+'
        token = Emolang::Token.new(Emolang::TOKEN_T::PLUS, @ch)
      when 0
        token = Emolang::Token.new(Emolang::TOKEN_T::EOF, @ch)
      when /\d/
        token = Emolang::Token.new(Emolang::TOKEN_T::INT, @ch)
      else
        if self.letter? @ch
          val = self.read_identifier
          token = Emolang::Token.new(self.lookup_identifier(T.must(val)), T.must(val))
        else
          raise "Error! Unexpected char: #{@ch}"
        end
      
      end
      self.read_char
      token
    end

    sig { params(ch: T.any(String, Integer)).returns(T::Boolean) }
    def letter?(ch)
      return 0 == (ch =~ /[a-zA-Z_:👴🧮]/)
    end

    sig { returns(T.nilable(String)) }
    def read_identifier
      start_pos = @position
      if self.letter? @ch
        self.read_char
      end
      @input[start_pos..@position]
    end

    sig { params(ident: String).returns(String) }
    def lookup_identifier(ident)
      if @@keywords.key? ident
        return @@keywords[ident]
      end
      Emolang::TOKEN_T::IDENT
    end

  end
end