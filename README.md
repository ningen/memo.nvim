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
  capture = {
    note_label = "memo",
    include_code = true,
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
| `:MemoSearch {query}` | メモを検索して quickfix に表示する |
| `:MemoExport` | LLM に渡しやすい Markdown バッファを開く |
| `:MemoYankLast` | 直近のメモエントリを yank する |
| `:MemoTodo` | TODO / FIXME / checkbox を quickfix に表示する |
| `:MemoToday` | 今日のメモエントリを quickfix に表示する |
| `:MemoProject` | プロジェクトメモを開閉する |
| `:MemoGlobal` | グローバルメモを開閉する |
| `:MemoTags` | タグ一覧を Markdown バッファで開く |
| `:MemoStats` | メモ統計を Markdown バッファで開く |
| `:MemoPruneBlank` | 余分な連続空行を整理する |
| `:MemoTelescope` | Telescope でメモエントリを検索・プレビューする |
| `:MemoSnacks` | folke/snacks.nvim picker でメモエントリを検索・プレビューする |
| `:MemoPicker` | Snacks があれば Snacks、なければ Telescope で開く |
| `:MemoIndex` | 構造化されたメモ概要を開く |
| `:MemoTimeline` | 日付別タイムラインを開く |
| `:MemoExportFiltered` | 条件付きで LLM 向けメモを書き出す |
| `:MemoExportJsonl` | JSONL 形式でメモを書き出す |
| `:MemoPrompt` | 目的別 LLM プロンプトを開く |
| `:MemoQuery` | 軽量 query syntax でメモを抽出する |
| `:MemoTaskReport` | タスクレポートを開く |
| `:MemoDigest` | メモ digest を開く |
| `:MemoStandup` | 今日の standup 下書きを開く |
| `:MemoCollections` | 保存済み collection 一覧を開く |
| `:MemoCollection` | 保存済み collection を開く |
| `:MemoInsights` | メモの利用傾向を開く |
| `:MemoRecommendations` | メモ運用のおすすめを開く |
| `:MemoReviewPack` | レビュー用メモパックを開く |
| `:MemoWorktreePrompt` | git 状態込みの LLM プロンプトを開く |
| `:MemoDuplicates` | 重複候補を開く |
| `:MemoValidateConfig` | 設定検証レポートを開く |
| `:MemoVersion` | バージョン情報を開く |

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

## 詳細ドキュメント

機能ごとの目的・意図・使い方は `docs/` 配下にあります。
全体構成は `docs/architecture.md` を参照してください。
