import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';
import 'safety_repository.dart';
import '../../core/widgets/kibo_section.dart';

class SafetyEntry extends StatefulWidget {
  const SafetyEntry({
    super.key,
    required this.repository,
    required this.onPressed,
    this.moderation = false,
    this.revision = 0,
    this.showLabel = false,
    this.moderationLabel = 'Modération',
  });
  final SafetyRepository repository;
  final VoidCallback onPressed;
  final bool moderation;
  final int revision;
  final bool showLabel;
  final String moderationLabel;
  @override
  State<SafetyEntry> createState() => _SafetyEntryState();
}

class _SafetyEntryState extends State<SafetyEntry> with WidgetsBindingObserver {
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _timer?.cancel();
    if (_foreground && _owner != null) {
      unawaited(_reload());
      if (!widget.moderation) {
        _timer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => unawaited(_reload()),
        );
      }
    }
  }

  @override
  void didUpdateWidget(SafetyEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) unawaited(_reload());
  }

  AuthController? _auth;
  String? _owner;
  int _epoch = 0;
  int? _count;
  bool _allowed = false;
  Timer? _timer;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_changed);
      _auth = auth;
      _auth?.addListener(_changed);
    }
    _changed();
  }

  void _changed() {
    final owner = _auth?.identity?.id;
    if (owner == _owner) return;
    _owner = owner;
    _epoch++;
    _count = null;
    _allowed = false;
    _timer?.cancel();
    if (owner != null) {
      unawaited(_reload());
      if (!widget.moderation) {
        _timer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => unawaited(_reload()),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    if (!_foreground) return;
    final owner = _owner, epoch = _epoch;
    if (owner == null) return;
    try {
      final value = widget.moderation
          ? await widget.repository.canModerate(owner)
          : await widget.repository.unreadCount(owner);
      if (!mounted || epoch != _epoch || widget.repository.userId != owner) {
        return;
      }
      setState(() {
        if (widget.moderation) {
          _allowed = value == true;
        } else {
          _count = value as int;
        }
      });
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(() {
          _count = null;
          _allowed = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _epoch++;
    _timer?.cancel();
    _auth?.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.moderation
      ? _allowed
            ? KiboMenuAction(
                onTap: widget.onPressed,
                icon: Icons.admin_panel_settings_outlined,
                label: widget.moderationLabel,
              )
            : const SizedBox.shrink()
      : widget.showLabel
      ? Tooltip(
          message: 'Notifications',
          child: TextButton.icon(
            onPressed: widget.onPressed,
            icon: Padding(
              padding: EdgeInsets.only(
                right: (_count ?? 0) > 0
                    ? MediaQuery.textScalerOf(context).scale(16)
                    : 0,
              ),
              child: Badge(
                isLabelVisible: (_count ?? 0) > 0,
                label: Text((_count ?? 0) >= 100 ? '99+' : '$_count'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
            label: const Text('Notifications'),
          ),
        )
      : IconButton(
          tooltip: 'Notifications',
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12 +
                ((_count ?? 0) > 0
                    ? MediaQuery.textScalerOf(context).scale(12)
                    : 0),
            12,
          ),
          onPressed: widget.onPressed,
          icon: Badge(
            isLabelVisible: (_count ?? 0) > 0,
            label: Text((_count ?? 0) >= 100 ? '99+' : '$_count'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        );
}
