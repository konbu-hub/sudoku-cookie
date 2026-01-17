import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ユーザー状態のストリーム
  Stream<User?> get user => _auth.authStateChanges();

  // 現在のユーザー
  User? get currentUser => _auth.currentUser;

  // 匿名サインイン
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print("Anonymous Sign-In Error: $e");
      // エラー時はnullを返すか、必要に応じてrethrow
      return null; 
    }
  }

  // Googleでサインイン
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Googleサインインフローを開始
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        // バグ回避: Pigeonの型エラーが出ても、ネイティブ側でログイン成功している場合があるため確認
        print("Google Sign-In Exception (handled): $e");
        if (_googleSignIn.currentUser != null) {
          googleUser = _googleSignIn.currentUser;
        } else {
           // 最後の手段: サイレントログインを試行
           try {
             googleUser = await _googleSignIn.signInSilently();
           } catch (_) {
             rethrow;
           }
        }
      }

      if (googleUser == null) return null; // ユーザーがキャンセル

      // 2. 認証詳細を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Firebase用のクレデンシャルを作成
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebaseにサインイン
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      // UIで詳細を表示するために再スローしない（または要件に応じて調整）
      // ここではUI側でcatchしているのでrethrowする
      throw e;
    }


  }

  // Googleアカウントとリンク（データ引き継ぎ用）
  Future<User?> linkWithGoogle() async {
    try {
      final currentUser = _auth.currentUser;
      // if (currentUser == null) throw Exception('No user signed in'); // 未サインインでも続行

      // 1. Googleサインインフローを開始
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (e) {
        print("Google Sign-In Exception (handled): $e");
        if (_googleSignIn.currentUser != null) {
          googleUser = _googleSignIn.currentUser;
        } else {
          try {
            googleUser = await _googleSignIn.signInSilently();
          } catch (_) {
            rethrow;
          }
        }
      }

      if (googleUser == null) return null; // ユーザーキャンセル

      // 2. 認証詳細を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Firebase用のクレデンシャルを作成
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. アカウントリンク or 新規サインイン
      if (currentUser != null) {
        final UserCredential userCredential = await currentUser.linkWithCredential(credential);
        return userCredential.user;
      } else {
        // ユーザーが未サインインの場合は新規サインインとして扱う
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }

    } catch (e) {
      print("Link with Google Error: $e");
      rethrow;
    }
  }

  // サインアウト
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Sign-Out Error: $e");
    }
  }
}
