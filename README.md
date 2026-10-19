# Emolang

English | [简体中文](README.zh-CN.md)

A toy emoji language written in Ruby, with closures, recursion, and Lisp-style macros.

## Quick start

Requires Ruby 3.0+.

```sh
bundle install
bin/emolang test/demo.emo   # Run a file
bin/emolang                 # Start the REPL; exit or Ctrl-D to quit
```

```text
🧮 fib |n| ↩️ ❓ n < 2 ▶️ n ⏹️ ❗ fib(n - 1) + fib(n - 2)
💬 fib(10)   💭 55
```

## Syntax

| Syntax | Meaning |
|---|---|
| `📦 x = 5` | Bind a variable |
| `💬 x` / `↩️ x` | Print / return |
| `✅` / `❎` | True / false |
| `❓ cond ▶️ a ⏹️ ❗ b` | If / else; else accepts an expression or a block |
| `🔁 cond ▶️ ... ⏹️` / `🛑` | While / break |
| `🧮 add \|a, b\| a + b` | Named function |
| `🧮 \|x\| x * x` | Anonymous function |
| `add(1, 2)` | Call |
| `[1, 2]` / `xs[0]` | Array / index |
| `"hello #{name}"` | String interpolation |
| `💭 comment` | Line comment; leave whitespace before it |

Newlines separate statements. Blocks use `▶️ ... ⏹️` and return their last value.
Numbers include integers and floats. Only false and null (displayed as `∅`) are falsey.
Errors stop evaluation; complex numbers are unsupported.

Operators, from low to high precedence:
`||`, `&&`, `== !=`, `< > <= >=`, `+ -`, `* / %`, `**`, then prefix `! - √`.
`**` associates right; `&&` and `||` short-circuit and return booleans.
Math aliases: `≤ ≥ ≠ × ÷` for `<= >= != * /`.

## Quote, eval, and macros

Symbols use `🔖name`. Quoted code is data; `🔮` evaluates it and `🚀` applies a function to an array of arguments.

```text
💬 🔮('[🔖+, 1, 2])     💭 3
📦 xs = [3, 4]
💬 📖 [1, 2, ~@xs]      💭 [1, 2, 3, 4]; ~ evaluates, ~@ splices
🧮 add |a, b| a + b
💬 🚀(add, [1, 2])      💭 3
```

Macros receive unevaluated arguments and run the returned code in the caller's scope.
Functions and macros require an exact argument count.

```text
🔧 unless |cond, body| [🔖if, cond, [🔖do], [🔖do, body]]
unless(❎, 💬 "hello")
```

## REPL shortcuts

- Type `\let`, then **Tab**, to insert `📦`.
- `\sq` → **Tab** → `\sqrt` → **Tab** → `√`.
- Press **Tab** twice on an ambiguous prefix such as `\s` to list candidates.
- **Enter** also expands shortcuts. Strings and comments stay unchanged.
- Arrow keys and **Ctrl-R** provide editing and history via Reline.

Shortcuts: `\let` `\fn` `\macro` `\if` `\else` `\while` `\break` `\ret`
`\true` `\false` `\print` `\do` `\end` `\qq` `\quote` `\sym` `\eval` `\apply` `\cmt`
`\le` `\ge` `\ne` `\times` `\div` `\sqrt` `\and` `\or` `\pow`.

## Development

```sh
bundle exec rake test
bundle exec rubocop
```

The original Ruby-eval implementation is available for comparison:
`bin/emolang --legacy test/legacy.emo`.
