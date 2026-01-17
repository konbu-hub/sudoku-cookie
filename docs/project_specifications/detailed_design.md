# 詳細設計書

## 1. ディレクトリ構成
```
lib/
├── config/             # 定数、テーマ設定など
├── controllers/        # ビジネスロジックを含まないUIコントローラ（Audioなど）
├── data/               # 静的データ（マスコットのセリフなど）
├── models/             # データモデル (DTO)
├── providers/          # 状態管理 (ChangeNotifier)
├── repositories/       # データアクセス層 (Firestore, SQLite)
├── screens/            # 画面UI
├── services/           # 外部サービス連携 (Auth, PlayGames)
├── utils/              # ユーティリティ関数
└── widgets/            # 再利用可能なUIコンポーネント
```

## 2. アーキテクチャ
*   **Providerパターン:** `ChangeNotifier` を継承したProviderクラスで状態を管理し、`Consumer` ウィジェットでUIを更新する。
*   **Repositoryパターン:** データの取得元（Firestore, SQLite, Mock）をRepository層で隠蔽し、Providerからは抽象化されたメソッドを呼び出す。

## 3. 主要クラス詳細

### 3.1 Providers
*   **GameProvider:**
    *   ゲームの進行状態（プレイ中、ポーズ、クリア）を管理。
    *   数独の盤面データ、ユーザーの入力、履歴（Undo/Redo用）を保持。
    *   タイマーの制御。
    *   スコア計算ロジック（残り時間、難易度係数、ヒント使用ペナルティ）。
*   **ThemeProvider:**
    *   アプリ全体のテーマ（Light/Dark）とフォント設定を管理。
*   **CookieDestroyGameProvider:**
    *   （旧機能/隠しモード）クッキー破壊ミニゲームの状態管理。

### 3.2 Screens
*   **TitleScreen:**
    *   アプリ起動後のエントリーポイント。
    *   BGM再生、Play Gamesサインイン状態の確認。
    *   難易度選択ダイアログの表示。
*   **GameScreen:**
    *   メインのゲーム画面。
    *   `SudokuGrid` による盤面表示。
    *   `NumberPad` による入力制御。
    *   `CookieMascot` の表示とインタラクション。
    *   数字完成時のエフェクト (`RipplePainter`) 制御。
*   **RankingScreen:**
    *   ランキング表示画面。
    *   `TabController` による3タブ切り替え（グローバル、タイムアタック、マイサマリー）。
    *   `RankingRepository` からデータを取得して表示。

### 3.3 Models
*   **SudokuPuzzle:**
    *   数独の問題データ（初期盤面、解答）。
*   **GameState:**
    *   現在のゲーム状態（盤面、エラー数、ヒント数、スコアなど）をスナップショットとして保持。
*   **UserStatsModel:**
    *   ランキング表示用のユーザー統計データ（ユーザー名、累計ポイント、ベストタイムマップ、最終更新日時）。
*   **ScoreModel:**
    *   個々のプレイログ（スコア、タイム、難易度、日時）。

### 3.4 Services / Repositories
*   **AuthService:**
    *   Firebase Authenticationラッパー（匿名ログイン、Googleログイン）。
*   **PlayGamesService:**
    *   `games_services` パッケージのラッパー。
    *   実績の解除、リーダーボードへのスコア送信。
*   **RankingRepository:**
    *   データのCRUD操作を担当。
    *   `SQLite` (ローカル履歴) と `Firestore` (グローバルランキング) の両方を扱う。

## 4. データベース設計

### 4.1 Cloud Firestore (NoSQL)
*   **Collections:**
    *   `users_v2` (Collection)
        *   Document ID: `uid` (Firebase Auth UID)
        *   Fields:
            *   `username`: String
            *   `totalPoints`: Number (累計ポイント)
            *   `bestTimes`: Map<String, Number> (難易度ごとのベストタイム秒数)
            *   `lastPlayedAt`: Timestamp
    *   `runaways` (Collection)
        *   Document ID: `uid`
        *   Fields:
            *   `count`: Number (逃走回数)
            *   `username`: String
            *   `updatedAt`: Timestamp

### 4.2 SQLite (Local)
*   **Database:** `sudoku_cookie.db`
*   **Tables:**
    *   `history`
        *   `id`: INTEGER PK AUTOINCREMENT
        *   `score`: INTEGER
        *   `timeSeconds`: INTEGER
        *   `difficulty`: TEXT
        *   `mistakes`: INTEGER
        *   `hintsUsed`: INTEGER
        *   `timestamp`: TEXT (ISO8601)

## 5. 主要ロジック

### 5.1 数独生成 (SudokuGenerator)
*   バックトラッキング法を用いて完全な数独盤面を生成。
*   難易度に応じてランダムにセルを空にする（穴あけ）。
*   生成された問題が一意の解を持つことを確認（現在は簡易的な穴あけロジックのみで、解の一意性検証は完全ではない場合があるが、ゲームとしては成立させている）。

### 5.2 スコア計算
```dart
BaseScore = (9x9 - InitialHints) * 50
TimeBonus = (TargetTime - ElapsedTime) * 10  (Max: DifficultyBasedCap)
Penalty = (HintsUsed * 300) + (Mistakes * 100)
TotalScore = (BaseScore + TimeBonus - Penalty) * DifficultyMultiplier
```

### 5.3 マスコット思考ルーチン
*   **Idle:** 一定時間操作がないと「遅い」「寝るぞ」などのセリフ。
*   **Mistake:** 誤答時に「m9(^Д^)」「バカなの？」などの煽り。
*   **Clear:** クリア時に「やるじゃん」「まグレでしょ」などのデレ（ツンデレ）。
*   **Tap:** タップ時にランダムな反応。連打で「激怒モード」へ移行。
