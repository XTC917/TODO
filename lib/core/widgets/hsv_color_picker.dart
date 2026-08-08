import 'package:flutter/material.dart';

/// Continuous HSL color picker with hue, saturation, and lightness sliders.
class HsvColorPicker extends StatefulWidget {
  const HsvColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
    this.hueLabel,
    this.saturationLabel,
    this.lightnessLabel,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final String? hueLabel;
  final String? saturationLabel;
  final String? lightnessLabel;

  @override
  State<HsvColorPicker> createState() => _HsvColorPickerState();
}

class _HsvColorPickerState extends State<HsvColorPicker> {
  late HSLColor _hsl;

  @override
  void initState() {
    super.initState();
    _hsl = HSLColor.fromColor(widget.color);
  }

  @override
  void didUpdateWidget(HsvColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) {
      _hsl = HSLColor.fromColor(widget.color);
    }
  }

  void _emit(HSLColor next) {
    setState(() => _hsl = next);
    widget.onChanged(next.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final preview = _hsl.toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: preview,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SliderRow(
          label: widget.hueLabel ?? 'Hue',
          value: _hsl.hue,
          min: 0,
          max: 360,
          activeColor: HSLColor.fromAHSL(1, _hsl.hue, 0.75, 0.5).toColor(),
          onChanged: (v) => _emit(_hsl.withHue(v)),
        ),
        const SizedBox(height: 8),
        _SliderRow(
          label: widget.saturationLabel ?? 'Saturation',
          value: _hsl.saturation,
          min: 0,
          max: 1,
          activeColor: HSLColor.fromAHSL(1, _hsl.hue, _hsl.saturation, 0.5)
              .toColor(),
          onChanged: (v) => _emit(_hsl.withSaturation(v)),
        ),
        const SizedBox(height: 8),
        _SliderRow(
          label: widget.lightnessLabel ?? 'Lightness',
          value: _hsl.lightness,
          min: 0,
          max: 1,
          activeColor: HSLColor.fromAHSL(1, _hsl.hue, _hsl.saturation, _hsl.lightness)
              .toColor(),
          onChanged: (v) => _emit(_hsl.withLightness(v)),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.16),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
