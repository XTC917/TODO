import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/theme_palette.dart';
import '../../core/widgets/hsv_color_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import 'widgets/settings_widgets.dart';

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final palette = ref.watch(themePaletteProvider);
    final isDark = themeMode == ThemeMode.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return SettingsSubpageScaffold(
      title: l10n.settingsAppearance,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsTheme,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeOption(
                        label: l10n.themeLight,
                        selected: !isDark,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ThemeOption(
                        label: l10n.themeDark,
                        selected: isDark,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setMode(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.accentColor,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ...AccentColor.values.map((c) {
                          final selected =
                              !palette.isCustomAccent && c == palette.preset;
                          return _ColorSwatch(
                            color: c.seed,
                            selected: selected,
                            onTap: () => ref
                                .read(themePaletteProvider.notifier)
                                .setPresetAccent(c),
                          );
                        }),
                        _ColorSwatch(
                          color: palette.seedColor,
                          selected: palette.isCustomAccent,
                          icon: Icons.palette_outlined,
                          onTap: () {
                            if (!palette.isCustomAccent) {
                              ref
                                  .read(themePaletteProvider.notifier)
                                  .setCustomSeed(palette.seedColor);
                            }
                          },
                        ),
                      ],
                    ),
                    if (palette.isCustomAccent) ...[
                      const SizedBox(height: 16),
                      HsvColorPicker(
                        color: palette.seedColor,
                        hueLabel: l10n.colorHue,
                        saturationLabel: l10n.colorSaturation,
                        lightnessLabel: l10n.colorLightness,
                        onChanged: (color) => ref
                            .read(themePaletteProvider.notifier)
                            .setCustomSeed(color),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.backgroundColor,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ThemeOption(
                            label: l10n.backgroundFollowAccent,
                            selected:
                                palette.backgroundMode == BackgroundMode.followAccent,
                            onTap: () => ref
                                .read(themePaletteProvider.notifier)
                                .setBackgroundMode(BackgroundMode.followAccent),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ThemeOption(
                            label: l10n.backgroundCustom,
                            selected:
                                palette.backgroundMode == BackgroundMode.custom,
                            onTap: () async {
                              final notifier =
                                  ref.read(themePaletteProvider.notifier);
                              await notifier.setBackgroundMode(
                                BackgroundMode.custom,
                              );
                              await notifier.setCustomBackground(
                                palette.customBackgroundFor(brightness),
                                brightness,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (palette.backgroundMode == BackgroundMode.custom) ...[
                      const SizedBox(height: 16),
                      HsvColorPicker(
                        color: palette.customBackgroundFor(brightness),
                        hueLabel: l10n.colorHue,
                        saturationLabel: l10n.colorSaturation,
                        lightnessLabel: l10n.colorLightness,
                        onChanged: (color) => ref
                            .read(themePaletteProvider.notifier)
                            .setCustomBackground(color, brightness),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      _BackgroundPreview(color: palette.backgroundFor(brightness)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: icon == null
            ? null
            : Icon(
                icon,
                size: 22,
                color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: selected ? 0.9 : 0.65,
                    ),
              ),
      ),
    );
  }
}

class _BackgroundPreview extends StatelessWidget {
  const _BackgroundPreview({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
          : Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
