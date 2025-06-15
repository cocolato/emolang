# frozen_string_literal: true
# typed: true

require_relative '../token'
require_relative 'node'

module Emolang
  module AST
    class Statement < Node
      attr_accessor :token

      def statement_name
        raise NotImplementedError
      end

      sig { returns(String) }
      def token_literal
        @token.literal
      end
    end

    class Expression < Node
      def expression_node
        raise NotImplementedError
      end
    end

    class Identifier < Expression
      sig { params(token: Token, value: String).void }
      def initialize(token, value)
        super()
        @token = token
        @value = value
      end

      sig { returns(String) }
      def token_literal
        @token.literal
      end
    end
  end
end
