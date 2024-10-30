# frozen_string_literal: true
# typed: true

require 'minitest/autorun'

require 'emolang'

class TestToken < Minitest::Test
  def test_next_token
    input = '=+(){},'

    tests = [
      [Emolang::TokenTypeEnum::ASSIGN, '='],
      [Emolang::TokenTypeEnum::PLUS, '+'],
      [Emolang::TokenTypeEnum::LPAREN, '('],
      [Emolang::TokenTypeEnum::RPAREN, ')'],
      [Emolang::TokenTypeEnum::LBRACE, '{'],
      [Emolang::TokenTypeEnum::RBRACE, '}'],
      [Emolang::TokenTypeEnum::COMMA, ',']
    ]

    lexer = Emolang::Lexer.new(input)
    tests.each do |test|
      token = lexer.next_token
      assert_equal(test[0], token.type)
      assert_equal(test[1], token.literal)
    end
  end

  def test_parse_let
    input = 'let a = 1;'
    lexer = Emolang::Lexer.new(input)
    parser = Emolang::EParser.new(lexer)
    parser.parse_program
    assert_equal(parser.errors, [])
  end
end
