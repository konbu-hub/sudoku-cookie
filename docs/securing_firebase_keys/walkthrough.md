# Firebaseオプション保護の実装手順

## 実施内容

### 1. `.gitignore` の更新
`lib/firebase_options.dart` と `android/app/google-services.json` を Git の除外対象に追加しました。

### 2. Git 追跡の解除
`git rm --cached` コマンドを実行し、これらのファイルをバージョン管理から外しました（ローカルファイルは保持されます）。

### 3. 検証
- **ファイル確認**: `lib/firebase_options.dart` がディスク上に存在し、Git ステータスで削除済み（Deleted）となっていることを確認しました。
- **ビルド確認**: `flutter build appbundle --debug` を実行し、ファイル除外後もアプリケーションが正常にビルドできることを確認しています。

## 注意事項
チームメンバーや別の環境でセットアップする場合は、`flutterfire configure` を実行して `firebase_options.dart` を再生成するか、`google-services.json` を手動で配置する必要があります。
