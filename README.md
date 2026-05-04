# memo.nvim

フローティングウィンドウでメモファイルを開くシンプルな Neovim プラグイン。

## インストール

lazy.nvim の場合:

```lua
{
  "ningen/memo.nvim",
  config = function()
    require("memo").setup()
  end,
}
```

## 設定

```lua
require("memo").setup({
  path = "~/memo.md",  -- メモファイルのパス（デフォルト: ~/memo.md）
})
```

## 使い方

`:Memo` コマンドでウィンドウを開閉します。`q` を押すと保存して閉じます。
