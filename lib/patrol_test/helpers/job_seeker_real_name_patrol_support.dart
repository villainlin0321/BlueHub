import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/files/data/file_models.dart';
import '../../features/me/data/user_models.dart';
import '../../shared/network/api_client.dart';
import '../../shared/network/services/file_service.dart';
import '../../shared/network/services/user_service.dart';
import '../../utils/upload_picker_utils.dart';

/// 求职者实名认证 Patrol 支撑：仅在显式开启环境变量时提供测试替身。
class JobSeekerRealNamePatrolSupport {
  JobSeekerRealNamePatrolSupport();

  static const bool enabled = bool.fromEnvironment(
    'PATROL_FAKE_REAL_NAME_FLOW',
    defaultValue: false,
  );

  int _nextFileId = 9000;

  /// 按身份证正反面返回稳定的伪图片结果，避免 Patrol 依赖系统相册与相机。
  Future<List<PickedUploadFile>> pickImages(
    BuildContext context, {
    required bool isEmblemSide,
  }) async {
    final String side = isEmblemSide ? 'emblem' : 'portrait';
    return <PickedUploadFile>[
      PickedUploadFile(
        id: 'patrol-real-name-$side',
        name: 'patrol_$side.png',
        path: '/patrol/$side.png',
        sourceType: UploadSourceType.gallery,
        state: UploadItemState.success,
        isImage: true,
      ),
    ];
  }

  /// 为 Patrol 返回稳定的伪上传结果，避免依赖真实文件系统与对象存储。
  FilePresignVO buildUploadedFile({required String path}) {
    final int fileId = _nextFileId++;
    final String normalizedPath = path.replaceAll('/', '_');
    return FilePresignVO(
      uploadUrl: 'https://patrol.local/upload/$fileId',
      fileUrl: 'https://patrol.local/file/$normalizedPath',
      expireIn: 3600,
      objectKey: 'patrol/$normalizedPath',
      fileId: fileId,
    );
  }
}

/// 仅在 Patrol 实名流程中启用的支撑对象；生产默认返回 `null`。
final jobSeekerRealNamePatrolSupportProvider =
    Provider<JobSeekerRealNamePatrolSupport?>((ref) {
      if (!JobSeekerRealNamePatrolSupport.enabled) {
        return null;
      }
      return JobSeekerRealNamePatrolSupport();
    });

/// Patrol 实名文件服务替身：身份证图片上传直接返回伪远端地址，其他场景走真实实现。
class PatrolRealNameFileService extends FileService {
  PatrolRealNameFileService({
    required ApiClient apiClient,
    required this.support,
  }) : super(apiClient: apiClient);

  final JobSeekerRealNamePatrolSupport support;

  @override
  /// 仅拦截实名认证图片上传，避免 Patrol 用例依赖本地图片与远端对象存储。
  Future<FilePresignVO> uploadFile({
    required String path,
    required FileScene scene,
    String accessType = 'PUBLIC',
    String errorMessage = '',
    void Function(int sent, int total)? onSendProgress,
  }) async {
    if (scene == FileScene.idCard) {
      return support.buildUploadedFile(path: path);
    }
    return super.uploadFile(
      path: path,
      scene: scene,
      accessType: accessType,
      errorMessage: errorMessage,
      onSendProgress: onSendProgress,
    );
  }
}

/// Patrol 实名用户服务替身：实名提交成功后，把后续 `getMe()` 结果切换为已实名。
class PatrolRealNameUserService extends UserService {
  PatrolRealNameUserService({required ApiClient apiClient})
    : super(apiClient: apiClient);

  UserVO? _verifiedUser;

  @override
  /// 实名提交后不调用真实接口，直接记录已实名快照供刷新当前用户资料时回读。
  Future<void> realNameVerify({required RealNameVerifyBO request}) async {
    final UserVO profile = await super.getMe();
    _verifiedUser = UserVO(
      userId: profile.userId,
      phone: profile.phone,
      email: profile.email,
      nickname: profile.nickname,
      avatarUrl: profile.avatarUrl,
      gender: profile.gender,
      birthday: profile.birthday,
      role: profile.role,
      currentLocation: profile.currentLocation,
      isVerified: true,
      blacklistCount: profile.blacklistCount,
      createdAt: profile.createdAt,
    );
  }

  @override
  /// 若 Patrol 已完成实名认证提交，则优先返回已实名快照。
  Future<UserVO> getMe() async {
    return _verifiedUser ?? super.getMe();
  }
}
