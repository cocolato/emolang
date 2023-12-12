# frozen_string_literal: true
# typed: true

module Emolang
  module StdLib
    include Kernel

    # rubocop:disable all
    def 💬(other)
      p other
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

    # rubocop:enable all
  end
end
