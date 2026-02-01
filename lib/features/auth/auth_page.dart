import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/models/user_role.dart';
import 'package:my_ebook/services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginIdController = TextEditingController();
  final _loginPwController = TextEditingController();
  final _signupIdController = TextEditingController();
  final _signupPwController = TextEditingController();
  UserRole _signupRole = UserRole.customer;
  bool _loading = false;

  static const _cardRadius = 20.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdController.dispose();
    _loginPwController.dispose();
    _signupIdController.dispose();
    _signupPwController.dispose();
    super.dispose();
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.code == 'naver-redirect') {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? '인증에 실패했습니다.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증에 실패했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    final id = _loginIdController.text.trim();
    final password = _loginPwController.text.trim();
    if (id.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력하세요.')),
      );
      return;
    }
    if (id.toLowerCase() != 'admin' && password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 6자 이상이어야 합니다.')),
      );
      return;
    }
    await _runAction(() async {
      await AuthService.signInWithIdPassword(id: id, password: password);
    });
  }

  Future<void> _handleSignup() async {
    final id = _signupIdController.text.trim();
    final password = _signupPwController.text.trim();
    if (id.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력하세요.')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 6자 이상이어야 합니다.')),
      );
      return;
    }
    await _runAction(() async {
      await AuthService.signUpWithIdPassword(
        id: id,
        password: password,
        role: _signupRole,
      );
    });
  }

  Future<UserRole?> _askRole() async {
    UserRole tempRole = _signupRole;
    final result = await showDialog<UserRole>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('회원 유형 선택'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                children: [
                  ChoiceChip(
                    label: const Text('고객'),
                    selected: tempRole == UserRole.customer,
                    onSelected: (_) =>
                        setState(() => tempRole = UserRole.customer),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('업체'),
                    selected: tempRole == UserRole.business,
                    onSelected: (_) =>
                        setState(() => tempRole = UserRole.business),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(tempRole),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<void> _handleSocialSignup(
    Future<UserCredential> Function() signIn,
  ) async {
    await _runAction(() async {
      final credential = await signIn();
      final user = credential.user;
      if (user == null) {
        return;
      }
      await AuthService.ensureUserProfile(
        uid: user.uid,
        role: _signupRole,
        displayName: user.displayName,
        provider: credential.additionalUserInfo?.providerId ?? 'oauth',
      );
    });
  }

  Future<void> _handleSocialLogin(
    Future<UserCredential> Function() signIn,
  ) async {
    await _runAction(() async {
      final credential = await signIn();
      final user = credential.user;
      if (user == null) {
        return;
      }
      final doc = await AuthService.userDoc(user.uid);
      if (!doc.exists) {
        final pickedRole = await _askRole();
        if (pickedRole == null) {
          return;
        }
        await AuthService.ensureUserProfile(
          uid: user.uid,
          role: pickedRole,
          displayName: user.displayName,
          provider: credential.additionalUserInfo?.providerId ?? 'oauth',
        );
      }
    });
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('고객'),
          selected: _signupRole == UserRole.customer,
          onSelected: _loading
              ? null
              : (_) => setState(() => _signupRole = UserRole.customer),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('업체'),
          selected: _signupRole == UserRole.business,
          onSelected: _loading
              ? null
              : (_) => setState(() => _signupRole = UserRole.business),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputAction? action,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: action,
      onSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildSocialButtons({required bool isSignup}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _loading
              ? null
              : () => isSignup
                  ? _handleSocialSignup(AuthService.signInWithGoogle)
                  : _handleSocialLogin(AuthService.signInWithGoogle),
          icon: const Icon(Icons.g_mobiledata),
          label: const Text('Google로 시작'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _loading
              ? null
              : () => isSignup
                  ? _handleSocialSignup(AuthService.signInWithNaver)
                  : _handleSocialLogin(AuthService.signInWithNaver),
          icon: const Icon(Icons.filter_1),
          label: const Text('네이버로 시작'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _loading
              ? null
              : () => isSignup
                  ? _handleSocialSignup(AuthService.signInWithKakao)
                  : _handleSocialLogin(AuthService.signInWithKakao),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('카카오로 시작'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: theme.colorScheme.surface,
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(_cardRadius),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '환영합니다',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '로그인 또는 회원가입을 진행해 주세요.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      labelColor: primary,
                      indicatorColor: primary,
                      tabs: const [
                        Tab(text: '로그인'),
                        Tab(text: '회원가입'),
                      ],
                    ),
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: ListView(
                              children: [
                                _buildField(
                                  controller: _loginIdController,
                                  label: '아이디',
                                  action: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  controller: _loginPwController,
                                  label: '비밀번호',
                                  obscureText: true,
                                  action: TextInputAction.done,
                                  onSubmitted:
                                      _loading ? null : _handleLogin,
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text('로그인'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '관리자 로그인: ID는 admin, 초기 비밀번호는 0000',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 20),
                                _buildSectionTitle('간편 로그인'),
                                const SizedBox(height: 10),
                                _buildSocialButtons(isSignup: false),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: ListView(
                              children: [
                                _buildSectionTitle('회원 유형 선택'),
                                const SizedBox(height: 8),
                                _buildRoleSelector(),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _signupIdController,
                                  label: '아이디',
                                  action: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                _buildField(
                                  controller: _signupPwController,
                                  label: '비밀번호',
                                  obscureText: true,
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _handleSignup,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text('아이디/비밀번호로 가입'),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildSectionTitle('간편 회원가입'),
                                const SizedBox(height: 10),
                                _buildSocialButtons(isSignup: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
