import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/digitransit.dart';
import '../theme.dart';

class AutocompleteInput extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChangeText;
  final ValueChanged<GeocodeSuggestion> onSelect;
  final String placeholder;
  final String variant; // 'origin' or 'destination'
  final VoidCallback? onSubmitted;
  final VoidCallback? onRequestLocation;
  final VoidCallback? onClear;
  final ({double lat, double lon})? focusPoint;

  const AutocompleteInput({
    super.key,
    required this.value,
    required this.onChangeText,
    required this.onSelect,
    required this.placeholder,
    required this.variant,
    this.onSubmitted,
    this.onRequestLocation,
    this.onClear,
    this.focusPoint,
  });

  @override
  State<AutocompleteInput> createState() => _AutocompleteInputState();
}

class _AutocompleteInputState extends State<AutocompleteInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlay = OverlayPortalController();
  List<GeocodeSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _selected = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _overlay.isShowing) _overlay.hide();
        });
      } else if (_suggestions.isNotEmpty && !_selected) {
        _overlay.show();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AutocompleteInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String text) {
    _selected = false;
    widget.onChangeText(text);
    _debounce?.cancel();
    if (text.length < 2) {
      setState(() => _suggestions = []);
      if (_overlay.isShowing) _overlay.hide();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await autocomplete(text, focusPoint: widget.focusPoint);
      if (!_selected && mounted) {
        setState(() => _suggestions = results);
        if (results.isNotEmpty) {
          if (!_overlay.isShowing) _overlay.show();
        } else {
          if (_overlay.isShowing) _overlay.hide();
        }
      }
    });
  }

  void _handleSelect(GeocodeSuggestion s) {
    _selected = true;
    _controller.text = s.label;
    widget.onChangeText(s.label);
    widget.onSelect(s);
    setState(() => _suggestions = []);
    if (_overlay.isShowing) _overlay.hide();
    FocusScope.of(context).unfocus();
  }

  void _handleClear() {
    _selected = false;
    _controller.clear();
    widget.onChangeText('');
    setState(() => _suggestions = []);
    if (_overlay.isShowing) _overlay.hide();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isOrigin = widget.variant == 'origin';
    final icon = isOrigin ? LucideIcons.circleDot : LucideIcons.mapPin;
    final iconColor = isOrigin ? AppColors.primary : AppColors.destRed;

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: (context) {
          return Positioned(
            width: MediaQuery.of(context).size.width - AppSpacing.lg * 2,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 52),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        offset: Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _suggestions.length; i++)
                        InkWell(
                          onTap: () => _handleSelect(_suggestions[i]),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: i < _suggestions.length - 1
                                      ? AppColors.borderLight
                                      : Colors.transparent,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.mapPin,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _suggestions[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _handleChanged,
                  onSubmitted: (_) => widget.onSubmitted?.call(),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: widget.placeholder,
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: _handleClear,
                  child: const Icon(LucideIcons.x,
                      size: 18, color: AppColors.textMuted),
                )
              else if (isOrigin && widget.onRequestLocation != null)
                GestureDetector(
                  onTap: widget.onRequestLocation,
                  child: const Icon(LucideIcons.locateFixed,
                      size: 20, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
