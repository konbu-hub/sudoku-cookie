# 実装計画: モバイルアプリのレスポンシブ対応

## 概要
スマートフォン（横画面）およびタブレット端末での表示崩れを防ぎ、適切なレイアウトでゲームをプレイできるようにコードを改修します。

## ユーザーレビューが必要な事項
> [!IMPORTANT]
> **GameScreenのレイアウト変更**:
> 横画面時には、画面を左右に分割し、左側に数独の盤面、右側に操作ボタン（数字キーパッド、機能ボタン）を配置するレイアウトに変更します。これにより、ボタン配置が縦画面と大きく異なることになりますが、操作性を維持するための処置です。

## 提案される変更

### lib/screens (UIレイアウト)

#### [MODIFY] [game_screen.dart](file:///c:/Users/konbu/sudoku_cookie_flutter/lib/screens/game_screen.dart)
- `LayoutBuilder` を導入し、画面サイズと向き（Orientation）を検知します。
- **縦画面（Portrait）**: 既存のレイアウトを維持しつつ、`SingleChildScrollView` でラップして画面が小さい場合でもスクロール可能にし、オーバーフローを防ぎます。
- **横画面（Landscape）**: `Row` を使用した2カラムレイアウトを実装します。
    - **左カラム**: 数独グリッド（画面高さに合わせて最大化）
    - **右カラム**: スコア、タイマー、数字キーパッド、操作ボタン
- **タブレット対応**: `ConstrainedBox` を使用して、数独グリッドが画面幅いっぱいに巨大化しすぎないように最大幅（例: 600px）を設定します。

#### [MODIFY] [title_screen.dart](file:///c:/Users/konbu/sudoku_cookie_flutter/lib/screens/title_screen.dart)
- タイトルテキスト（"おしゃべりクッキーのSUDOKU"）を `FittedBox` または `ViewBox` でラップし、画面幅が狭い場合でも自動的に縮小して改行崩れを防ぐようにします。
- 固定の `SizedBox(height: 48)` などを、画面高さに対する割合（`MediaQuery.of(context).size.height * 0.05` など）に変更し、様々なアスペクト比に対応させます。

### lib/widgets (コンポーネント)

#### [MODIFY] [sudoku_grid.dart](file:///c:/Users/konbu/sudoku_cookie_flutter/lib/widgets/sudoku_grid.dart)
- `AspectRatio` の制約を、親Widgetからの制約に基づいて柔軟に調整できるようにします（必要な場合）。基本的にはそのままでも、親側でサイズ制御すれば機能する見込みです。

#### [MODIFY] [number_pad.dart](file:///c:/Users/konbu/sudoku_cookie_flutter/lib/widgets/number_pad.dart)
- 横画面時にレイアウトが崩れないよう、ボタンのサイズ調整やパディングの見直しを行います。必要であれば `Flexible` で囲んでリサイズに対応させます。

## 検証計画

### 自動テスト
- 既存のテストスイートを実行し、リファクタリングによるロジック破壊がないか確認します。
- (UIの変更が中心のため、自動テストより手動検証がメインとなります)

### 手動検証
以下の環境シミュレーションにて表示確認を行います：
1.  **Pixel 5 (標準スマホ)**: 縦画面で既存のデザインが崩れていないか。横画面で2カラムレイアウトが機能するか。
2.  **iPad / Nexus 9 (タブレット)**: グリッドが適切なサイズで中央表示されるか。文字が小さすぎないか。
3.  **スモールスクリーン (小画面)**: タイトルがはみ出さずに縮小表示されるか。
