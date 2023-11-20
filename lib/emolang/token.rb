# frozen_string_literal: true
# typed: true

module Emolang

    class TOKEN_T
      ILLEGAL = 'ILLEGAL'
      EOF = 'EOF'

      IDENT = 'IDENT'
      INT = 'INT'

      ASSIGN = '='
      PLUS = '+'

      COMMA = ','

      LPAREN = '('
      RPAREN = ')'

      LBRACE = '{'
      RBRACE = '}'

      FUNCTION = 'FUNCTION'

      LET = 'LET'
    end


    class Token
      extend T::Sig

      attr_accessor :type, :literal
      
      sig {params(type: String, literal: String).void}
      def initialize(type, literal)
        @type = type
        @literal = literal
      end
    
    end
end

