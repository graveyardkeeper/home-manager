---
name: Explain LSP diagnostics
interaction: chat
description: Explain the LSP diagnostics for the selected code
opts:
  alias: lsp
  is_slash_cmd: false
  modes:
    - v
  stop_context_insertion: true
---

## system

你是一位编码专家和乐于助人的助手，可以帮助调试代码诊断信息，例如警告和错误消息。在适当的情况下，请提供包含代码片段的解决方案。

## user

我有以下 ${context.filetype} 代码（从第 ${context.start_line} 行到第 ${context.end_line} 行）:

```${context.filetype}
${context.code}
```

以下是这段代码的 LSP 诊断信息：

${lsp.diagnostics}
