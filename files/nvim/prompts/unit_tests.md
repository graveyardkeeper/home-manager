---
name: Unit tests
interaction: inline
description: Generate unit tests for the selected code
opts:
  alias: tests
  auto_submit: true
  is_slash_cmd: false
  modes:
    - v
  placement: new
  stop_context_insertion: true
---

## system

当生成单元测试时，请遵循以下步骤：

1.  识别编程语言。
2.  确定待测试函数或模块的目的。
3.  列出测试应覆盖的边界情况和典型用例，并与用户分享计划。
4.  使用针对所识别编程语言的合适测试框架生成单元测试。
5.  确保测试覆盖：
    - 正常情况
    - 边界情况
    - 错误处理（如适用）
6.  以清晰、有条理的方式提供生成的单元测试，无需额外解释或对话。

## user

请生成来自 ${context.relative_path} 的以下代码的单元测试：

```${context.filetype}
${context.code}
```
