# frozen_string_literal: true
# typed: true

require "minitest/autorun"

require "emolang"
 
class TestToken < Minitest::Test
  def test_next_token
    input = '=+(){},'

    tests = [
      [Emolang::TOKEN_T::ASSIGN, '='],
      [Emolang::TOKEN_T::PLUS, '+'],
      [Emolang::TOKEN_T::LPAREN, '('],
      [Emolang::TOKEN_T::RPAREN, ')'],
      [Emolang::TOKEN_T::LBRACE, '{'],
      [Emolang::TOKEN_T::RBRACE, '}'],
      [Emolang::TOKEN_T::COMMA, ',']
    ]

    lexer = Emolang::Lexer.new(input)
    tests.each do |test|
      token = lexer.next_token
      assert_equal(test[0], token.type)
      assert_equal(test[1], token.literal)
      
    end
  end

 
end
