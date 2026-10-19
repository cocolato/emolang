# frozen_string_literal: true

require_relative 'test_helper'

class ParserTest < Minitest::Test
  def test_let_statement
    stmt = parse('📦 x = 5').statements.first
    assert_instance_of Emolang::AST::LetStatement, stmt
    assert_equal 'x', stmt.name.name
    assert_equal 5, stmt.value.value
  end

  def test_precedence
    expr = parse('1 + 2 * 3').statements.first.expression
    assert_equal '+', expr.operator
    assert_equal 1, expr.left.value
    assert_equal '*', expr.right.operator
  end

  def test_grouped_expression
    expr = parse('(1 + 2) * 3').statements.first.expression
    assert_equal '*', expr.operator
    assert_equal '+', expr.left.operator
  end

  def test_if_statement
    expr = parse("❓ x < 2 ▶️\n  💬 1\n⏹️").statements.first.expression
    assert_instance_of Emolang::AST::IfExpression, expr
    assert_equal 1, expr.consequence.statements.first.value.value
    assert_nil expr.alternative
  end

  def test_if_else_inline
    expr = parse('❓ ✅ ▶️ 1 ⏹️ ❗ ▶️ 2 ⏹️').statements.first.expression
    assert_equal 2, expr.alternative.statements.first.expression.value
  end

  def test_named_function_and_call
    program = parse("🧮 f |a, b| ▶️\n  ↩️ a + b\n⏹️\nf(1, 2)")
    let = program.statements[0]
    assert_instance_of Emolang::AST::FunctionLiteral, let.value
    assert_equal 'f', let.name.name
    assert_equal %w[a b], let.value.parameters.map(&:name)
    call = program.statements[1].expression
    assert_instance_of Emolang::AST::CallExpression, call
    assert_equal 2, call.arguments.length
  end

  def test_anonymous_function
    stmt = parse('📦 adder = 🧮 |x| ▶️ ↩️ x ⏹️').statements.first
    assert_instance_of Emolang::AST::FunctionLiteral, stmt.value
  end

  def test_compact_function_body
    stmt = parse('🧮 sq |n| ↩️ n × n').statements.first
    assert_equal 'sq', stmt.name.name
    assert_equal 1, stmt.value.parameters.length
    assert_equal 1, stmt.value.body.statements.length
  end

  def test_macro_definition
    stmt = parse('🔧 swap |a, b| ↩️ b').statements.first
    assert_instance_of Emolang::AST::MacroLiteral, stmt.value
    assert_equal 'swap', stmt.name.name
  end

  def test_string_interpolation_parts
    parts = parse('💬 "a#{1 + 1}b"').statements.first.value.parts
    assert_equal 'a', parts[0]
    assert_equal '+', parts[1].operator
    assert_equal 'b', parts[2]
  end

  def test_array_and_index
    expr = parse('💬 [1, 2][0]').statements.first.value
    assert_instance_of Emolang::AST::IndexExpression, expr
    assert_equal 2, expr.left.elements.length
  end

  def test_quote_and_unquote
    quote = parse("📦 x = 1\n'[🔖+, x, ~x]").statements.last.expression
    assert_instance_of Emolang::AST::QuoteExpression, quote
    refute quote.template
    inner = quote.expression
    assert_equal :+, inner.elements.first.value
    assert_equal 3, inner.elements.length
  end

  def test_quasiquote_marks_template
    quote = parse('📖 [~x]').statements.first.expression
    assert quote.template
    unquote = quote.expression.elements.first
    assert_instance_of Emolang::AST::UnquoteExpression, unquote
    refute unquote.splice, '~ should not splice'

    quote = parse('📖 [~@xs]').statements.first.expression
    assert quote.expression.elements.first.splice, '~@ should splice'
  end

  def test_symbol_literal
    expr = parse('💬 🔖foo').statements.first.value
    assert_equal :foo, expr.value

    expr = parse('💬 🔖+').statements.first.value
    assert_equal :+, expr.value

    expr = parse('💬 🔖==').statements.first.value
    assert_equal :==, expr.value
  end

  def test_while_and_break
    expr = parse("🔁 x < 3 ▶️\n  🛑\n⏹️").statements.first.expression
    assert_instance_of Emolang::AST::WhileExpression, expr
    assert_equal '<', expr.condition.operator
    assert_instance_of Emolang::AST::BreakStatement, expr.body.statements.first
  end

  def test_else_block_and_compact
    blocked = parse('❓ ❎ ▶️ 1 ⏹️ ❗ ▶️ 2 ⏹️').statements.first.expression
    assert_equal 2, blocked.alternative.statements.first.expression.value

    compact = parse('❓ ❎ ▶️ 1 ⏹️ ❗ 2').statements.first.expression
    assert_equal 2, compact.alternative.statements.first.expression.value
  end

  def test_errors_are_collected
    parser = Emolang::Parser.new(Emolang::Lexer.new('📦 5'))
    parser.parse_program
    refute_empty parser.errors
    assert_match(/line 1/, parser.errors.first)
  end

  def test_missing_block_end_is_reported
    parser = Emolang::Parser.new(Emolang::Lexer.new('❓ ✅ ▶️ 1'))
    parser.parse_program
    refute_empty parser.errors
  end

  def test_missing_value_does_not_hang
    parser = Emolang::Parser.new(Emolang::Lexer.new('📦 x ='))
    parser.parse_program
    refute_empty parser.errors
  end

  private

  def parse(source)
    Emolang.parse(source)
  end
end
