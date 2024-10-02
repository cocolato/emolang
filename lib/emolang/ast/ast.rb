# frozen_string_literal: true
# typed: true

require_relative '../token'
require_relative 'node'

module Emolang
  module AST
    class Statement < Node
      def statement_name
        raise NotImplementedError
      end
    end

    class LetStatement < Statement
      attr_accessor :token, :name

      sig { params(token: Token).void }
      def initialize(token)
        super()
        @token = token
        @name = T.let(nil, T.nilable(AST::Identifier))
      end

      sig { returns(String) }
      def token_literal
        @token.literal
      end
    end

    class Identifier < Node
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

    class Expression < Node
      def expression_node
        nil
      end
    end
  end
end
