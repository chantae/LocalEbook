import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/features/admin/admin_home_page.dart';
import 'package:my_ebook/features/auth/auth_page.dart';
import 'package:my_ebook/features/bookmarks/bookmarks_page.dart';
import 'package:my_ebook/features/business_owner/business_owner_page.dart';
import 'package:my_ebook/models/user_role.dart';
import 'package:my_ebook/services/auth_service.dart';

enum _AccountAction {
  bookmarks,
  businessPortal,
  adminPanel,
  logout,
}

class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return IconButton(
            tooltip: '로그인',
            icon: const Icon(Icons.login),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthPage()),
              );
            },
          );
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: AuthService.userDocStream(user.uid),
          builder: (context, profileSnapshot) {
            final data = profileSnapshot.data?.data();
            final role = userRoleFromString(data?['role'] as String?);
            final roleLabel = switch (role) {
              UserRole.business => '업체',
              UserRole.admin => '관리자',
              _ => '고객',
            };
            return PopupMenuButton<_AccountAction>(
              tooltip: '계정',
              icon: const Icon(Icons.account_circle),
              onSelected: (action) async {
                switch (action) {
                  case _AccountAction.bookmarks:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BookmarksPage(),
                      ),
                    );
                    break;
                  case _AccountAction.businessPortal:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BusinessOwnerPage(),
                      ),
                    );
                    break;
                  case _AccountAction.adminPanel:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminHomePage(),
                      ),
                    );
                    break;
                  case _AccountAction.logout:
                    await AuthService.signOut();
                    break;
                }
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem<_AccountAction>(
                    enabled: false,
                    child: Text('${user.email ?? user.uid} ($roleLabel)'),
                  ),
                  const PopupMenuItem<_AccountAction>(
                    value: _AccountAction.bookmarks,
                    child: Text('찜한 업체'),
                  ),
                  if (role == UserRole.business)
                    const PopupMenuItem<_AccountAction>(
                      value: _AccountAction.businessPortal,
                      child: Text('업체 페이지 관리'),
                    ),
                  if (role == UserRole.admin)
                    const PopupMenuItem<_AccountAction>(
                      value: _AccountAction.adminPanel,
                      child: Text('관리자 페이지'),
                    ),
                  const PopupMenuItem<_AccountAction>(
                    value: _AccountAction.logout,
                    child: Text('로그아웃'),
                  ),
                ];
              },
            );
          },
        );
      },
    );
  }
}
