import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AppearanceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureAppearanceStore implements AppearanceStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'kibo_appearance_mode';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

class AppearanceController extends ChangeNotifier {
  AppearanceController(this.store);
  final AppearanceStore store;
  ThemeMode mode = ThemeMode.system;
  int _revision = 0;
  bool _disposed = false;
  String? error;
  Future<void> _writes = Future<void>.value();
  Future<void> initialize() async {
    final revision = _revision;
    try {
      final saved = await store.read();
      if (_disposed || revision != _revision) return;
      mode = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    } catch (_) {
      /* Le choix système reste disponible si le stockage manque. */
    }
  }

  Future<void> select(ThemeMode value) async {
    final revision = ++_revision;
    mode = value;
    error = null;
    notifyListeners();
    try {
      final write = _writes.then((_) => store.write(value.name));
      _writes = write.catchError((Object _) {});
      await write;
    } catch (_) {
      if (!_disposed && revision == _revision) {
        error = 'Choix appliqué. Sa mémorisation a échoué.';
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppearanceController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.notifier;
}

class AppearancePicker extends StatelessWidget {
  const AppearancePicker({super.key, this.showHeading = true});
  final bool showHeading;
  @override
  Widget build(BuildContext context) {
    final controller = AppearanceScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeading) ...[
          Text('Apparence', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mode in ThemeMode.values)
              ChoiceChip(
                label: Text(switch (mode) {
                  ThemeMode.system => 'Appareil',
                  ThemeMode.light => 'Clair',
                  ThemeMode.dark => 'Sombre',
                }),
                selected: controller.mode == mode,
                onSelected: (_) => controller.select(mode),
              ),
          ],
        ),
        if (controller.error != null)
          Semantics(liveRegion: true, child: Text(controller.error!)),
      ],
    );
  }
}
