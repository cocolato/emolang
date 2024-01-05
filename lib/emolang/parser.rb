# frozen_string_literal: true
# typed: true

require_relative 'stdlib'
require_relative 'token'
require_relative 'lexer'
require_relative 'ast'

module Emolang
  class Parser
    include Emolang::StdLib

    def initialize(filename)
      @filename = filename || raise(ArgumentError, 'Invalid file name!')
    end

    def execute
      data = File.read(@filename)

      data.gsub!(/#{BLOCK_BEGIN}/) { 'do' }
      data.gsub!(/#{BLOCK_END}/) { 'end' }

      Binding.eval(data)
    end
  end

  class EParser
    extend T::Sig
    def initialize(lexer)
      @l = T.let(lexer, Lexer)
      @cur_token = T.let(Token.new(TokenTypeEnum::NIL, ''), Token)
      @peek_token = T.let(Token.new(TokenTypeEnum::NIL, ''), Token)
      next_token
      next_token
    end

    sig { void }
    def next_token
      @cur_token = @peek_token
      @peek_token = @l.next_token
    end

    sig { returns(AST::Program) }
    def parse_program
      program = AST::Program.new

      loop do
        break if @cur_token.type == TokenTypeEnum::EOF

        stmt = parse_statement
        program.statements.append(stmt) unless stmt.nil?
        next_token
      end
      program
    end

    sig { returns(T.nilable(AST::Statement)) }
    def parse_statement
      case @cur_token.type

      when TokenTypeEnum::LET
        parse_let_statement
      end
    end

    sig { returns(T.nilable(AST::Statement)) }
    def parse_let_statement
      stmt = AST::LetStatement.new(@cur_token)

      return nil unless expect_peek TokenTypeEnum::IDENT

      stmt.name = AST::Identifier.new(@cur_token, @cur_token.literal)

      return nil unless expect_peek TokenTypeEnum::ASSIGN

      loop do
        break if @cur_token.type == TokenTypeEnum::SEMICOLON

        next_token
      end

      stmt
    end

    def expect_peek(type)
      return false unless peek_token_is type

      next_token
      true
    end

    def peek_token_is(type)
      @peek_token.type == type
    end

    def cur_token_is(type)
      @cur_token == type
    end
  end
end
