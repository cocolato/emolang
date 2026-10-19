# frozen_string_literal: true

require_relative 'test_helper'

class EvalTest < Minitest::Test
  def test_arithmetic
    assert_eval '2', '1 + 1'
    assert_eval '7', '1 + 2 * 3'
    assert_eval '5', '(1 + 2) * 5 / 3'
    assert_eval '3', '7 % 4'
    assert_eval '-5', '-(5)'
  end

  def test_pow_is_right_associative
    assert_eval '512', '2 ** 3 ** 2'
    assert_eval '1024', '2 ** 10'
    assert_eval '3', '2 ** 3 * 4 - 29'
    assert_eval '1.4142135623730951', '2.0 ** 0.5'
    assert_error '0 ** -1', 'division by zero'
  end

  def test_booleans_and_equality
    assert_eval '✅', '1 < 2'
    assert_eval '❎', '!✅'
    assert_eval '✅', '1 != 2'
    assert_eval '✅', '"a" == "a"'
    assert_eval '✅', '[1, 2] == [1, 2]'
  end

  def test_truthiness
    assert_eval '5', '❓ 0 ▶️ 5 ⏹️'
    assert_eval '∅', '❓ ❎ ▶️ 5 ⏹️'
  end

  def test_let_and_identifiers
    assert_eval '5', "📦 x = 5\nx"
    assert_error 'nope', 'identifier not found'
  end

  def test_if_expressions
    assert_eval '1', '❓ 1 < 2 ▶️ 1 ⏹️'
    assert_eval '2', '❓ 1 > 2 ▶️ 1 ⏹️ ❗ 2'
    assert_eval '2', '❓ 1 > 2 ▶️ 1 ⏹️ ❗ ▶️ 2 ⏹️'
  end

  def test_top_level_return_unwraps
    assert_eval '10', '↩️ 10'
  end

  def test_functions_and_return
    assert_eval '10', "🧮 f ▶️ ↩️ 10 ⏹️\nf()"
    assert_eval '3', "🧮 f ▶️\n  ↩️ 3\n⏹️\nf()"
    assert_eval '4', "🧮 sq |n| ↩️ n × n\nsq(2)"
  end

  def test_closures
    src = "🧮 adder |x| ↩️ 🧮 |y| ↩️ x + y\nadder(2)(3)"
    assert_eval '5', src
  end

  def test_higher_order_functions
    src = "🧮 twice |f, x| ↩️ f(f(x))\n🧮 inc |n| ↩️ n + 1\ntwice(inc, 3)"
    assert_eval '5', src
  end

  def test_recursion_with_compact_else
    src = '📦 fib = 🧮 |n| ↩️ ❓ n < 2 ▶️ n ⏹️ ❗ fib(n - 1) + fib(n - 2)'
    assert_eval '55', "#{src}\nfib(10)"
  end

  def test_strings_and_interpolation
    assert_eval 'ab', '"a" + "b"'
    assert_eval 'a1b', "📦 x = 1\n" + '"a#{x}b"' # rubocop:disable Style/StringConcatenation
    assert_eval "it's", %q("it's")
  end

  def test_arrays
    assert_eval '[1, 2, 3]', '[1, 2, 3]'
    assert_eval '2', '[1, 2, 3][1]'
    assert_eval '∅', '[1][5]'
    assert_eval '[1, 2]', '[1] + [2]'
  end

  def test_runtime_errors
    assert_error '1 + ✅', 'type mismatch'
    assert_error '1 / 0', 'division by zero'
    assert_error '📦 f = 1
f()', 'not a function'
    assert_error '🧮 f |a| ▶️ ⏹️
f(1, 2)', 'wrong number of arguments'
    assert_error '"a" + 1', 'type mismatch'
  end

  def test_print_statement
    out, = capture_io { Emolang.run('💬 40 + 2') }
    assert_equal "42\n", out

    out, = capture_io { Emolang.run('💬 [1, "a", ✅]') }
    assert_equal "[1, a, ✅]\n", out
  end

  # ---- while / break / booleans / floats / math symbols ----

  def test_while_loop_and_break
    src = <<~EMO
      📦 i = 0
      📦 sum = 0
      🔁 i < 10 ▶️
          📦 sum = sum + i
          📦 i = i + 1
      ⏹️
      sum
    EMO
    assert_eval '45', src
  end

  def test_break_exits_loop
    src = <<~EMO
      📦 i = 0
      🔁 ✅ ▶️
          📦 i = i + 1
          ❓ i == 3 ▶️ 🛑 ⏹️
      ⏹️
      i
    EMO
    assert_eval '3', src
  end

  def test_break_outside_loop_is_error
    assert_error '🛑', 'break outside loop'
  end

  def test_logical_short_circuit
    assert_eval '❎', "📦 x = 0\n❎ && 1 ÷ x == 1"
    assert_eval '✅', "📦 x = 0\n✅ || 1 ÷ x == 1"
    assert_eval '✅', '1 < 2 && 2 < 3'
    assert_eval '❎', '1 > 2 || ❎'
  end

  def test_floats
    assert_eval '3.5', '1.5 + 2'
    assert_eval '0.5', '1 / 2.0'
    assert_eval '2.25', '1.5 × 1.5'
    assert_eval '2.0', '√ 4'
    assert_eval '1.4142135623730951', '√ 2'
  end

  def test_math_symbol_operators
    assert_eval '✅', '1 ≤ 1'
    assert_eval '❎', '2 ≥ 3'
    assert_eval '❎', '1 ≠ 1'
    assert_eval '8', '2 × 4'
    assert_eval '3', '6 ÷ 2'
    assert_error '√(-1)', '√ of negative'
  end

  # ---- Lisp layer ----

  def test_symbols_and_quote
    assert_eval ':foo', '🔖foo'
    assert_eval ':x', "'x"
    assert_eval '5', "'5"
    assert_eval '[1, :x]', "'[1, 🔖x]"
    assert_eval '[:quote, :x]', "''x"
  end

  def test_quasiquote_unquote_and_splice
    assert_eval '[1, 2]', "📦 x = 2\n📖 [1, ~x]"
    assert_eval '[1, 2, 3, 4]', "📦 xs = [3, 4]\n📖 [1, 2, ~@xs]"
    assert_error '📦 x = 1
~x', 'unquote outside quasiquote'
  end

  def test_eval_builtin
    assert_eval '3', "🔮('[🔖+, 1, 2])"
    assert_eval '5', "📦 x = 4\n🔮('[🔖+, x, 1])"
    assert_eval '25', "🧮 sq |n| ↩️ n × n\n🔮('[🔖call, 🔖sq, 5])"

    out, = capture_io { Emolang.run("🔮('[🔖print, \"hi\"])") }
    assert_equal "hi\n", out
  end

  def test_apply_builtin
    src = "🧮 add |a, b| ↩️ a + b\n🚀(add, [10, 20])"
    assert_eval '30', src
  end

  def test_macro_receives_unevaluated_args_and_expands
    src = <<~EMO
      🔧 unless |cond, body| ▶️
          ↩️ [🔖if, cond, [🔖do], [🔖do, body]]
      ⏹️
      unless(❎ == ✅, 💬 "macro!")
    EMO
    out, = capture_io { Emolang.run(src) }
    assert_equal "macro!\n", out
  end

  def test_macro_can_build_bindings
    src = <<~EMO
      🔧 set10 |name| ▶️
          ↩️ [🔖let, name, 10]
      ⏹️
      set10(🔖answer)
      answer
    EMO
    assert_eval '10', src
  end

  def test_data_roundtrip_errors
    assert_error "🔮('[🔖bogus, 1])", 'unknown list head'
    assert_error "🔮('[🔖+, 1])", 'wrong arity'
  end

  def test_complex_results_are_language_errors
    ['(-1) ** 0.5', '√ ((-1) ** 0.5)', '((-1) ** 0.5) < 1'].each do |source|
      assert_error source, 'complex numbers are not supported'
    end
    assert_eval '-8', '(-2) ** 3'
    assert_eval '0.5', '2.0 ** -1'
  end

  def test_if_preserves_statement_boundaries
    assert_eval '-2', "❓ ✅ ▶️ 1 ⏹️\n-2"
    assert_eval '2', "❓ ✅ ▶️ 1 ⏹️\n(2)"
    assert_eval '[2]', "❓ ✅ ▶️ [1] ⏹️\n[2]"
    assert_eval '2', "❓ ❎ ▶️ 1 ⏹️\n💭 else on another line\n❗ 2"
    assert_eval '3', '1 + ❓ ✅ ▶️ 2 ⏹️'
    assert_eval '3', '❓ ✅ ▶️ 1 ⏹️ + 2'
  end

  def test_control_flow_propagates_through_expressions
    expression_contexts.each do |context|
      out, = capture_io do
        expression = context.sub('VALUE', '(❓ ✅ ▶️ ↩️ 7 ⏹️)')
        assert_eval '7', "🧮 f ▶️\n#{expression}\n99\n⏹️\nf()"

        expression = context.sub('VALUE', '(❓ ✅ ▶️ 🛑 ⏹️)')
        assert_eval '7', "🔁 ✅ ▶️\n#{expression}\n💬 99\n🛑\n⏹️\n7"
      end
      assert_empty out, context
    end
  end

  def test_errors_stop_before_later_side_effects
    expression_contexts.each do |context|
      out, = capture_io { assert_error context.sub('VALUE', 'missing'), 'identifier not found: missing' }
      assert_empty out, context
    end

    out, = capture_io do
      assert_error "🧮 f |a, b| 0\nf(missing, 💬 99)", 'identifier not found: missing'
    end
    assert_empty out
  end

  def test_loop_and_function_control_boundaries
    assert_eval '7', "🧮 f ▶️ 🔁 (↩️ 7) ▶️ ↩️ 99 ⏹️ ⏹️\nf()"
    assert_eval '7', "🔁 (🛑) ▶️ ↩️ 99 ⏹️\n7"
    assert_eval '7', "🔁 ✅ ▶️ 🔁 ✅ ▶️ 🛑 ⏹️\n↩️ 7 ⏹️"
    assert_error "🧮 f ▶️ 🛑 ⏹️\n🔁 ✅ ▶️ f() ⏹️", 'break outside loop'
    assert_error "🔧 m ▶️ 🛑 ⏹️\nm()", 'break outside loop'
    assert_eval '7', "🔧 m ▶️ ↩️ '[🔖return, 7] ⏹️\n🧮 f ▶️ m()\n99 ⏹️\nf()"
    assert_eval '7', "🔧 m ▶️ ↩️ '[🔖break] ⏹️\n🔁 ✅ ▶️ m()\n💬 99 ⏹️\n7"
  end

  def test_failed_binding_does_not_replace_existing_value
    env = Emolang::Env.root
    Emolang.run('📦 x = 3', env)
    result = Emolang.run('📦 x = 📖 (~missing + 1)', env)
    assert_instance_of Emolang::Obj::Error, result
    assert_equal 3, Emolang.run('x', env)
  end

  def test_quasiquote_propagates_errors_in_nested_nodes
    [
      '📖 (!~missing)', '📖 (1 + ~missing)', '📖 [~missing, ~(💬 99)]',
      '📖 (💬 ~missing)', '📖 (↩️ ~missing)', '📖 (f(~missing, ~(💬 99)))',
      '📖 ([1][~missing])', '📖 "a#{~missing}b"',
      '📖 (❓ ~missing ▶️ ~(💬 99) ⏹️)', '📖 (🔁 ~missing ▶️ ~(💬 99) ⏹️)',
      '📖 (🧮 ▶️ 📦 x = ~missing ⏹️)', '📖 [~@[missing]]'
    ].each do |source|
      out, = capture_io { assert_error source, 'identifier not found: missing' }
      assert_empty out, source
    end
    assert_error '📖 [~@1]', 'splice expects an array'
    assert_error '📖 (~@ [1])', 'splice outside array literal'
    assert_eval '[✅, ❎]', '📖 [~✅, ~❎]'
    assert_eval '[:if, ∅, [:do, 1]]', '📖 (❓ ~(❓ ❎ ▶️ 1 ⏹️) ▶️ 1 ⏹️)'
  end

  def test_unary_minus_roundtrips_through_eval_and_macros
    assert_eval '-1', "🔮('(-1))"
    assert_eval '3', "🔮('(5 - 2))"
    assert_eval '-1', "🔧 identity |x| ↩️ x\nidentity(-1)"
    assert_error "🔮('[🔖-])", 'wrong arity'
    assert_error "🔮('[🔖-, 1, 2, 3])", 'wrong arity'
  end

  def test_macro_arity_matches_function_arity_in_direct_calls_and_apply
    %w[🧮 🔧].each do |keyword|
      ['f()', 'f(1, 2)', '🚀(f, [])', '🚀(f, [1, 2])'].each do |call|
        out, = capture_io do
          assert_error "#{keyword} f |x| ▶️ 💬 99 ⏹️\n#{call}", 'wrong number of arguments'
        end
        assert_empty out
      end
      assert_eval '7', "#{keyword} f |x| ↩️ x\n🚀(f, [7])"
    end
  end

  def test_decoded_arrays_and_blocks_preserve_values_and_errors
    assert_eval '[1, ❎]', "🔮('[🔖array, 1, ❎])"
    assert_eval '2', "🔮('[🔖do, [🔖let, 🔖x, 2], x])"
    assert_eval '7', "🔮('[🔖do, [🔖return, 7], 99])"
    assert_eval '7', "🔮('[🔖call, [🔖fn, [], 7]])"
    assert_error "🔮('[🔖array, [🔖bogus]])", 'unknown list head'
    assert_error "🔮('[🔖str, [🔖bogus]])", 'unknown list head'
  end

  def test_scope_lookup_distinguishes_null_false_and_missing
    assert_eval '∅', "📦 x = ❓ ❎ ▶️ 1 ⏹️\n🧮 f ▶️ x ⏹️\nf()"
    assert_eval '❎', "📦 x = ❎\n🧮 f ▶️ x ⏹️\nf()"
    assert_eval '∅', "📦 x = 7\n🧮 f |x| x\nf(❓ ❎ ▶️ 1 ⏹️)"
    assert_error "🧮 f ▶️ missing ⏹️\nf()", 'identifier not found: missing'
  end

  private

  def expression_contexts
    [
      '📦 x = VALUE', '↩️ VALUE', '💬 VALUE', '[VALUE, 💬 99]',
      '!(VALUE)', '(VALUE) + (💬 99)', '1 + (VALUE)',
      '✅ && (VALUE)', '❎ || (VALUE)', '(VALUE) && (💬 99)', '(VALUE) || (💬 99)',
      '❓ VALUE ▶️ 💬 99 ⏹️', '(VALUE)(💬 99)', '(🧮 |a, b| 0)(VALUE, 💬 99)',
      '[1][VALUE]', '(VALUE)[💬 99]', '"a#{VALUE}b"',
      '📖 [~(VALUE), ~(💬 99)]', '📖 (~(VALUE) + ~(💬 99))'
    ]
  end

  def assert_eval(expected, source)
    result = Emolang.run(source)
    flunk "unexpected error: #{result.message}" if result.is_a?(Emolang::Obj::Error)

    assert_equal expected, Emolang::Obj.display(result)
  end

  def assert_error(source, fragment)
    result = Emolang.run(source)
    assert_instance_of Emolang::Obj::Error, result
    assert_match fragment, result.message
  end
end
