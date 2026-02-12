# Firebaseオプション保護の実装計画

## 目標
`lib/firebase_options.dart` で露出している Google API Key に関する GitHub のシークレットスキャン警告を解決します。シークレットを含む設定ファイルをローカルには保持しつつ、Git リポジトリの追跡対象から外します。

## ユーザーレビュー必須事項
> [!IMPORTANT]
> この変更では `git rm --cached` を実行し、ファイルをディスク上に残したまま Git の追跡から外します。
> **注意:** チーム開発や CI/CD を利用している場合、他の開発者やビルドサーバーは `flutterfire configure` を実行するか、安全な方法でこれらのファイル（`lib/firebase_options.dart` および `android/app/google-services.json`）を配置する必要があります。

## 提案される変更

### 設定
#### [変更] [.gitignore](file:///c:/Users/konbu/sudoku_cookie_flutter/.gitignore)
Firebase 設定ファイルを除外するために以下の行を追加します：
```gitignore
lib/firebase_options.dart
android/app/google-services.json
```

### Git 操作
以下のコマンドを実行し、ファイルへの変更追跡を解除します：
- `git rm --cached lib/firebase_options.dart`
- `git rm --cached android/app/google-services.json`

## 検証計画

### 自動テスト
- `flutter build appbundle --debug`（または軽量なビルドチェック）を実行し、ファイルがディスク上に存在し、ビルドが正常に行えることを確認します。
- `git status` を実行し、ファイルが無視され、削除としてステージングされていることを確認します（コミット時にリポジトリからは削除されますが、ローカルファイルは保持されます）。
