# GitHub Pages プライバシーポリシー公開手順

## 現在の状態

✅ Gitリポジトリ初期化完了  
✅ プライバシーポリシーファイルコミット完了  
✅ リモートリポジトリ設定完了 (`konbu-hub/sudoku-cookie`)  
✅ ブランチ名を`main`に変更完了

## 次のステップ

### 1. GitHubリポジトリの作成

まず、GitHubでリポジトリを作成してください:

1. https://github.com/new にアクセス
2. 以下の情報を入力:
   - **Repository name**: `sudoku-cookie`
   - **Description**: おしゃべりクッキーのSUDOKU - 数独ゲームアプリ
   - **Public** を選択 ⚠️ 重要: GitHub Pagesには必須
   - **Add a README file**: ❌ チェックしない
   - **Add .gitignore**: None
   - **Choose a license**: None
3. 「Create repository」をクリック

### 2. プッシュコマンドの実行

GitHubリポジトリを作成したら、以下のコマンドを実行してください:

```bash
git push -u origin main
```

> [!NOTE]
> 初回プッシュ時にGitHubの認証が求められます。Personal Access Token (PAT) を使用してください。

### 3. GitHub Pagesの有効化

1. https://github.com/konbu-hub/sudoku-cookie/settings/pages にアクセス
2. **Source** セクション:
   - Branch: `main` を選択
   - Folder: `/docs` を選択
   - 「Save」をクリック

### 4. 公開URLの確認

数分後、以下のURLでプライバシーポリシーが公開されます:

**日本語版**:
```
https://konbu-hub.github.io/sudoku-cookie/privacy_policy_ja.html
```

**英語版**:
```
https://konbu-hub.github.io/sudoku-cookie/privacy_policy_en.html
```

ブラウザでアクセスして、正しく表示されることを確認してください。

### 5. Google Play Consoleでの設定

#### プライバシーポリシーURL

1. https://play.google.com/console にアクセス
2. 「おしゃべりクッキーのSUDOKU」を選択
3. **「ポリシー」→「アプリのコンテンツ」** を選択
4. **「プライバシーポリシー」** をクリック
5. 以下のURLを入力:
   ```
   https://konbu-hub.github.io/sudoku-cookie/privacy_policy_ja.html
   ```
6. 「保存」をクリック

#### データ セーフティ セクション

1. 「データ セーフティ」セクションを選択
2. 「開始」をクリック

**データ収集: はい**

**収集するデータタイプ**:
- ✅ 名前 (任意、削除可能)
- ✅ メールアドレス (任意、削除可能)
- ✅ ユーザーID (任意、削除可能)
- ✅ アプリの操作 (必須、削除可能)

**データの使用目的**:
- ✅ アプリの機能
- ✅ アカウント管理

**データの共有**:
- ✅ はい (Firebase、Google Sign-In)

**セキュリティ**:
- ✅ 転送中のデータは暗号化されます
- ✅ ユーザーはデータの削除をリクエストできます

3. すべて入力したら「保存」をクリック

### 6. AABのアップロード

プライバシーポリシーとデータ セーフティの設定が完了したら、AABをアップロードできます:

**ファイル**: `build\app\outputs\bundle\release\app-release.aab`  
**バージョン**: 1.0.5 (8)

## トラブルシューティング

### Personal Access Token (PAT) の作成

1. https://github.com/settings/tokens にアクセス
2. 「Generate new token」→「Generate new token (classic)」
3. Note: `sudoku-cookie`
4. Expiration: 90 days (または任意)
5. スコープ: ✅ `repo` (すべて)
6. 「Generate token」をクリック
7. トークンをコピー(一度しか表示されません!)
8. `git push` 時にパスワードの代わりに使用

### GitHub Pagesが表示されない場合

- 5-10分待ってから再度アクセス
- リポジトリが **Public** になっているか確認
- Settings → Pages で正しく設定されているか確認
- Actions タブでビルドが成功しているか確認

## チェックリスト

- [ ] GitHubリポジトリ作成 (`sudoku-cookie`, Public)
- [ ] `git push -u origin main` 実行
- [ ] GitHub Pages有効化 (main, /docs)
- [ ] プライバシーポリシーURL確認
- [ ] Google Play: プライバシーポリシー設定
- [ ] Google Play: データ セーフティ設定
- [ ] AABアップロード

すべて完了すれば、Google Playでアプリを公開できます! 🎉
