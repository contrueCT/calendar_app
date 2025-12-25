import 'package:flutter/material.dart';
import '../../../data/models/event_model.dart';

/// 事件标记组件 - 显示在日历单元格中
class EventMarker extends StatelessWidget {
  final Color color;
  final double size;
  final int count;
  final bool showCount;

  const EventMarker({
    super.key,
    required this.color,
    this.size = 6.0,
    this.count = 1,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showCount && count > 1) {
      return Container(
        width: size * 2,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Center(
          child: Text(
            count > 9 ? '9+' : count.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 多事件标记组件 - 显示多个不同颜色的圆点
class MultiEventMarkers extends StatelessWidget {
  final List<Color>? colors;
  final List<EventInstance>? events;
  final double size;
  final int maxMarkers;
  final double spacing;

  const MultiEventMarkers({
    super.key,
    this.colors,
    this.events,
    this.size = 6.0,
    this.maxMarkers = 3,
    this.spacing = 2.0,
  }) : assert(colors != null || events != null, 'Either colors or events must be provided');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // 获取颜色列表
    final colorList = colors ?? 
        events!.map((e) => e.event.colorValue ?? colorScheme.primary).toList();
    
    if (colorList.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayColors = colorList.take(maxMarkers).toList();
    final hasMore = colorList.length > maxMarkers;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < displayColors.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          EventMarker(color: displayColors[i], size: size),
        ],
        if (hasMore) ...[
          SizedBox(width: spacing),
          Text(
            '+',
            style: TextStyle(
              fontSize: size,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ],
    );
  }
}

/// 事件条形标记 - 用于周视图和日视图
class EventBar extends StatelessWidget {
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double height;
  final bool isAllDay;

  const EventBar({
    super.key,
    required this.color,
    required this.title,
    this.subtitle,
    this.onTap,
    this.height = 24.0,
    this.isAllDay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border(
              left: BorderSide(
                color: color,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color.computeLuminance() > 0.5 
                            ? Colors.black87 
                            : color,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (subtitle != null && height >= 36) 
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              if (isAllDay)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '全天',
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
