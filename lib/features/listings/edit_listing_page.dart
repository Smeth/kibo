import 'package:flutter/material.dart';
import '../../core/widgets/congo_city_field.dart';

import '../auth/auth_controller.dart';
import 'listing_models.dart';
import 'listing_repository.dart';
import 'owned_listing_repository.dart';
import 'listing_photo_widgets.dart';
import 'listing_photos.dart';
import 'manage_listing_photos_page.dart';
import '../../core/widgets/kibo_section.dart';

class EditListingPage extends StatefulWidget {
  const EditListingPage({
    super.key,
    required this.listing,
    required this.repository,
    required this.listings,
  });
  final OwnedListing listing;
  final OwnedListingRepository repository;
  final ListingRepository listings;
  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  late OwnedListing _editingListing = widget.listing;
  Future<void> _managePhotos() async {
    final scope = ListingPhotoScope.maybeOf(context);
    final repository = scope?.repository;
    if (!_current || _busy || repository is! ListingGalleryRepository) return;
    final galleryRepository = repository as ListingGalleryRepository;
    final auth = AuthScope.maybeOf(context)!;
    final result = await Navigator.push<GalleryState>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScope(
          controller: auth,
          child: ListingPhotoScope(
            repository: scope!.repository,
            picker: scope.picker,
            child: ManageListingPhotosPage(
              listing: widget.listing.id,
              owner: widget.listing.sellerId,
              repository: galleryRepository,
              picker: scope.picker,
            ),
          ),
        ),
      ),
    );
    if (_current && result != null) {
      setState(
        () => _editingListing = OwnedListing(
          id: widget.listing.id,
          sellerId: widget.listing.sellerId,
          status: widget.listing.status,
          updatedAt:
              DateTime.tryParse(result.baseUpdatedAt ?? '') ==
                  DateTime.tryParse(_editingListing.updatedAt)
              ? result.updatedAt
              : _editingListing.updatedAt,
          draft: widget.listing.draft,
          photoPaths: result.paths,
        ),
      );
    }
  }

  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.listing.draft.title);
  late final _description = TextEditingController(
    text: widget.listing.draft.description,
  );
  late final _price = TextEditingController(text: widget.listing.draft.price);
  late final _city = TextEditingController(text: widget.listing.draft.city);
  late final _neighborhood = TextEditingController(
    text: widget.listing.draft.neighborhood,
  );
  late String _category = widget.listing.draft.categoryId,
      _type = widget.listing.draft.type;
  List<ListingCategory>? _categories;
  bool _loading = true, _busy = false;
  bool _sessionInvalidated = false;
  String? _error;
  List<ListingPhotoDraft> _newPhotos = [];
  bool _picking = false, _photosSaved = false, _photoAttempted = false;
  Future<void> _pickPhotos() async {
    final scope = ListingPhotoScope.maybeOf(context);
    if (!_current || _busy || _picking || scope == null) return;
    setState(() => _picking = true);
    try {
      final photos = await scope.picker.pick(widget.listing.sellerId);
      if (_current && photos.isNotEmpty) {
        if (photos.length > maxListingPhotos) {
          throw const PhotoValidationException('Trois photos maximum.');
        }
        setState(() {
          _newPhotos = photos;
          _error = null;
        });
      }
    } catch (error) {
      if (_current) {
        setState(
          () => _error = error is PhotoValidationException
              ? error.message
              : 'Impossible de sélectionner les photos. Réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _savePhotos() async {
    final scope = ListingPhotoScope.maybeOf(context);
    if (!_current || _busy || _newPhotos.isEmpty || scope == null) return;
    setState(() {
      _busy = true;
      _photoAttempted = true;
      _error = null;
    });
    try {
      await scope.repository.attach(
        widget.listing.id,
        _newPhotos,
        widget.listing.sellerId,
      );
      if (_current) setState(() => _photosSaved = true);
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Ajout des photos non confirmé. Votre sélection est conservée ; réessayez avec ces mêmes photos ou actualisez l’annonce.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  bool get _current =>
      mounted &&
      !_sessionInvalidated &&
      widget.repository.userId == widget.listing.sellerId &&
      AuthScope.maybeOf(context)?.identity?.id == widget.listing.sellerId;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AuthScope.maybeOf(context)?.identity?.id != widget.listing.sellerId) {
      _sessionInvalidated = true;
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await widget.listings.categories();
      if (_current) setState(() => _categories = categories);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger les catégories.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _picking || !_current || !_form.currentState!.validate()) {
      return;
    }
    if (_newPhotos.isNotEmpty && !_photosSaved) {
      setState(
        () => _error =
            'Enregistrez les photos sélectionnées avant les autres modifications.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.edit(
        _editingListing,
        ListingDraft(
          title: _title.text,
          description: _description.text,
          price: _price.text,
          categoryId: _category,
          city: _city.text,
          neighborhood: _neighborhood.text,
          type: _type,
        ),
      );
      if (mounted && _current) Navigator.pop(context, true);
    } catch (error) {
      if (_current) setState(() => _error = listingManagementError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _price,
      _city,
      _neighborhood,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String key,
    String label,
    TextEditingController controller,
    FormFieldValidator<String> validate, {
    bool multiline = false,
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      enabled: !_busy,
      decoration: InputDecoration(
        labelText: label,
        helperText: key == 'edit-listing-price'
            ? 'Laissez vide pour afficher « Prix à négocier ».'
            : null,
      ),
      validator: validate,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 8 : 1,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : multiline
          ? TextInputType.multiline
          : TextInputType.text,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final current = _current;
    return PopScope(
      canPop: !_busy && !_picking,
      child: Scaffold(
        appBar: AppBar(title: const Text('Modifier mon annonce')),
        body: !current
            ? const Center(
                child: Text(
                  'Votre session a changé. Fermez ce formulaire et reconnectez-vous.',
                ),
              )
            : _loading
            ? const Center(child: CircularProgressIndicator())
            : _categories == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? 'Catégories indisponibles.'),
                    TextButton(
                      onPressed: _loadCategories,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const KiboSection(
                            title: 'Photos de l’annonce',
                            icon: Icons.photo_library_outlined,
                          ),
                          if (_editingListing.photoPaths.isNotEmpty)
                            ListingPhotoGallery(
                              paths: _editingListing.photoPaths,
                              title: widget.listing.draft.title,
                            )
                          else if (_newPhotos.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (var i = 0; i < _newPhotos.length; i++)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      _newPhotos[i].bytes,
                                      width: 96,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      semanticLabel: 'Photo ${i + 1}',
                                    ),
                                  ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Aucune photo pour le moment',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          if (ListingPhotoScope.maybeOf(context)?.repository
                              case final ListingGalleryRepository gallery
                              when gallery.galleryEnabled) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _managePhotos,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Gérer les photos'),
                            ),
                          ] else if (widget.listing.photoPaths.isEmpty &&
                              ListingPhotoScope.maybeOf(
                                    context,
                                  )?.repository.enabled ==
                                  true) ...[
                            const SizedBox(height: 8),
                            if (_photosSaved)
                              const Text(
                                'Photos ajoutées. Elles seront visibles au retour à vos annonces.',
                              )
                            else ...[
                              OutlinedButton.icon(
                                onPressed:
                                    _busy || _picking || _newPhotos.isNotEmpty
                                    ? null
                                    : _pickPhotos,
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                ),
                                label: Text(
                                  _picking
                                      ? 'Sélection…'
                                      : 'Ajouter jusqu’à 3 photos',
                                ),
                              ),
                              if (_newPhotos.isNotEmpty)
                                FilledButton.tonalIcon(
                                  onPressed: _busy ? null : _savePhotos,
                                  icon: const Icon(Icons.cloud_upload_outlined),
                                  label: const Text('Enregistrer les photos'),
                                ),
                              if (_newPhotos.isNotEmpty && !_photoAttempted)
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(() => _newPhotos = []),
                                  child: const Text('Annuler la sélection'),
                                ),
                            ],
                          ],
                          const SizedBox(height: 24),
                          const KiboSection(
                            title: 'Les détails de votre annonce',
                            icon: Icons.edit_outlined,
                          ),
                          const Text(
                            'Le statut et la date de publication restent inchangés. Les photos déjà enregistrées sont conservées.',
                          ),
                          const SizedBox(height: 16),
                          _field(
                            'edit-listing-title',
                            'Titre',
                            _title,
                            validateListingTitle,
                          ),
                          _field(
                            'edit-listing-description',
                            'Description',
                            _description,
                            validateListingDescription,
                            multiline: true,
                          ),
                          _field(
                            'edit-listing-price',
                            'Prix en XAF (facultatif)',
                            _price,
                            validateListingPrice,
                            numeric: true,
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie',
                            ),
                            items: [
                              if (!_categories!.any((c) => c.id == _category))
                                DropdownMenuItem(
                                  value: _category,
                                  child: const Text(
                                    'Catégorie actuelle (inactive)',
                                  ),
                                ),
                              for (final c in _categories!)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _busy
                                ? null
                                : (value) => setState(() => _category = value!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _type,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'product',
                                child: Text('Produit'),
                              ),
                              DropdownMenuItem(
                                value: 'service',
                                child: Text('Service'),
                              ),
                            ],
                            onChanged: _busy
                                ? null
                                : (value) => setState(() => _type = value!),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: CongoCityField(
                              fieldKey: const ValueKey('edit-listing-city'),
                              controller: _city,
                              enabled: !_busy,
                              validator: validateListingCity,
                            ),
                          ),
                          _field(
                            'edit-listing-neighborhood',
                            'Quartier',
                            _neighborhood,
                            (_) => null,
                          ),
                          if (_error != null)
                            Semantics(liveRegion: true, child: Text(_error!)),
                          FilledButton(
                            onPressed: _busy ? null : _save,
                            child: Text(
                              _busy
                                  ? 'Enregistrement…'
                                  : 'Enregistrer les modifications',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
