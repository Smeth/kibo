import 'package:flutter/material.dart';
import 'trust_scope.dart';

class OfficialBadge extends StatefulWidget {
  const OfficialBadge({super.key, required this.userId, this.verify});
  final String userId;
  final Future<bool> Function(String)? verify;
  @override
  State<OfficialBadge> createState() => _OfficialBadgeState();
}

class _OfficialBadgeState extends State<OfficialBadge> {
  Future<bool>? _verified;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verified ??= _load();
  }

  Future<bool> _load() async {
    try {
      if (widget.verify != null) return await widget.verify!(widget.userId);
      return await TrustScope.maybeClient(
            context,
          )?.rpc('kibo_is_official', params: {'p_user': widget.userId}) ==
          true;
    } catch (_) {
      return false;
    }
  }

  @override
  void didUpdateWidget(OfficialBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _verified = _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _verified,
    builder: (context, snapshot) =>
        snapshot.connectionState != ConnectionState.done ||
            snapshot.data != true
        ? const SizedBox.shrink()
        : const Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Icon(Icons.verified_outlined, size: 20),
              Text('Équipe KIBO'),
            ],
          ),
  );
}
