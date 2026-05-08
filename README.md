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
})
```

## 使い方

| 操作 | 説明 |
|------|------|
| `:Memo` | メモウィンドウを開閉する |
| `q` | 保存して閉じる |
| `:'<,'>Memo` | ビジュアル選択範囲をコードブロックとしてメモに追記する |

### ビジュアル選択 → コードブロック

コードを選択した状態で `:Memo` を実行すると、ファイルタイプを自動検出してコードブロックとして追記されます。

```
:'<,'>Memo
```

### プロジェクト別メモ

`per_project = true` にすると、git リポジトリごとに `.memo.md` を作成します。
`.gitignore` への追加を推奨します:

```
.memo.md
```
