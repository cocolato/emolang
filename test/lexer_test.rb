# frozen_string_literal: true

require_relative 'test_helper'

class LexerTest < Minitest::Test
  TT = Emolang::TT

  def test_operators_and_punctuation
    tokens = lex('=+(),[]| ! ~ **')
    assert_equal ['=', '+', '(', ')', ',', '[', ']', '|', '!', '~', '**', 'EOF'], tokens.map(&:type)
  end

  def test_two_char_operators
    assert_equal %w[== != <= >= && || < EOF], lex('== != <= >= && || <').map(&:type)
  end

  def test_math_symbol_operators
    source = 'x ≤ 1 y ≥ 2 a ≠ b 3 × 4 6 ÷ 3 √ 9'
    expected = [TT::IDENT, TT::LE, TT::INT, TT::IDENT, TT::GE, TT::INT, TT::IDENT,
                TT::NEQ, TT::IDENT, TT::INT, TT::ASTERISK, TT::INT, TT::INT,
                TT::SLASH, TT::INT, TT::SQRT, TT::INT, TT::EOF].map(&:to_s)
    assert_equal expected, lex(source).map(&:type)
  end

  def test_floats
    token = lex('1.5 + 2.25')[0]
    assert_equal TT::FLOAT, token.type
    assert_equal '1.5', token.literal
    assert_equal TT::INT, lex('42')[0].type
  end

  def test_loops_and_break_tokens
    source = '🔁 ✅ ▶️ 🛑 ⏹️'
    assert_equal [TT::WHILE, TT::TRUE, TT::BLOCK_BEGIN, TT::BREAK, TT::BLOCK_END, TT::EOF],
                 lex(source).map(&:type)
  end

  def test_bookmark_symbols
    tokens = lex('🔖foo 🔖🚢 🔖+ 🔖==')
    assert_equal [TT::MARK, TT::IDENT, TT::MARK, TT::IDENT, TT::MARK, TT::PLUS,
                  TT::MARK, TT::EQ, TT::EOF], tokens.map(&:type)
  end

  def test_keywords
    source = '📦 ↩️ ❓ ❗ ✅ ❎ 🧮 🔧 💬 📖 🔁 🛑 ▶️ ⏹️'
    expected = [TT::LET, TT::RETURN, TT::IF, TT::ELSE, TT::TRUE, TT::FALSE,
                TT::FUNC, TT::MACRO, TT::PRINT, TT::QUASIQUOTE, TT::WHILE, TT::BREAK,
                TT::BLOCK_BEGIN, TT::BLOCK_END, TT::EOF].map(&:to_s)
    assert_equal expected, lex(source).map(&:type)
  end

  def test_ascii_and_emoji_identifiers
    tokens = lex('fib ➕➕ 🚢 x1')
    assert_equal [TT::IDENT, TT::IDENT, TT::IDENT, TT::IDENT, TT::EOF], tokens.map(&:type)
    assert_equal '➕➕', tokens[1].literal
  end

  def test_symbols_use_bookmark_only
    tokens = lex('🔖foo 🔖🚢 🔖+ 🔖== 🔖!')
    assert_equal [TT::MARK, TT::IDENT, TT::MARK, TT::IDENT, TT::MARK, TT::PLUS,
                  TT::MARK, TT::EQ, TT::MARK, TT::BANG, TT::EOF], tokens.map(&:type)

    error = assert_raises(Emolang::LexError) { lex(':foo') }
    assert_match(/unexpected character/, error.message)
    assert_includes error.message, ':'
  end

  def test_newlines_and_comments
    tokens = lex("💬 1\n💭 comment line\n💬 2")
    types = tokens.map(&:type)
    assert_equal [TT::PRINT, TT::INT, TT::NEWLINE, TT::NEWLINE, TT::PRINT, TT::INT, TT::EOF], types
    assert_equal 1, tokens[0].line
    assert_equal 3, tokens[4].line
  end

  def test_strings_keep_raw_content
    token = lex('"a#{x}b"')[0]
    assert_equal TT::STRING, token.type
    assert_equal 'a#{x}b', token.literal
  end

  def test_variation_selector_is_ignored
    assert_equal [TT::BLOCK_BEGIN, TT::EOF], lex('▶️').map(&:type)
    assert_equal [TT::BLOCK_BEGIN, TT::EOF], lex('▶').map(&:type)
  end

  def test_unterminated_string_raises_with_line
    error = assert_raises(Emolang::LexError) { lex('💬 "oops') }
    assert_match(/line 1/, error.message)
  end

  def test_illegal_character_raises_with_line
    error = assert_raises(Emolang::LexError) { lex("📦 x = 1\n@") }
    assert_match(/line 2/, error.message)
  end

  private

  def lex(source)
    Emolang::Lexer.new(source).tokens
  end
end
