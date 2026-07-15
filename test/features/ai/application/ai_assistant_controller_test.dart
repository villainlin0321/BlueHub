// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

import 'package:europepass/features/ai/application/ai_assistant/ai_assistant_controller.dart';
import 'package:europepass/features/ai/application/ai_assistant/ai_assistant_state.dart';
import 'package:europepass/features/ai/data/ai_models.dart';
import 'package:europepass/features/ai/data/ai_providers.dart';
import 'package:europepass/shared/auth/token_store.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/services/ai_service.dart';
import 'package:europepass/shared/network/sse_client.dart';
import 'package:europepass/shared/network/sse_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SpeechToTextPlatform originalPlatform;

  setUp(() {
    originalPlatform = SpeechToTextPlatform.instance;
  });

  tearDown(() {
    SpeechToTextPlatform.instance = originalPlatform;
  });

  test(
    'first voice press only requests permission, later press listens and sends after final result',
    () async {
      final _PermissionThenDelayedSpeechPlatform platform =
          _PermissionThenDelayedSpeechPlatform();
      SpeechToTextPlatform.instance = platform;
      final ProviderContainer container = ProviderContainer(
        overrides: [aiServiceProvider.overrideWithValue(_FakeAiService())],
      );
      addTearDown(container.dispose);
      final ProviderSubscription<dynamic> subscription = container.listen(
        aiAssistantControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final AiAssistantController controller = container.read(
        aiAssistantControllerProvider.notifier,
      );

      controller.toggleComposerMode();
      await controller.startVoiceInput();

      final AiAssistantState firstPressState = container.read(
        aiAssistantControllerProvider,
      );
      expect(firstPressState.voiceInputState, AiAssistantVoiceInputState.idle);
      expect(firstPressState.voiceSeconds, 0);
      expect(firstPressState.messages, isEmpty);
      expect(platform.initializeCallCount, 1);
      expect(platform.listenCallCount, 0);
      expect(
        platform.lastInitializeOptions.any(
          (SpeechConfigOption option) => option.name == 'intentLookup',
        ),
        isFalse,
      );
      expect(
        platform.lastInitializeOptions.any(
          (SpeechConfigOption option) => option.name == 'noBluetooth',
        ),
        isTrue,
      );

      await controller.startVoiceInput();

      final AiAssistantState secondPressState = container.read(
        aiAssistantControllerProvider,
      );
      expect(
        secondPressState.voiceInputState,
        AiAssistantVoiceInputState.listening,
      );
      expect(platform.listenCallCount, 1);
      final Future<void> finishFuture = controller.finishVoiceInput(
        language: 'zh',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final AiAssistantState immediateState = container.read(
        aiAssistantControllerProvider,
      );
      expect(immediateState.voiceInputState, AiAssistantVoiceInputState.idle);
      expect(immediateState.voiceSeconds, 0);
      expect(immediateState.messages, isEmpty);

      await finishFuture;

      final state = container.read(aiAssistantControllerProvider);
      expect(
        state.messages.any(
          (message) =>
              message.role == AiAssistantChatRole.user &&
              message.text == '你好世界',
        ),
        isTrue,
      );
    },
  );
}

class _FakeAiService extends AiService {
  _FakeAiService()
    : super(
        apiClient: ApiClient(Dio()),
        sseClient: SseClient(
          baseUrl: 'http://127.0.0.1',
          tokenStore: TokenStore.inMemory(),
        ),
      );

  @override
  Stream<SseEvent> chat({required AiChatBO request}) async* {}
}

class _PermissionThenDelayedSpeechPlatform extends SpeechToTextPlatform {
  static const String _locale = 'zh_CN:Chinese';
  static final String _finalResultJson = jsonEncode(<String, Object?>{
    'alternates': <Object?>[
      <String, Object?>{'recognizedWords': '你好世界', 'confidence': 0.92},
    ],
    'resultType': ResultType.finalResult.value,
  });

  bool _hasPermission = false;
  int initializeCallCount = 0;
  int listenCallCount = 0;
  List<SpeechConfigOption> lastInitializeOptions = <SpeechConfigOption>[];

  @override
  Future<bool> hasPermission() async => _hasPermission;

  @override
  Future<bool> initialize({
    debugLogging = false,
    List<SpeechConfigOption>? options,
  }) async {
    initializeCallCount++;
    lastInitializeOptions = options ?? <SpeechConfigOption>[];
    _hasPermission = true;
    return true;
  }

  @override
  Future<bool> listen({
    String? localeId,
    partialResults = true,
    onDevice = false,
    int listenMode = 0,
    sampleRate = 0,
    SpeechListenOptions? options,
  }) async {
    listenCallCount++;
    scheduleMicrotask(() => onStatus?.call(SpeechToText.listeningStatus));
    return true;
  }

  @override
  Future<void> stop() async {
    scheduleMicrotask(() => onStatus?.call(SpeechToText.notListeningStatus));
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        onTextRecognition?.call(_finalResultJson);
        onStatus?.call(SpeechToText.doneStatus);
      }),
    );
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<List<dynamic>> locales() async => <String>[_locale];
}
