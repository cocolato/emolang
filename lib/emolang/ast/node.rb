# frozen_string_literal: true
# typed: true

require_relative '../token'

module Emolang
  module AST
    class Node
      extend T::Sig

      def token_literal
        raise NotImplementedError
      end
    end

    class Program < Node
      attr_accessor :statements

      sig { void }
      def initialize
        super
        @statements = T.let([], T::Array[Statement])
      end

      sig { returns(String) }
      def token_literal
        @statements.map(&:token_literal).join
      end
    end
  end
end
