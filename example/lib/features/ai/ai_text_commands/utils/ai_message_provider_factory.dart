import 'package:flutter/widgets.dart';

import '../enum/ai_provider_enum.dart';
import '../providers/ai_message_base_provider.dart';
import '../providers/ai_message_gemini_provider.dart';
import '../providers/ai_message_open_ai_provider.dart';

/// Factory class to create AI message providers based on the selected type.
class AiMessageProviderFactory {
  /// Creates an AI message provider for the given context, type, and API key.
  static AiMessageBaseProvider create({
    required BuildContext context,
    required AiProvider provider,
    required String apiKey,
  }) {
    switch (provider) {
      case AiProvider.gemini:
        return AiMessageGeminiProvider(
          apiKey: apiKey,
          context: context,
        );
      case AiProvider.openAi:
        return AiMessageOpenAiProvider(
          apiKey: apiKey,
          context: context,
        );
    }
  }
}
