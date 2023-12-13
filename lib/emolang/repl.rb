# frozen_string_literal: true
# typed: true

module Emolang
  PROMOT = '>>> '
  class REPL
    extend T::Sig

    sig { void }
    def start
      loop do
        print PROMOT
        input = gets.chomp
        return if input.empty?

        lexer = Lexer.new(input)

        loop do
          t = lexer.next_token
          p t
          break if t.type == Emolang::TokenTypeEnum::EOF
        end
      end
    end
  end
end
