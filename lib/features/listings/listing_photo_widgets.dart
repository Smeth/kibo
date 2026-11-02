import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'listing_photos.dart';
import '../auth/auth_controller.dart';

class ListingPhotoScope extends InheritedWidget {
  const ListingPhotoScope({
    super.key,
    required this.repository,
    required this.picker,
    required super.child,
  });
  final ListingPhotoRepository repository;
  final ListingPhotoPicker picker;
  static ListingPhotoScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ListingPhotoScope>();
  @override
  bool updateShouldNotify(ListingPhotoScope oldWidget) =>
      oldWidget.repository != repository || oldWidget.picker != picker;
}

class ListingPhotoView extends StatefulWidget {
  const ListingPhotoView({
    super.key,
    required this.path,
    required this.label,
    this.fit = BoxFit.cover,
  });
  final BoxFit fit;
  final String path, label;
  @override
  State<ListingPhotoView> createState() => _ListingPhotoViewState();
}

class _ListingPhotoViewState extends State<ListingPhotoView> {
  Future<Object>? _url;
  ListingPhotoRepository? _repository;
  int? _cacheRevision;
  String? _owner;
  Future<Object> _resolve({bool force = false}) {
    final repository = _repository!;
    final Future<Object> future = repository is CachedListingPhotoRepository
        ? (repository as CachedListingPhotoRepository).photoBytes(
            widget.path,
            force: force,
          )
        : Future<String>.sync(() => repository.signedUrl(widget.path));
    future.ignore();
    return future;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = ListingPhotoScope.maybeOf(context)?.repository;
    final owner = AuthScope.maybeOf(context)?.identity?.id;
    final revision = repository is CachedListingPhotoRepository
        ? (repository as CachedListingPhotoRepository).photoCacheRevision
        : null;
    if (_repository != repository ||
        _owner != owner ||
        _cacheRevision != revision) {
      _repository = repository;
      _owner = owner;
      _cacheRevision = revision;
      _url = repository == null ? null : _resolve();
    }
  }

  @override
  void didUpdateWidget(ListingPhotoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path) {
      _url = _repository == null ? null : _resolve();
    }
  }

  Widget _retry() => Center(
    child: IconButton(
      tooltip: 'Recharger la photo',
      icon: const Icon(Icons.broken_image_outlined),
      onPressed: _repository == null
          ? null
          : () => setState(() {
              _url = _resolve(force: true);
            }),
    ),
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<Object>(
    future: _url,
    builder: (context, snapshot) {
      if (_url == null) return _retry();
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) return _retry();
      return LayoutBuilder(
        builder: (context, constraints) {
          final width =
              ((constraints.hasBoundedWidth
                          ? constraints.maxWidth
                          : MediaQuery.sizeOf(context).width) *
                      MediaQuery.devicePixelRatioOf(context))
                  .clamp(1, 1600)
                  .ceil();
          final data = snapshot.data!;
          if (data is Uint8List) {
            return Image.memory(
              data,
              cacheWidth: width,
              fit: widget.fit,
              width: double.infinity,
              semanticLabel: widget.label,
              errorBuilder: (context, error, stack) => _retry(),
            );
          }
          return Image.network(
            data as String,
            cacheWidth: width,
            fit: widget.fit,
            width: double.infinity,
            semanticLabel: widget.label,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stack) => _retry(),
          );
        },
      );
    },
  );
}

class ListingPhotoGallery extends StatefulWidget {
  const ListingPhotoGallery({
    super.key,
    required this.paths,
    required this.title,
    this.immersive = false,
  }) : assert(paths.length > 0);
  final List<String> paths;
  final String title;
  final bool immersive;
  @override
  State<ListingPhotoGallery> createState() => _ListingPhotoGalleryState();
}

class _ListingPhotoGalleryState extends State<ListingPhotoGallery> {
  final _controller = PageController();
  int _index = 0;
  @override
  void didUpdateWidget(ListingPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paths.length != widget.paths.length ||
        oldWidget.paths.asMap().entries.any(
          (e) => e.value != widget.paths[e.key],
        )) {
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  void _go(int index) {
    if (!_controller.hasClients || index < 0 || index >= widget.paths.length) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(index);
    } else {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: (constraints.maxWidth * (widget.immersive ? 1.05 : 0.8))
              .clamp(220.0, widget.immersive ? 420.0 : 360.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.immersive ? 0 : 16),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.paths.length,
                      allowImplicitScrolling: true,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (context, index) => ListingPhotoView(
                        key: ValueKey('gallery-$index-${widget.paths[index]}'),
                        path: widget.paths[index],
                        label:
                            '${widget.title}, photo ${index + 1} sur ${widget.paths.length}',
                      ),
                    ),
                  ),
                  if (widget.immersive)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(28),
                          child: _controls(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (!widget.immersive) _controls(context),
    ],
  );
  Widget _controls(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 8,
    children: [
      IconButton(
        tooltip: 'Photo précédente',
        onPressed: _index > 0 ? () => _go(_index - 1) : null,
        icon: const Icon(Icons.chevron_left),
      ),
      Semantics(
        liveRegion: true,
        child: Text(
          'Photo ${_index + 1} sur ${widget.paths.length}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
      IconButton(
        tooltip: 'Photo suivante',
        onPressed: _index + 1 < widget.paths.length
            ? () => _go(_index + 1)
            : null,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

class ListingPhotoEditor extends StatelessWidget {
  const ListingPhotoEditor({
    super.key,
    required this.photos,
    required this.busy,
    required this.onPick,
    required this.onRemove,
    required this.onMove,
  });
  final List<ListingPhotoDraft> photos;
  final bool busy;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  final void Function(int, int) onMove;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Photos (facultatif, 3 maximum)'),
      const Text(
        'JPEG, PNG ou WebP. Compression automatique, 4 Mo maximum par photo. La première est la photo principale.',
      ),
      for (var i = 0; i < photos.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              SizedBox(
                height: 120,
                child: Image.memory(
                  photos[i].bytes,
                  fit: BoxFit.contain,
                  semanticLabel:
                      'Photo ${i + 1}${i == 0 ? ', principale' : ''}',
                  errorBuilder: (_, error, stack) =>
                      const Icon(Icons.broken_image_outlined),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  if (i > 0)
                    TextButton.icon(
                      onPressed: busy ? null : () => onMove(i, 0),
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Choisir comme principale'),
                    ),
                  IconButton(
                    tooltip: 'Avancer la photo ${i + 1}',
                    onPressed: busy || i == 0 ? null : () => onMove(i, i - 1),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: 'Reculer la photo ${i + 1}',
                    onPressed: busy || i == photos.length - 1
                        ? null
                        : () => onMove(i, i + 1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  IconButton(
                    tooltip: 'Supprimer la photo ${i + 1}',
                    onPressed: busy ? null : () => onRemove(i),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      OutlinedButton.icon(
        onPressed: busy || photos.length >= 3 ? null : onPick,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Ajouter des photos'),
      ),
      const SizedBox(height: 16),
    ],
  );
}
