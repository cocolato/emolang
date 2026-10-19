# Emolang

[English](README.md) | 简体中文

用 emoji 写代码的玩具语言：Ruby 实现的 tree-walking 解释器，架构参考 Monkey 语言（*Writing an Interpreter in Go*），并带一层 Lisp 能力（引用 / 准引用 / eval / apply / 宏）。

## 快速开始

```shell
$ bundle install
$ bin/emolang test/demo.emo   # 运行程序
$ bin/emolang                 # REPL（exit 或 Ctrl-D 退出）
```

## 语言一览

| 语法 | 含义 |
|------|------|
| `📦 x = 5` | 变量绑定 |
| `↩️ expr` | 返回 |
| `💬 expr` | 打印（也可出现在表达式位置，供宏使用） |
| `❓ cond ▶️ ... ⏹️` | if |
| `❓ cond ▶️ ... ⏹️ ❗ ...` | if / else（else 支持紧凑表达式或 `▶️...⏹️` 块） |
| `🔁 cond ▶️ ... ⏹️`、`🛑` | while 循环、break |
| `✅` / `❎` | true / false |
| `🧮 name \|a, b\| ▶️ ... ⏹️` | 命名函数（`📦 name = ...` 的糖） |
| `🧮 \|x\| ▶️ ... ⏹️`、`🧮 \|x\| expr` | 匿名函数：块体或紧凑体 |
| `name(args)` | 调用 |
| `💭 ...` | 行注释（前面需留空白） |
| `"a#{x}b"` | 字符串（支持插值与 `\"` `\\` `\n` `\t`） |
| `[1, 2]`、`xs[0]` | 数组字面量与索引 |
| `42`、`3.14` | 整数与浮点数字面量 |

运算符（ASCII 与数学符号等价，参考 Julia）：

| ASCII | 数学符号 | 优先级（低→高） |
|---|---|---|
| `\|\|` | | 最低 |
| `&&` | | |
| `==` `!=` | `≠` | |
| `<` `>` `<=` `>=` | `≤` `≥` | |
| `+` `-` | | |
| `*` `/` `%` | `×` `÷` | |
| `**`（右结合） | | |
| `!` `-` `√`（前缀） | | |

- `&&`/`||` 短路求值，结果为布尔值
- 求值遇错立即停止；嵌套表达式中的 `↩️` / `🛑` 分别退出当前函数 / 循环
- 不支持复数；产生复数的幂运算返回语言错误
- 换行分隔语句；`▶️` / `⏹️` 包裹块（`▶️ 1 ⏹️` 单行块也合法）
- 闭包、递归；块隐式返回最后一条语句的值
- `∅` 表示 null；除 `❎` 与 `∅` 外一切值为真（包括 `0`）
- `▶️` 后的变体选择符（U+FE0F）可有可无：`▶` 与 `▶️` 等价

```text
📦 fib = 🧮 |n| ↩️ ❓ n < 2 ▶️ n ⏹️ ❗ fib(n - 1) + fib(n - 2)

💬 fib(10)        💭 55
```

## Lisp 层

代码即数据。符号用 `🔖name`（书签 = 标签，如 `🔖+`、`🔖if`）；引用产生的"数据语言"是带标签的数组：

```text
'[🔖+, 1, 2]             💭 引用：得到 [:+, 1, 2]
📖 [1, 2, ~@xs]          💭 准引用：~ 求值、~@ 展开（拼接）
🔮('[🔖+, 1, 2])         💭 eval 内建：数据 → 求值 → 3
🚀(add, [1, 2])          💭 apply 内建
```

数据标签：`[:+, a, b]`（中缀）`[:!, x]`、`[:√, x]`（前缀）`[:call, f, args...]`、`[:array, ...]`、
`[:do, stmts...]`、`[:if, cond, then, else?]`、`[:while, cond, body]`、`[:break]`、
`[:let, :name, value]`、`[:return, v]`、`[:print, v]`、`[:fn, [:params], body]`、
`[:macro, [:params], body]`、`[:index, l, i]`、`[:str, parts...]`、`[:quote, expr]`。

宏：参数**不求值**（以数据传入），体的返回值在调用点编译回 AST 并在调用方环境求值——经典非卫生 Lisp 宏：

函数和宏都严格检查参数数量，直接调用与 `🚀` apply 遵循相同规则。

```text
🔧 unless |cond, body| ▶️
    ↩️ [🔖if, cond, [🔖do], [🔖do, body]]
⏹️

unless(❎ == ✅, 💬 "macro!")   💭 打印 macro!
```

## REPL 输入捷径（Julia 风格）

语言本身保持纯 emoji；REPL 里用反斜杠助记符输入，无需 emoji 输入法：

- **Tab 补全**：输入完整助记符（如 `\let`）按 Tab 立即转换成 emoji（`📦`）；`\sq` 先补全为 `\sqrt`，再按 Tab 转换成 `√`；歧义前缀（如 `\s`）显示候选
- **回车展开**：完整助记符在回车时替换为 emoji（粘贴的代码同样生效）；字符串和注释内容保持原样，未知助记符不作部分替换
- **行编辑与历史**：由 Ruby 标准库 reline 提供（方向键、Ctrl-R 等）

```text
>>> \sqrt 9
3.0
```

支持的捷径：`\let` `\fn` `\macro` `\if` `\else` `\while` `\break` `\ret` `\true` `\false`
`\print` `\do` `\end` `\qq` `\quote` `\sym` `\eval` `\apply` `\cmt`
`\le` `\ge` `\ne` `\times` `\div` `\sqrt` `\and` `\or` `\pow`

## 旧版（--legacy）

v0.1 的实现把 `▶️/⏹️` 文本替换成 do/end 后直接 eval 为 Ruby，仅支持旧语法，保留作对照：

```shell
$ bin/emolang --legacy test/legacy.emo
```

## 开发

```shell
$ bundle exec rake test    # 测试
$ bundle exec rubocop      # 静态检查
```
