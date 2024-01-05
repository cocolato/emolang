# frozen_string_literal: true
# typed: true

require_relative 'token'

module Emolang
  module AST
    class Node
      extend T::Sig
    end

    class Program < Node
      attr_accessor :statements

      sig { void }
      def initialize
        super
        @statements = T.let([], Array)
      end

      sig { returns(String) }
      def token_literal
        @statements.map(&:token_literal).join
      end
    end

    class Statement < Node
      sig { returns(String) }
      def statement_name
        @name
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
