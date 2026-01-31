enum UserRole {
  customer,
  business,
  admin,
}

extension UserRoleValue on UserRole {
  String get value {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.business:
        return 'business';
      case UserRole.admin:
        return 'admin';
    }
  }
}

UserRole? userRoleFromString(String? value) {
  switch (value) {
    case 'customer':
      return UserRole.customer;
    case 'business':
      return UserRole.business;
    case 'admin':
      return UserRole.admin;
  }
  return null;
}
