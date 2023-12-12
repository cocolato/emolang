# frozen_string_literal: true
# typed: true

require_relative 'stdlib'
require_relative 'token'

module Emolang
  class Parser
    include Emolang::StdLib

    def initialize(filename)
      @filename = filename || raise(ArgumentError, 'Invalid file name!')
    end

    def execute
      data = File.read(@filename)

      data.gsub!(/#{BLOCK_BEGIN}/) { 'do' }
      data.gsub!(/#{BLOCK_END}/) { 'end' }

      Binding.eval(data)
    end
  end
end
