import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// 颜色选择器字段组件
class ColorPickerField extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onChanged;
  final String? label;
  final bool showLabel;

  const ColorPickerField({
    super.key,
    required this.color,
    required this.onChanged,
    this.label,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // 颜色预览
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 标签
            if (showLabel)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label ?? '颜色', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      _colorToHex(color),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    Color pickedColor = color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 预设颜色
              _buildPresetColors(context, (c) {
                pickedColor = c;
                Navigator.pop(context);
                onChanged(c);
              }),
              const Divider(height: 32),
              // 自定义颜色选择器
              ColorPicker(
                pickerColor: pickedColor,
                onColorChanged: (c) => pickedColor = c,
                enableAlpha: false,
                labelTypes: const [],
                pickerAreaHeightPercent: 0.7,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onChanged(pickedColor);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetColors(
    BuildContext context,
    ValueChanged<Color> onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '预设颜色',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: presetColors.map((c) {
            final isSelected = c.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => onSelect(c),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: c.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 20, color: _contrastColor(c))
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// 预设颜色列表
const List<Color> presetColors = [
  Color(0xFFE57373), // 红色
  Color(0xFFF06292), // 粉色
  Color(0xFFBA68C8), // 紫色
  Color(0xFF9575CD), // 深紫色
  Color(0xFF7986CB), // 靛蓝色
  Color(0xFF64B5F6), // 蓝色
  Color(0xFF4FC3F7), // 浅蓝色
  Color(0xFF4DD0E1), // 青色
  Color(0xFF4DB6AC), // 蓝绿色
  Color(0xFF81C784), // 绿色
  Color(0xFFAED581), // 浅绿色
  Color(0xFFDCE775), // 酸橙色
  Color(0xFFFFF176), // 黄色
  Color(0xFFFFD54F), // 琥珀色
  Color(0xFFFFB74D), // 橙色
  Color(0xFFFF8A65), // 深橙色
  Color(0xFFA1887F), // 棕色
  Color(0xFF90A4AE), // 蓝灰色
];

/// 简洁的颜色指示器（用于列表项）
class ColorIndicator extends StatelessWidget {
  final Color color;
  final double size;

  const ColorIndicator({super.key, required this.color, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// 内联颜色选择器（显示预设颜色列表）
class InlineColorPicker extends StatelessWidget {
  final Color? selectedColor;
  final ValueChanged<Color> onColorSelected;
  final double itemSize;
  final double spacing;

  const InlineColorPicker({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
    this.itemSize = 32,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: presetColors.map((color) {
        final isSelected =
            selectedColor != null &&
            color.toARGB32() == selectedColor!.toARGB32();

        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: itemSize * 0.5,
                    color: _contrastColor(color),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
