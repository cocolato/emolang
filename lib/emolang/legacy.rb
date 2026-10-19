# frozen_string_literal: true

module Emolang
  # Legacy v0.1 implementation, kept behind `--legacy` for comparison:
  # rewrites ▶️/⏹️ to do/end and evals the result as Ruby with emoji methods.
  module LegacyStdLib
    def 💬(other) = p(other)

    def ❓(expr, &blk)
      blk&.call if expr
    end

    def ✅ = true
    def ❎ = false

    def 🧮(name, &body)
      define_singleton_method(name.to_s) { |*args| body.call(*args) }
    end
  end

  class LegacyRunner
    include LegacyStdLib

    BLOCK_BEGIN = '▶️'
    BLOCK_END = '⏹️'

    def initialize(filename)
      @filename = filename || raise(ArgumentError, 'Invalid file name!')
    end

    def execute
      data = File.read(@filename)
      data.gsub!(/#{BLOCK_BEGIN}/) { 'do' }
      data.gsub!(/#{BLOCK_END}/) { 'end' }
      binding.eval(data)
    end
  end
end
