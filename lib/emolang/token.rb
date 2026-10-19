# frozen_string_literal: true

module Emolang
  # A lexical token with its source line.
  Token = Struct.new(:type, :literal, :line)

  # Token type constants. Single-character tokens use their literal as the
  # type; operator types are the canonical operator strings.
  module TT
    EOF = 'EOF'
    NEWLINE = 'NEWLINE'
    IDENT = 'IDENT'
    INT = 'INT'
    FLOAT = 'FLOAT'
    STRING = 'STRING'
    MARK = '🔖'

    ASSIGN = '='
    EQ = '=='
    NEQ = '!='
    BANG = '!'
    LT = '<'
    GT = '>'
    LE = '<='
    GE = '>='
    AND = '&&'
    OR = '||'
    PLUS = '+'
    MINUS = '-'
    ASTERISK = '*'
    POW = '**'
    SLASH = '/'
    PERCENT = '%'
    SQRT = '√'
    LPAREN = '('
    RPAREN = ')'
    LBRACKET = '['
    RBRACKET = ']'
    COMMA = ','
    COLON = ':'
    PIPE = '|'

    QUOTE = "'"
    QUASIQUOTE = '📖'
    TILDE = '~'
    TILDE_AT = '~@'

    BLOCK_BEGIN = '▶'
    BLOCK_END = '⏹'

    LET = '📦'
    RETURN = '↩'
    IF = '❓'
    ELSE = '❗'
    TRUE = '✅'
    FALSE = '❎'
    FUNC = '🧮'
    MACRO = '🔧'
    PRINT = '💬'
    WHILE = '🔁'
    BREAK = '🛑'
  end
end
