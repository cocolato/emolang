# frozen_string_literal: true
# typed: true


module Emolang

  module StdLib
  include Kernel
    def 💬(obj)
      p obj
    end

    def ❓(expr, &blk)
      blk.call if expr
    end

    def ✅ 
      true
    end

    def ❎
      false
    end

    def 🧮(name, &body)
      define_singleton_method name.to_s do |*args|
        body.call(*args)
      end
    end
  end
end