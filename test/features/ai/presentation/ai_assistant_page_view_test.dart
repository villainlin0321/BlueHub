import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/features/ai/application/ai_assistant/ai_assistant_state.dart';
import 'package:europepass/features/ai/presentation/widgets/ai_assistant_page_view.dart';
import 'package:europepass/shared/localization/app_locales.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Android 下强制回退为文本输入，不显示语音入口', (WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: 'assets/translations',
        fallbackLocale: AppLocales.english,
        startLocale: AppLocales.chinese,
        saveLocale: false,
        useOnlyLangCode: true,
        child: MaterialApp(
          home: AiAssistantPageView(
            state: const AiAssistantState(
              composerMode: AiAssistantComposerMode.voice,
              voiceInputState: AiAssistantVoiceInputState.listening,
              voiceSeconds: 5,
            ),
            controller: TextEditingController(),
            focusNode: FocusNode(),
            scrollController: ScrollController(),
            isVoiceInputEnabled: false,
            onOpenHistory: () {},
            onToggleComposerMode: () {},
            onSend: () async {},
            onVoiceRecordStart: () async {},
            onVoiceRecordEnd: () async {},
            onVoiceRecordMoveUpdate: (_) {},
            onApplyJob: (_) async {},
            onOpenJobDetail: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('ai_assistant_text_input')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('ai_assistant_voice_toggle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('ai_assistant_voice_record_button')),
      findsNothing,
    );
  });
}
