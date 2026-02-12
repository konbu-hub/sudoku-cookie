---
name: release_verification
description: リリースビルド（AAB）の検証とバージョン整合性チェックを行うスキル
---

# Release Verification Skill

このスキルは、リリースビルド作成後に実行し、成果物が正しく生成されているか、バージョン設定が正しいかを検証します。

## 手順

1. **バージョン情報の確認**
    - `pubspec.yaml` を読み込み、`version` フィールドの値を確認します。
    - `lib/screens/title_screen.dart` 内の `Ver X.X.X` 表記が `pubspec.yaml` のバージョン（`+`以降のビルド番号を除く）と一致しているか確認します。

2. **ビルド成果物の確認**
    - `build/app/outputs/bundle/release/app-release.aab` が存在するか確認します。
    - ファイルサイズを確認し、極端に小さくないか（例: 0バイトでないか）チェックします。

3. **レポート**
    - 確認結果をユーザーに報告します。
    - 問題なければ「検証OK」と伝えます。
