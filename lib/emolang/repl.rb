# frozen_string_literal: true

module Emolang
  # Interactive read-eval-print loop. Evaluates each line (or multi-line
  # block) in a shared environment; `exit` or Ctrl-D quits.
  #
  # Julia-style input: ASCII mnemonics starting with a backslash expand to
  # emoji keywords. In an interactive terminal they expand on Tab (via
  # reline, with history/line editing); they always expand on Enter.
  class REPL
    PROMPT = '>>> '
    CONTINUATION = '... '

    ALIASES = {
      '\\let' => '📦', '\\fn' => '🧮', '\\macro' => '🔧', '\\if' => '❓',
      '\\else' => '❗', '\\while' => '🔁', '\\break' => '🛑', '\\ret' => '↩',
      '\\true' => '✅', '\\false' => '❎', '\\print' => '💬', '\\do' => '▶️',
      '\\end' => '⏹️', '\\qq' => '📖', '\\quote' => "'", '\\sym' => '🔖',
      '\\eval' => '🔮', '\\apply' => '🚀', '\\cmt' => '💭',
      '\\le' => '≤', '\\ge' => '≥', '\\ne' => '≠', '\\times' => '×',
      '\\div' => '÷', '\\sqrt' => '√', '\\and' => '&&', '\\or' => '||',
      '\\pow' => '**'
    }.freeze

    def self.expand(line)
      # Match strings and comments whole so their contents stay literal.
      line.gsub(/"(?:\\.|[^"\\])*(?:"|\\?\z)|(?:💭|\\cmt\b)[^\n]*|\\(?:\\|[a-z]+\b)/) do |part|
        part.start_with?('\\cmt') ? part.sub(/\A\\cmt\b/, '💭') : ALIASES.fetch(part, part)
      end
    end

    # Partial words use Reline's candidate menu; complete words expand on Tab.
    def self.completions(word)
      return [] unless word.start_with?('\\')

      ALIASES.keys.select { |key| key.start_with?(word) }
    end

    def start
      @env = Env.root
      buffer = +''
      loop do
        line = read_line(buffer.empty? ? PROMPT : CONTINUATION)
        break if line.nil?

        line = self.class.expand(line.chomp)
        break if line == 'exit'

        buffer = buffer.empty? ? line : "#{buffer}\n#{line}"
        next if block_open?(buffer)

        execute(buffer)
        buffer = ''
      end
      puts
    end

    private

    def read_line(prompt)
      return $stdin.gets unless $stdin.tty?

      require 'reline'
      setup_reline
      input = Reline.readline(prompt, true)
      return nil if input.nil?

      Reline::HISTORY.pop if input.strip.empty?
      input
    end

    def setup_reline
      Reline.completion_append_character = nil
      # Backslash must not break words so "\sqrt" completes as one unit.
      Reline.completer_word_break_characters = " \t\n()[]{}\"'=<>+-*%|!,"
      Reline.completion_proc = method(:complete)
    end

    def complete(word, before)
      candidates = self.class.completions(word)
      return [] if candidates.empty?
      return [] unless self.class.expand(before + candidates.first).end_with?(ALIASES.fetch(candidates.first))
      return candidates unless ALIASES.key?(word)

      # Emoji cannot pass Reline's prefix filter, so edit the current word directly.
      start = Reline.point - word.bytesize
      Reline.delete_text(start, word.bytesize)
      Reline.point = start
      Reline.insert_text(ALIASES.fetch(word))
      nil
    end

    def execute(source)
      result = Emolang.run(source, @env)
      case result
      when Obj::Error then puts "💀 #{result.message}"
      when nil then nil
      else puts Obj.display(result)
      end
    rescue Emolang::Error => e
      puts "💀 #{e.message}"
    end

    # Buffer continues while ▶️ ... ⏹️ blocks are still open.
    def block_open?(source)
      depth = 0
      Lexer.new(source).tokens.each do |token|
        depth += 1 if token.type == TT::BLOCK_BEGIN
        depth -= 1 if token.type == TT::BLOCK_END
      end
      depth.positive?
    rescue Emolang::Error
      false
    end
  end
end
