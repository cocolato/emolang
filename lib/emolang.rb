# frozen_string_literal: true

require_relative 'emolang/version'

module Emolang
  class Error < StandardError; end
  class LexError < Error; end
  class ParseError < Error; end

  class << self
    # source -> AST::Program (raises ParseError with all parser errors).
    def parse(source)
      parser = Parser.new(Lexer.new(source))
      program = parser.parse_program
      raise ParseError, parser.errors.join("\n") unless parser.errors.empty?

      program
    end

    # AST node (usually a Program) -> value. Runtime errors are Obj::Error values.
    def evaluate(node, env = Env.root)
      Evaluator.eval_node(node, env)
    end

    def run(source, env = Env.root)
      evaluate(parse(source), env)
    end
  end
end

require_relative 'emolang/token'
require_relative 'emolang/lexer'
require_relative 'emolang/ast'
require_relative 'emolang/parser'
require_relative 'emolang/obj'
require_relative 'emolang/eval'
require_relative 'emolang/repl'
require_relative 'emolang/legacy'
