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
  path = "~/memo.md",   -- メモファイルのパス（デフォルト: ~/memo.md）
  per_project = false,  -- true にすると git root に .memo.md を作成
  window = {
    width = 0.6,
    height = 0.4,
    border = "rounded",
    winblend = 20,
    number = false,
    relativenumber = false,
  },
  input_window = {
    width = 0.4,
    min_width = 30,
    max_width = 80,
    border = "rounded",
    winblend = 10,
    number = false,
    relativenumber = false,
  },
})
```

## 使い方

| 操作 | 説明 |
|------|------|
| `:Memo` | メモウィンドウを開閉する |
| `q` | 保存して閉じる |
| `:'<,'>Memo` | ビジュアル選択範囲をコードブロックとしてメモに追記する |
| `:MemoHere` | 現在行にクイックメモを付けて追記する |
| `:'<,'>MemoHere` | 選択範囲にクイックメモを付けて追記する |

### ビジュアル選択 → コードブロック

コードを選択した状態で `:Memo` を実行すると、ファイルタイプを自動検出してコードブロックとして追記されます。

```
:'<,'>Memo
```

### クイックメモ

`:MemoHere` を実行すると 1 行入力の小さいフローティングウィンドウが開きます。
Enter で現在行または選択範囲と一緒にメモへ追記し、Esc または `q` でキャンセルします。
入力が空でも追記できます。

```lua
vim.keymap.set("n", "<leader>mh", "<cmd>MemoHere<CR>")
vim.keymap.set("v", "<leader>mh", ":MemoHere<CR>")
```

### プロジェクト別メモ

`per_project = true` にすると、git リポジトリごとに `.memo.md` を作成します。
`.gitignore` への追加を推奨します:

```
.memo.md
```
