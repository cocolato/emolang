# frozen_string_literal: true
# typed: true

BLOCK_BEGIN = '▶️'
BLOCK_END = '⏹️'

module Emolang
  class TokenTypeEnum
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

    sig { params(type: String, literal: T.any(String, Integer)).void }
    def initialize(type, literal)
      @type = type
      @literal = literal
    end
  end
end
