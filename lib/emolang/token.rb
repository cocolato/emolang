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
    MINUS = '-'
    ASTERISK = '*'
    MOD = '%'
    SLASH = '/'

    BANG = '!'
    PIPE = '|'

    LT = '<'
    GT = '>'

    COMMA = ','

    LPAREN = '('
    RPAREN = ')'

    LBRACE = '{'
    RBRACE = '}'

    SEMICOLON = ';'

    EQ = '=='
    NEQ = '!='

    FUNCTION = 'FUNCTION'
    LET = 'LET'
    TRUE = 'TRUE'
    FALSE = 'FALSE'
    IF = 'IF'
    ELSE = 'ELSE'
    RETURN = 'RETURN'
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
