## [0.2.0] - 2026-10-19

### 重写：真正的解释器（参考 Monkey 语言）

- 全新 tree-walking 解释器：Pratt parser（优先级爬升）、作用域链、闭包、错误值传播
- 新语法：`📦` let、`↩️` return、`❓`/`❗` if-else、`💭` 注释、字符串插值、数组与索引
- 函数定义收敛为两种形态：`🧮 name |params| ▶️ ... ⏹️` 与紧凑 `🧮 |params| expr`；命名不需要任何前缀符号
- else 支持紧凑表达式：`⏹️ ❗ expr`；顶层 `↩️` 解包返回值
- `🔁` while 循环与 `🛑` break
- `&&`/`||` 短路求值；`**` 幂（右结合）；浮点数
- Julia 式数学操作符：`≤ ≥ ≠ × ÷ √` 与 ASCII 写法等价
- REPL：逐行求值、共享环境、多行块续行；Julia 风格 `\` 助记输入：Tab 补全前缀、转换完整助记符为 emoji，回车也会展开助记符；行编辑/历史由 reline 提供
- 词法/语法错误带行号；`▶️` 的变体选择符（U+FE0F）可省略

### Lisp 层

- 符号唯一写法 `🔖name`（书签 = 标签），`:+` 式操作符符号写作 `🔖+`
- 引用 `'expr`；准引用 `📖` 模板，`~x` 求值、`~@xs` 拼接
- 代码即数据：AST 与带标签列表双向转换（`[🔖+, 1, 2]`、`[🔖if, ...]` 等）
- 内建 `🔮`（eval）与 `🚀`（apply）
- 宏 `🔧 name |params| ⏹️`：参数不求值，展开于调用点

### 修复

- 统一嵌套表达式的错误、return 与 break 传播；数组、调用参数和准引用遇错停止后续求值
- if 查找 else 时保留下一条语句的换行边界
- quote / eval 和宏展开支持一元负号；函数与宏共用参数数量检查
- 产生复数的幂运算返回语言错误，避免 Ruby 异常终止 REPL
- REPL 助记符展开保留字符串、转义和注释内容
- `Binding.eval` NoMethodError（v0.1 demo 无法运行）
- `rake test` 的 glob 匹配不到测试文件（CI 0 测试假绿灯）
- v0.1 parser 缺分号时死循环

### 变更

- 旧 gsub+eval 实现移至 `bin/emolang --legacy`
- 移除 Sorbet/tapioca 脚注；CI 新增 RuboCop job；gemspec 修复可执行文件安装
