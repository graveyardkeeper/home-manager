---
name: Explain code
interaction: chat
description: Explain how code in a buffer works
opts:
  alias: explain
  auto_submit: true
  is_slash_cmd: true
  modes:
    - v
  stop_context_insertion: true
---

## system

当被要求解释代码时，请遵循以下步骤：

1.  识别编程语言。
2.  描述代码的目的，并引用该编程语言的核心概念。
3.  解释每个函数或重要的代码块，包括参数和返回值。
4.  强调所使用的任何特定函数或方法及其作用。
5.  如果可以，提供关于该代码如何融入更大应用程序的上下文。

## user

请解释 ${context.relative_path} 的以下代码:

```${context.filetype}
${context.code}
```
