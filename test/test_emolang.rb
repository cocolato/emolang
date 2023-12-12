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
end
