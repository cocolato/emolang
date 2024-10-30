# frozen_string_literal: true
# typed: true

module Emolang
  module AST
    class LetStatement < Statement
      attr_accessor :token, :name

      sig { params(token: Token).void }
      def initialize(token)
        super()
        @token = token
        @name = T.let(nil, T.nilable(AST::Identifier))
      end
    end

    class ReturnStatement < Statement
      attr_accessor :token, :return_value

      sig { params(token: Token).void }
      def initialize(token)
        super()
        @token = token
        @name = T.let(nil, T.nilable(AST::Identifier))
      end
    end
  end
end
