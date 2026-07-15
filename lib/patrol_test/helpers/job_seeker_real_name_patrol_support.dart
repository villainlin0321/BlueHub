import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/files/data/file_models.dart';
import '../../features/me/data/user_models.dart';
import '../../shared/network/services/file_service.dart';
import '../../shared/network/services/user_service.dart';
import '../../utils/upload_picker_utils.dart';

/// 求职者实名认证 Patrol 支撑：仅在显式开启环境变量时提供测试替身。
class JobSeekerRealNamePatrolSupport {
  JobSeekerRealNamePatrolSupport();

  static const bool fakeFlowEnabled = bool.fromEnvironment(
    'PATROL_FAKE_REAL_NAME_FLOW',
    defaultValue: false,
  );
  static const bool localImageFlowEnabled = bool.fromEnvironment(
    'PATROL_REAL_NAME_TEST_IMAGES',
    defaultValue: false,
  );
  static const bool enabled = fakeFlowEnabled || localImageFlowEnabled;

  static const String _emblemAssetPath =
      'assets/images/qualification_id_emblem.png';
  static const String _portraitAssetPath =
      'assets/images/qualification_id_portrait.png';

  int _nextFileId = 9000;

  /// 按当前 Patrol 模式返回图片：
  /// - 半真实模式：回填本地真实测试文件，后续仍走真实上传与实名接口。
  /// - fake 模式：回填伪文件，仅用于纯流程验证。
  Future<List<PickedUploadFile>> pickImages(
    BuildContext context, {
    required bool isEmblemSide,
  }) async {
    if (localImageFlowEnabled) {
      return _pickBundledRealImages(isEmblemSide: isEmblemSide);
    }
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

  /// 把打包进应用的测试图片复制到临时目录，生成可被真实文件上传链路读取的本地文件。
  Future<List<PickedUploadFile>> _pickBundledRealImages({
    required bool isEmblemSide,
  }) async {
    final String side = isEmblemSide ? 'emblem' : 'portrait';
    final String assetPath = isEmblemSide
        ? _emblemAssetPath
        : _portraitAssetPath;
    final File localFile = await _copyAssetToTempFile(
      assetPath: assetPath,
      fileName: 'patrol_real_name_$side',
    );
    final int fileSize = await localFile.length();
    return <PickedUploadFile>[
      PickedUploadFile(
        id: 'patrol-real-name-$side-${DateTime.now().microsecondsSinceEpoch}',
        name: UploadPickerUtils.basename(localFile.path),
        path: localFile.path,
        sourceType: UploadSourceType.gallery,
        state: UploadItemState.success,
        isImage: true,
        sizeLabel: UploadPickerUtils.formatFileSize(fileSize),
        fileSizeBytes: fileSize,
      ),
    ];
  }

  /// 将 asset 图片落盘到应用临时目录，供真实上传接口按文件路径读取。
  Future<File> _copyAssetToTempFile({
    required String assetPath,
    required String fileName,
  }) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final Directory directory = await Directory(
      '${Directory.systemTemp.path}/patrol_real_name_assets',
    ).create(recursive: true);
    final String suffix = assetPath.toLowerCase().endsWith('.png')
        ? '.png'
        : '.jpg';
    final File file = File('${directory.path}/$fileName$suffix');
    await file.writeAsBytes(bytes, flush: true);
    return file;
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
  PatrolRealNameFileService({required super.apiClient, required this.support});

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
  PatrolRealNameUserService({required super.apiClient});

  UserVO? _verifiedUser;
  RealNameVerificationVO? _latestVerification;

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
      realName: request.realName,
      blacklistCount: profile.blacklistCount,
      createdAt: profile.createdAt,
    );
    _latestVerification = RealNameVerificationVO(
      verifyId: 1,
      realName: request.realName,
      idCardNumber: '******************',
      idCardFront: request.idCardFrontUrl,
      idCardBack: request.idCardBackUrl,
      status: 'verified',
      statusLabel: '已完成实名认证',
      rejectReason: '',
      createdAt: '2026-01-01T00:00:00Z',
      reviewedAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    );
  }

  @override
  /// 若 Patrol 已完成实名认证提交，则优先返回已实名快照。
  Future<UserVO> getMe() async {
    return _verifiedUser ?? super.getMe();
  }

  @override
  Future<List<RealNameVerificationVO>> listMyRealNameVerifications() async {
    if (_latestVerification != null) {
      return <RealNameVerificationVO>[_latestVerification!];
    }
    return const <RealNameVerificationVO>[];
  }
}
