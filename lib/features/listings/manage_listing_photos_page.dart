import 'dart:math';
import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';
import 'listing_photos.dart';
import 'listing_photo_widgets.dart';

class ManageListingPhotosPage extends StatefulWidget {
  const ManageListingPhotosPage({
    super.key,
    required this.listing,
    required this.owner,
    required this.repository,
    required this.picker,
  });
  final String listing, owner;
  final ListingGalleryRepository repository;
  final ListingPhotoPicker picker;
  @override
  State<ManageListingPhotosPage> createState() =>
      _ManageListingPhotosPageState();
}

class _ManageListingPhotosPageState extends State<ManageListingPhotosPage> {
  AuthController? _auth;
  void _changed() {
    if (_auth?.identity?.id != widget.owner) {
      _invalid = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_changed);
    super.dispose();
  }

  GalleryState? _state;
  List<GalleryPhoto> _photos = [];
  bool _busy = false, _invalid = false, _attempted = false;
  String? _error;
  String _operation = '';
  bool get _current =>
      mounted &&
      !_invalid &&
      AuthScope.maybeOf(context)?.identity?.id == widget.owner;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    if (_auth != auth) {
      _auth?.removeListener(_changed);
      _auth = auth;
      _auth?.addListener(_changed);
    }
    if (AuthScope.maybeOf(context)?.identity?.id != widget.owner) {
      _invalid = true;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  String _uuid() {
    final r = Random.secure();
    final b = List.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<void> _load() async {
    if (!_current || _busy) return;
    setState(() => _busy = true);
    try {
      final state = await widget.repository.gallery(
        widget.listing,
        widget.owner,
      );
      if (_current) {
        setState(() {
          _state = state;
          _photos = state.paths.map(GalleryPhoto.existing).toList();
          _attempted = false;
          _error = null;
          _operation = _uuid();
        });
      }
    } catch (_) {
      if (_current) {
        setState(() => _error = 'Impossible de charger la galerie.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    if (!_current || _busy || _attempted) return;
    setState(() => _busy = true);
    try {
      final added = await widget.picker.pick(widget.owner);
      if (_current) {
        if (_photos.length + added.length > 3) {
          throw const PhotoValidationException(
            'Trois photos maximum. Retirez une photo avant d’en ajouter.',
          );
        }
        setState(() {
          for (final p in added) {
            if (!_photos.any((x) => x.draft?.digest == p.digest)) {
              _photos.add(GalleryPhoto.added(p));
            }
          }
          _error = null;
        });
      }
    } catch (e) {
      if (_current) {
        setState(
          () => _error = e is PhotoValidationException
              ? e.message
              : 'Sélection indisponible. Réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_current || _busy || _state == null || !_state!.editable) return;
    setState(() {
      _busy = true;
      _attempted = true;
      _error = null;
    });
    try {
      final result = await widget.repository.saveGallery(
        widget.listing,
        widget.owner,
        _state!.revision,
        _operation,
        List.of(_photos),
      );
      if (mounted && _current) {
        Navigator.pop(
          context,
          GalleryState(
            result.paths,
            result.revision,
            result.updatedAt,
            result.editable,
            baseUpdatedAt: _state!.updatedAt,
          ),
        );
      }
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Enregistrement non confirmé. Réessayez avec cette sélection ou rechargez la galerie pour vérifier son état.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Gérer les photos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Jusqu’à 3 photos. La première sera la couverture. Les changements sont appliqués ensemble après enregistrement.',
          ),
          const SizedBox(height: 24),
          if (_invalid)
            const Text('La session a changé. Revenez à vos annonces.')
          else ...[
            for (var i = 0; i < _photos.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 160,
                          width: double.infinity,
                          child: _photos[i].draft != null
                              ? Image.memory(
                                  _photos[i].draft!.bytes,
                                  fit: BoxFit.cover,
                                )
                              : ListingPhotoView(
                                  path: _photos[i].path!,
                                  label: 'Photo ${i + 1}',
                                ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (i == 0) const Chip(label: Text('Couverture')),
                            IconButton(
                              tooltip: 'Déplacer avant',
                              onPressed: _busy || _attempted || i == 0
                                  ? null
                                  : () => setState(() {
                                      final p = _photos.removeAt(i);
                                      _photos.insert(i - 1, p);
                                    }),
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            IconButton(
                              tooltip: 'Déplacer après',
                              onPressed:
                                  _busy || _attempted || i == _photos.length - 1
                                  ? null
                                  : () => setState(() {
                                      final p = _photos.removeAt(i);
                                      _photos.insert(i + 1, p);
                                    }),
                              icon: const Icon(Icons.arrow_downward),
                            ),
                            IconButton(
                              tooltip: 'Retirer la photo',
                              onPressed: _busy || _attempted
                                  ? null
                                  : () => setState(() => _photos.removeAt(i)),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_state?.editable == true && _photos.length < 3)
              OutlinedButton.icon(
                onPressed: _busy || _attempted ? null : _pick,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Ajouter des photos'),
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Semantics(liveRegion: true, child: Text(_error!)),
              const SizedBox(height: 16),
            ],
            if (_busy) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            if (_state?.editable == true)
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(
                  _attempted
                      ? 'Réessayer l’enregistrement'
                      : 'Enregistrer la galerie',
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : _load,
              child: const Text('Recharger la galerie'),
            ),
          ],
        ],
      ),
    ),
  );
}
