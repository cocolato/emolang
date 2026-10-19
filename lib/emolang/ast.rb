# frozen_string_literal: true

module Emolang
  # AST nodes as plain structs. Statements compose a Program; expressions
  # produce values when evaluated.
  module AST
    Program = Struct.new(:statements)

    LetStatement = Struct.new(:name, :value)
    ReturnStatement = Struct.new(:value)
    PrintStatement = Struct.new(:value)
    ExpressionStatement = Struct.new(:expression)
    BlockStatement = Struct.new(:statements)
    BreakStatement = Struct.new(:value)

    Identifier = Struct.new(:name)
    IntegerLiteral = Struct.new(:value)
    FloatLiteral = Struct.new(:value)
    BooleanLiteral = Struct.new(:value)
    SymbolLiteral = Struct.new(:value)
    # parts: flat list of String literals and AST expression nodes.
    StringLiteral = Struct.new(:parts)
    ArrayLiteral = Struct.new(:elements)
    PrefixExpression = Struct.new(:operator, :right)
    InfixExpression = Struct.new(:operator, :left, :right)
    IfExpression = Struct.new(:condition, :consequence, :alternative)
    WhileExpression = Struct.new(:condition, :body)
    FunctionLiteral = Struct.new(:parameters, :body)
    MacroLiteral = Struct.new(:parameters, :body)
    CallExpression = Struct.new(:callee, :arguments)
    IndexExpression = Struct.new(:left, :index)
    # Lisp layer: quote (template = quasiquote with ~ / ~@ holes).
    QuoteExpression = Struct.new(:expression, :template)
    UnquoteExpression = Struct.new(:expression, :splice)
  end
end
