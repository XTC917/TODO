import '../providers/app_providers.dart';
import '../providers/l10n_providers.dart';
import 'english_natural_language_parser.dart';
import 'natural_language_parser.dart';
import 'parsed_task.dart';

/// Supported natural-language input locales for quick add.
enum QuickAddParserLanguage { zh, en }

/// Returns the parser language for the current app language, or `null` if unsupported.
QuickAddParserLanguage? resolveQuickAddParserLanguage(AppLanguage language) {
  final code = resolveAppLocale(language).languageCode;
  return switch (code) {
    'zh' => QuickAddParserLanguage.zh,
    'en' => QuickAddParserLanguage.en,
    _ => null,
  };
}

/// Parses quick-add input using language-specific local rules (no AI / network).
ParsedTask parseQuickAddInput(
  String input, {
  required QuickAddParserLanguage language,
  DateTime? reference,
}) {
  return switch (language) {
    QuickAddParserLanguage.zh =>
      ChineseNaturalLanguageParser().parse(input, reference: reference),
    QuickAddParserLanguage.en =>
      EnglishNaturalLanguageParser().parse(input, reference: reference),
  };
}
