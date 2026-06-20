# TODO

macOS 向けのシンプルなネイティブ TODO アプリです。

![スクリーンショット](screenshots/screenshot.png)

## 機能

- **タスク管理** — 追加・削除・完了チェック
- **優先度** — 高 / 中 / 低のカラーコード表示と絞り込みフィルタ
- **進捗** — 0〜100% のプログレスバーを一覧に表示。クリックまたは右クリック「進捗を設定...」でスライダー編集
- **期日** — 期限日の設定。過ぎた場合は赤色で警告表示
- **検索** — キーワードによるリアルタイム絞り込み
- **並び替え** — ドラッグ＆ドロップで順序を変更
- **セクション分け** — 未完了 / 完了済みを分けて表示・非表示切り替え
- **コンテキストメニュー** — 右クリックでクイック操作
- **永続化** — UserDefaults に自動保存（再起動後もデータを保持）

## 動作環境

- macOS 13.0 (Ventura) 以降
- Xcode 15 以降

## ビルド方法

```bash
git clone https://github.com/Tierra-Soft/todo.git
cd todo
open todo.xcodeproj
```

Xcode で `⌘R` を押すとビルド・起動できます。

## 構成

```
todo/
├── TodoApp.swift       # @main エントリポイント
├── TodoItem.swift      # データモデル（Codable）
├── TodoStore.swift     # 状態管理（@MainActor ObservableObject）
└── ContentView.swift   # メイン UI・TodoRow・ProgressEditorView
```

## 技術スタック

- **SwiftUI** — 宣言的 UI フレームワーク
- **UserDefaults** — JSON シリアライズによるローカル永続化
- `@MainActor` / `ObservableObject` — スレッドセーフな状態管理
