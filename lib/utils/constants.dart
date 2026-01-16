/// アプリ全体で使用する定数
class AppConstants {
  // ゲーム設定
  static const int maxErrors = 3;
  static const int maxHints = 3;
  
  // アニメーション時間
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // グリッドサイズ
  static const int gridSize = 9;
  static const int blockSize = 3;
  
  // ローカルストレージキー
  static const String keyUsername = 'sudoku_username';
  static const String keyTheme = 'sudoku_theme';
  static const String keyDefaultFastPencil = 'sudoku_def_fast_pencil';
  static const String keyDefaultLightning = 'sudoku_def_lightning';
  static const String keyTutorialSeen = 'sudoku_tutorial_seen';
  
  // データベース
  static const String dbName = 'sudoku_cookie.db';
  static const int dbVersion = 1;
  
  // チュートリアルメッセージ
  static const List<String> tutorialMessages = [
    '「おしゃべりクッキーのSUDOKU」へようこそ!\n'
    'まずは「新しく始める」から修行を開始するッキー!',
    
    'これが盤面だッキー!\n'
    'スワイプやキーボードを使って、超高速で数字を埋めていくのがコツだッキー。',
    
    '間違った数字を入れるとミスになるッキー。\n'
    '3回ミスすると修行失敗(終了)だから気をつけるッキー!',
    
    '「クイックモード(LIGHTNING)」をONにすれば、選んだ数字を連続で叩き込めるッキー。最強だッキー!',
    
    'わからないときは「ヒント」も使えるけど、\n'
    '1回の修行で3回までしか使えないから、よく考えて使うッキー!',
  ];
}
