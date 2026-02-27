/// Secure storage key names.
///
/// These keys are used by [SecureTokenStorage] to persist auth/session data.
class StorageKeys {
  StorageKeys._();

  static const String token = 'access_token';
  static const String employeeId = 'employee_id';
  static const String companyId = 'company_id';
}
