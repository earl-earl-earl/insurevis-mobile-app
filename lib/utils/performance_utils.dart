import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PerformanceUtils {
  // Cache images for better performance
  static const Map<String, Image> _imageCache = {};

  // Get a cached image
  static Image getCachedImage(String path) {
    if (_imageCache.containsKey(path)) {
      return _imageCache[path]!;
    }

    final image = Image.asset(
      path,
      cacheHeight: 500, // Adjust based on your needs
      cacheWidth: 500,
      filterQuality: FilterQuality.medium,
    );

    _imageCache[path] = image;
    return image;
  }

  // Optimize heavy widgets with a builder that prevents unnecessary rebuilds
  static Widget optimizedBuilder({
    required Widget Function() builder,
    List<Object?>? dependencies,
  }) {
    if (dependencies == null) {
      return builder();
    }

    return _OptimizedWidget(builder: builder, dependencies: dependencies);
  }

  // Throttle a function to avoid excessive calls
  static Function throttle(Function callback, int milliseconds) {
    int lastCall = 0;
    return () {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastCall >= milliseconds) {
        lastCall = now;
        callback();
      }
    };
  }
}

class _OptimizedWidget extends StatefulWidget {
  final Widget Function() builder;
  final List<Object?> dependencies;

  const _OptimizedWidget({required this.builder, required this.dependencies});

  @override
  _OptimizedWidgetState createState() => _OptimizedWidgetState();
}

class _OptimizedWidgetState extends State<_OptimizedWidget> {
  late Widget _child;

  @override
  void initState() {
    super.initState();
    _child = widget.builder();
  }

  @override
  void didUpdateWidget(_OptimizedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.dependencies, oldWidget.dependencies)) {
      _child = widget.builder();
    }
  }

  @override
  Widget build(BuildContext context) => _child;
}
