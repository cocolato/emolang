# frozen_string_literal: true

require_relative 'test_helper'
require 'stringio'

class REPLTest < Minitest::Test
  def test_repl_input_aliases
    assert_equal '❓ ✅ ▶️ 🛑 ⏹️', Emolang::REPL.expand('\\if \\true \\do \\break \\end')
    assert_equal '📦 x = 1 ≤ 2 && 3 ≠ 4', Emolang::REPL.expand('\\let x = 1 \\le 2 \\and 3 \\ne 4')
    assert_equal '2 ** 8', Emolang::REPL.expand('2 \\pow 8')
  end

  def test_repl_tab_completion
    assert_equal ['\\sqrt'], Emolang::REPL.completions('\\sqrt')
    assert_equal ['\\let'], Emolang::REPL.completions('\\let')
    assert_equal ['\\sqrt', '\\sym'].sort, Emolang::REPL.completions('\\s').sort
    assert_equal [], Emolang::REPL.completions('sqrt')
    assert_equal [], Emolang::REPL.completions('\\zzz')
  end

  def test_tab_converts_complete_aliases_in_the_reline_buffer
    assert_equal ['📦', '📦'.bytesize, nil], complete_line('', '\\let')
    assert_equal ['√', '√'.bytesize, nil], complete_line('', '\\sqrt')
    assert_equal ["'", 1, nil], complete_line('', '\\quote')
    assert_equal ['≤', '≤'.bytesize, nil], complete_line('', '\\le')
    assert_equal ['💬 √(9)', '💬 √'.bytesize, nil], complete_line('💬 ', '\\sqrt', '(9)')
  end

  def test_tab_keeps_candidates_for_partial_aliases
    assert_equal ['\\sq', 3, ['\\sqrt']], complete_line('', '\\sq')
    assert_equal ['\\sqrt', '\\sym'].sort, complete_line('', '\\s').last.sort
    assert_equal ['\\unknown', 8, []], complete_line('', '\\unknown')
  end

  def test_tab_preserves_string_and_comment_contents
    ['"', '💬 "escaped \\" ', '💭 ', '\\cmt '].each do |before|
      %w[\\let \\sq].each do |word|
        source = before + word
        assert_equal [source, source.bytesize, []], complete_line(before, word)
      end
    end
  end

  def test_expansion_preserves_strings_escapes_and_unknown_words
    [
      '"\\true \\times \\sqrt"',
      '"escaped \\" quote \\true"',
      '"unfinished \\true',
      '"unfinished \\true\\',
      '"literal \\\\true"',
      '\\\\true', '\\trueish', '\\true1', '\\true_name', '\\unknown'
    ].each do |source|
      assert_equal source, Emolang::REPL.expand(source), source
    end
    assert_equal '💬 "\\true" ✅', Emolang::REPL.expand('\\print "\\true" \\true')
    assert_equal '"\\\\" ✅', Emolang::REPL.expand('"\\\\" \\true')
    assert_equal '🔖 name', Emolang::REPL.expand('\\sym name')
  end

  def test_expansion_preserves_comment_contents
    assert_equal '✅ 💭 \\false', Emolang::REPL.expand('\\true 💭 \\false')
    assert_equal '✅ 💭 \\false', Emolang::REPL.expand('\\true \\cmt \\false')
    assert_equal "💭 \\false\n✅", Emolang::REPL.expand("💭 \\false\n\\true")
  end

  def test_repl_reports_errors_and_continues_with_shared_environment
    input = <<~'EMO'
      \let x = 7
      √ ((-1) ** 0.5)
      x
      \print "\\true"
      \macro first |x| \ret x
      first(1, 2)
      first(3)
      exit
    EMO
    previous_stdin = $stdin
    $stdin = StringIO.new(input)
    out, = capture_io { Emolang::REPL.new.start }
    assert_equal [
      '💀 complex numbers are not supported', '7', '\\true',
      '💀 wrong number of arguments: given 2, expected 1', '3'
    ], out.lines.map(&:chomp).reject(&:empty?)
  ensure
    $stdin = previous_stdin
  end

  private

  def complete_line(before, word, after = '')
    require 'reline'
    Emolang::REPL.new.send(:setup_reline)
    Reline.delete_text
    Reline.insert_text(before + word + after)
    Reline.point = (before + word).bytesize
    candidates = Reline.completion_proc.call(word, before)
    [Reline.line_buffer, Reline.point, candidates]
  ensure
    Reline.delete_text
  end
end
