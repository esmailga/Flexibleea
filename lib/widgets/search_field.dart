import 'dart:async';

import 'package:flutter/material.dart';

/// Rounded search box that debounces input and offers a clear button.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Search',
    this.debounce = const Duration(milliseconds: 250),
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final Duration debounce;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {}); // Toggle the clear button.
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    setState(() {});
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _changed,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        suffixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
          child: _controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  key: const ValueKey('clear'),
                  tooltip: 'Clear search',
                  onPressed: _clear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}
