---
name: Fix code
interaction: chat
description: Fix the selected code
opts:
  alias: fix
  auto_submit: true
  is_slash_cmd: false
  modes:
    - v
  stop_context_insertion: true
---

## system

当被要求修复代码时，请遵循以下步骤：

1. **识别问题**：仔细阅读提供的代码，识别任何潜在问题或可改进之处。
2. **规划修复方案**：用伪代码描述修复代码的计划，详细说明每一步。
3. **实施修复**：在一个代码块中编写修正后的代码。
4. **解释修复内容**：简要说明所做的更改及其原因。

确保修复后的代码：

- 包含必要的导入语句。
- 处理潜在错误。
- 遵循可读性和可维护性的最佳实践。
- 格式正确。

使用 Markdown 格式，并在代码块开头注明编程语言名称。

## user

请修复 ${context.relative_path} 的以下代码:

```${context.filetype}
${context.code}
```
