import '../../shell/application/shell_role_provider.dart';

const String workerRoleId = 'worker';
const String employerRoleId = 'employer';
const String visaProviderRoleId = 'visa_provider';

ShellRole shellRoleFromApiRole(String role) {
  switch (role) {
    case employerRoleId:
      return ShellRole.company;
    case visaProviderRoleId:
      return ShellRole.serviceProvider;
    case workerRoleId:
    default:
      return ShellRole.jobSeeker;
  }
}

String apiRoleFromSelection(String roleId) {
  switch (roleId) {
    case 'visaProvider':
      return visaProviderRoleId;
    case employerRoleId:
    case visaProviderRoleId:
    case workerRoleId:
    default:
      return roleId.isEmpty ? workerRoleId : roleId;
  }
}

String apiRoleFromShellRole(ShellRole role) {
  switch (role) {
    case ShellRole.company:
      return employerRoleId;
    case ShellRole.serviceProvider:
      return visaProviderRoleId;
    case ShellRole.jobSeeker:
      return workerRoleId;
  }
}
