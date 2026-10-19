# frozen_string_literal: true

module Emolang
  # Runtime values. Emolang maps onto plain Ruby values: Integer, String,
  # Symbol, Array, true/false, nil (null). Callable and control-flow values
  # get small wrapper structs.
  module Obj
    ReturnValue = Struct.new(:value)
    Break = Struct.new(:value)
    Error = Struct.new(:message)
    Function = Struct.new(:parameters, :body, :env)
    Macro = Struct.new(:parameters, :body, :env)
    Builtin = Struct.new(:name, :fn)

    module_function

    def display(value)
      case value
      when true then '✅'
      when false then '❎'
      when nil then '∅'
      when Array then "[#{value.map { |v| display(v) }.join(', ')}]"
      when Break then '🛑'
      when Function, Macro, Builtin then '🧮<fn>'
      when Symbol then ":#{value}"
      else value.to_s
      end
    end
  end
end
