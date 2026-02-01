import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:my_ebook/models/user_role.dart';

class AuthService {
  AuthService._();

  static const _emailDomain = 'local-ebook.app';
  static const _adminId = 'admin';
  static const _adminPassword = '0000';
  static const _adminAuthPassword = '000000';

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static String emailFromId(String id) {
    final normalized = id.trim().toLowerCase();
    return '$normalized@$_emailDomain';
  }

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> userDoc(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).get();
  }

  static Future<void> ensureUserProfile({
    required String uid,
    required UserRole role,
    String? id,
    String? displayName,
    String? provider,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();
    if (doc.exists) {
      return;
    }
    await docRef.set({
      'role': role.value,
      'id': id ?? '',
      'displayName': displayName ?? '',
      'provider': provider ?? '',
      'businessId': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<UserCredential> signInWithIdPassword({
    required String id,
    required String password,
  }) async {
    final normalizedId = id.trim().toLowerCase();
    final email = emailFromId(normalizedId);
    var resolvedPassword = password;
    if (normalizedId == _adminId && password == _adminPassword) {
      resolvedPassword = _adminAuthPassword;
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: resolvedPassword,
      );
      if (normalizedId == _adminId && password == _adminPassword) {
        await ensureUserProfile(
          uid: credential.user!.uid,
          role: UserRole.admin,
          id: normalizedId,
          displayName: '관리자',
          provider: 'password',
        );
      }
      return credential;
    } on FirebaseAuthException {
      if (normalizedId == _adminId && password == _adminPassword) {
        final created = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: resolvedPassword,
        );
        await ensureUserProfile(
          uid: created.user!.uid,
          role: UserRole.admin,
          id: normalizedId,
          displayName: '관리자',
          provider: 'password',
        );
        return created;
      }
      rethrow;
    }
  }

  static Future<UserCredential> signUpWithIdPassword({
    required String id,
    required String password,
    required UserRole role,
  }) async {
    final normalizedId = id.trim().toLowerCase();
    if (normalizedId == _adminId) {
      throw FirebaseAuthException(
        code: 'invalid-id',
        message: '관리자 ID는 사용할 수 없습니다.',
      );
    }
    final email = emailFromId(normalizedId);
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await ensureUserProfile(
      uid: credential.user!.uid,
      role: role,
      id: normalizedId,
      displayName: normalizedId,
      provider: 'password',
    );
    return credential;
  }

  static Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }
    return _auth.signInWithProvider(provider);
  }

  static Future<UserCredential> signInWithNaver() async {
    if (kIsWeb) {
      throw FirebaseAuthException(
        code: 'naver-web-unsupported',
        message: '네이버는 웹에서 직접 로그인을 지원하지 않습니다.',
      );
    }
    final result = await FlutterNaverLogin.logIn();
    if (result.status != NaverLoginStatus.loggedIn) {
      throw FirebaseAuthException(
        code: 'naver-login-failed',
        message: '네이버 로그인에 실패했습니다.',
      );
    }
    final dynamic tokenValue = result.accessToken;
    final accessToken = tokenValue is String
        ? tokenValue
        : tokenValue?.token as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'naver-missing-token',
        message: '네이버 토큰을 가져오지 못했습니다.',
      );
    }
    final callable =
        FirebaseFunctions.instance.httpsCallable('verifyNaverToken');
    final response = await callable.call(<String, dynamic>{
      'accessToken': accessToken,
    });
    final firebaseToken = response.data is Map
        ? response.data['firebaseToken'] as String?
        : response.data as String?;
    if (firebaseToken == null || firebaseToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'naver-custom-token-failed',
        message: 'Firebase 토큰 발급에 실패했습니다.',
      );
    }
    return _auth.signInWithCustomToken(firebaseToken);
  }

  static Future<UserCredential> signInWithKakao() async {
    final provider = OAuthProvider('oidc.kakao');
    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }
    return _auth.signInWithProvider(provider);
  }

  static Future<void> signOut() => _auth.signOut();
}
