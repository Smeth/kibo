import '../../core/widgets/kibo_modal.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/congo_city_field.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_page.dart';
import 'listing_models.dart';
import 'listing_repository.dart';
import 'listing_photos.dart';
import 'listing_photo_widgets.dart';
import 'dart:async';
import 'listing_draft_store.dart';
import '../../core/diagnostics/operation_id.dart';
import '../../core/widgets/kibo_section.dart';

class PublishListingPage extends StatelessWidget {
  const PublishListingPage({
    super.key,
    required this.repository,
    this.onPublished,
    this.draftStore,
  });
  final ListingRepository repository;
  final ValueChanged<String>? onPublished;
  final ListingDraftStore? draftStore;
  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    if (auth?.identity == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Connectez-vous pour publier une annonce.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: auth == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AuthPage(controller: auth),
                        ),
                      ),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      );
    }
    return _ListingForm(
      draftStore: draftStore,
      key: ValueKey(auth!.identity!.id),
      repository: repository,
      userId: auth.identity!.id,
      initialCity: auth.profile?.city ?? 'Brazzaville',
      onPublished: onPublished,
    );
  }
}

class _ListingForm extends StatefulWidget {
  const _ListingForm({
    super.key,
    required this.repository,
    required this.userId,
    required this.initialCity,
    this.onPublished,
    this.draftStore,
  });
  final ListingRepository repository;
  final String userId, initialCity;
  final ValueChanged<String>? onPublished;
  final ListingDraftStore? draftStore;
  @override
  State<_ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends State<_ListingForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController(),
      _price = TextEditingController(),
      _neighborhood = TextEditingController();
  late final _city = TextEditingController(text: widget.initialCity);
  List<ListingCategory>? _categories;
  bool _loading = true, _busy = false, _sent = false;
  String? _category, _message;
  String _type = 'product';
  final List<ListingPhotoDraft> _photos = [];
  bool _picking = false, _recovered = false;
  String? _createdId;
  Timer? _draftTimer;
  bool _draftReady = false;
  String? _draftMessage;
  String _operationId = newOperationId();
  Future<void> _preview() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await showKiboModalSheet<void>(
      context: context,
      builder: (context) => KiboSheet(
        title: 'Aperçu avant publication',
        subtitle: 'Vérifiez les informations de votre annonce.',
        footer: FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Revenir au formulaire'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_photos.isNotEmpty)
                    Image.memory(
                      _photos.first.bytes,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  Padding(
                    padding: EdgeInsets.all(
                      MediaQuery.textScalerOf(context).scale(18) > 27 ? 12 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _title.text,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatListingPrice(
                            listingPriceValue(_price.text) ?? '',
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(_city.text)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(_description.text),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _createdId == null
                  ? '${_photos.length} photo(s). Rien n’a encore été publié depuis cet aperçu.'
                  : '${_photos.length} photo(s) à terminer pour l’annonce déjà créée.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _discardDraft() async {
    if (_busy || widget.draftStore == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => KiboDialog(
        destructive: true,
        title: const Text('Effacer le brouillon local ?'),
        content: const Text(
          'Seul le brouillon de ce compte sur cet appareil sera effacé. Une annonce déjà publiée restera dans Mes annonces.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        widget.repository.userId != widget.userId) {
      return;
    }
    _draftTimer?.cancel();
    setState(() => _busy = true);
    try {
      await widget.draftStore!.clear(widget.userId);
      if (!mounted) return;
      _draftReady = false;
      for (final field in [_title, _description, _price, _neighborhood]) {
        field.clear();
      }
      setState(() {
        _createdId = null;
        _operationId = newOperationId();
        _category = null;
        _photos.clear();
        _draftReady = true;
        _draftMessage = 'Brouillon effacé.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _form.currentState?.reset();
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _draftMessage =
              'Effacement non terminé. Réessayez pour terminer le nettoyage local.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ListingDraftSnapshot _snapshot() => ListingDraftSnapshot(
    {
      'title': _title.text,
      'description': _description.text,
      'price': _price.text,
      'city': _city.text,
      'neighborhood': _neighborhood.text,
      'category': _category ?? '',
      'type': _type,
    },
    createdId: _createdId,
    operationId: _operationId,
    photos: List.unmodifiable(_photos),
  );
  void _scheduleDraft() {
    if (!_draftReady || _sent || widget.repository.userId != widget.userId) {
      return;
    }
    _draftTimer?.cancel();
    _draftTimer = Timer(
      const Duration(milliseconds: 700),
      () => unawaited(_persistDraft()),
    );
  }

  Future<void> _persistDraft() async {
    if (!_draftReady || _sent || widget.draftStore == null) return;
    try {
      await widget.draftStore!.write(widget.userId, _snapshot());
      if (mounted) {
        setState(
          () => _draftMessage = 'Brouillon enregistré sur cet appareil.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _draftMessage =
              'Brouillon non enregistré. Gardez cet écran ouvert ou réessayez.',
        );
      }
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final saved = await widget.draftStore?.read(widget.userId);
      if (!mounted || widget.repository.userId != widget.userId) return;
      if (saved != null) {
        final f = saved.fields;
        _title.text = f['title'] ?? '';
        _description.text = f['description'] ?? '';
        _price.text = f['price'] ?? '';
        _city.text = f['city'] ?? widget.initialCity;
        _neighborhood.text = f['neighborhood'] ?? '';
        _category = f['category']?.isEmpty == false ? f['category'] : null;
        _type = f['type'] == 'service' ? 'service' : 'product';
        _createdId = saved.createdId;
        _operationId = saved.operationId ?? _operationId;
        final combined = [...saved.photos, ..._photos];
        _photos.clear();
        for (final photo in combined) {
          if (!_photos.any((p) => p.digest == photo.digest) &&
              _photos.length < maxListingPhotos) {
            _photos.add(photo);
          }
        }
        _draftMessage = _createdId == null
            ? 'Brouillon restauré avec ${_photos.length} photo(s).'
            : 'Cette annonce a déjà été créée. Terminez l’envoi des photos sans la recréer.';
      }
      _draftReady = true;
      if (_photos.isNotEmpty) _scheduleDraft();
    } catch (_) {
      _draftMessage =
          'Brouillon local illisible. Il est conservé sans être écrasé.';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_recovered) {
      _recovered = true;
      final scope = ListingPhotoScope.maybeOf(context);
      if (scope?.repository.enabled == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _selectPhotos(recover: true);
        });
      }
    }
  }

  Future<void> _selectPhotos({bool recover = false}) async {
    final scope = ListingPhotoScope.maybeOf(context);
    if (scope == null || _picking || _busy || _createdId != null) return;
    setState(() {
      _picking = true;
      _message = null;
    });
    try {
      final selected = await (recover
          ? scope.picker.recover(widget.userId)
          : scope.picker.pick(widget.userId));
      if (!mounted || widget.repository.userId != widget.userId) return;
      final combined = [..._photos];
      for (final photo in selected) {
        if (!combined.any((p) => p.digest == photo.digest)) combined.add(photo);
      }
      if (combined.length > 3) {
        throw const PhotoValidationException('Trois photos maximum.');
      }
      setState(() {
        _photos.clear();
        _photos.addAll(combined);
      });
      _scheduleDraft();
    } on PhotoValidationException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Impossible de sélectionner les photos. Réessayez.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _picking = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    for (final field in [_title, _description, _price, _city, _neighborhood]) {
      field.addListener(_scheduleDraft);
    }
    _restoreDraft().then((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await widget.repository.categories();
      if (mounted) {
        setState(() {
          _categories = result;
          if (_category != null && !result.any((c) => c.id == _category)) {
            _category = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Impossible de charger les catégories.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (_draftReady &&
        !_sent &&
        widget.draftStore != null &&
        widget.repository.userId == widget.userId) {
      unawaited(
        widget.draftStore!
            .write(widget.userId, _snapshot())
            .catchError((Object _) {}),
      );
    }
    for (final field in [_title, _description, _price, _city, _neighborhood]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.draftStore != null && !_draftReady) {
      setState(
        () => _message =
            'Le brouillon local doit être restauré ou effacé explicitement avant de publier. Vos saisies restent sur cet écran.',
      );
      return;
    }
    if (_busy || _picking || !_form.currentState!.validate()) return;
    final photoRepository = ListingPhotoScope.maybeOf(context)?.repository;
    if (_photos.isNotEmpty && photoRepository?.enabled != true) {
      setState(() {
        _message =
            'Les photos sont temporairement indisponibles. Retirez-les pour publier sans photo.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_createdId == null &&
          _photos.isNotEmpty &&
          photoRepository is PhotoPublicationPreflight) {
        await (photoRepository as PhotoPublicationPreflight)
            .checkPublicationAvailability();
        if (!mounted || widget.repository.userId != widget.userId) return;
      }
      final draft = ListingDraft(
        title: _title.text,
        description: _description.text,
        price: _price.text,
        city: _city.text,
        categoryId: _category!,
        type: _type,
        neighborhood: _neighborhood.text,
      );
      _draftTimer?.cancel();
      if (widget.draftStore != null && _draftReady) {
        await widget.draftStore!.write(widget.userId, _snapshot());
      }
      final repo = widget.repository;
      final id = _createdId ??=
          await (repo is IdempotentListingRepository
                  ? (repo as IdempotentListingRepository).createOnce(
                      draft,
                      expectedUserId: widget.userId,
                      operationId: _operationId,
                    )
                  : repo.create(draft, expectedUserId: widget.userId))
              .timeout(const Duration(seconds: 30));
      if (!mounted || repo.userId != widget.userId) return;
      // Persister l'identifiant confirmé avant les photos pour ne pas recréer l'annonce.
      _draftTimer?.cancel();
      if (widget.draftStore != null && _draftReady) {
        await widget.draftStore!.write(widget.userId, _snapshot());
      }
      if (_photos.isNotEmpty) {
        await photoRepository!.attach(
          id,
          List.unmodifiable(_photos),
          widget.userId,
        );
      }
      if (mounted && widget.repository.userId == widget.userId) {
        _draftTimer?.cancel();
        if (widget.draftStore != null && _draftReady) {
          try {
            await widget.draftStore!.clear(widget.userId);
          } catch (_) {
            _draftMessage =
                'Annonce publiée ; le brouillon local reste à effacer.';
          }
        }
        if (!mounted) return;
        setState(() {
          _sent = true;
        });
        widget.onPublished?.call(id);
      }
    } on PhotoBackendUnavailable {
      if (mounted) {
        setState(() {
          _message = _createdId == null
              ? 'Envoi des photos indisponible. Aucune annonce créée. Vos saisies sont conservées ; réessayez plus tard ou retirez les photos pour publier sans photo.'
              : 'Annonce déjà créée. Envoi des photos indisponible ; réessayez plus tard sans recréer l’annonce.';
        });
      }
    } on ListingPublicationDenied {
      if (mounted) {
        setState(() {
          _message =
              'Publication refusée. Reconnectez-vous ou contactez l’assistance.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = _createdId == null
              ? 'Publication non confirmée. Vérifiez votre connexion avant de réessayer pour éviter un doublon.'
              : 'Annonce publiée, photos incomplètes. Réessayez les photos sans recréer l’annonce.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _sent
              ? Semantics(
                  liveRegion: true,
                  child: const Text(
                    'Annonce publiée. Elle est disponible dans le catalogue.',
                  ),
                )
              : _categories == null || _categories!.isEmpty
              ? Column(
                  children: [
                    Text(_message ?? 'Aucune catégorie disponible.'),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Réessayer'),
                    ),
                  ],
                )
              : Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Publier une annonce',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        _createdId == null
                            ? 'Prix facultatif : laissez-le vide pour négocier. Votre annonce sera publiée immédiatement.'
                            : 'Annonce déjà créée. Terminez l’envoi de vos photos sans la recréer.',
                      ),
                      const SizedBox(height: 16),
                      const KiboSection(
                        title: 'Préparez votre annonce',
                        subtitle:
                            'Photos · Détails · Localisation · Aperçu et publication',
                        icon: Icons.edit_note_outlined,
                      ),
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _title,
                          _description,
                          _price,
                          _city,
                        ]),
                        builder: (context, _) {
                          final complete = [
                            validateListingTitle(_title.text) == null,
                            validateListingDescription(_description.text) ==
                                null,
                            _city.text.trim().isNotEmpty,
                            _category != null,
                          ].where((valid) => valid).length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '$complete sur 4 champs requis renseignés',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: complete / 4,
                                semanticsLabel: 'Préparation des champs requis',
                                semanticsValue: '$complete sur 4',
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                      if (widget.draftStore != null) ...[
                        if (_draftMessage != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(_draftMessage!),
                          ),
                      ],
                      _section('Vos photos'),
                      if (ListingPhotoScope.maybeOf(
                            context,
                          )?.repository.enabled ==
                          true)
                        ListingPhotoEditor(
                          photos: _photos,
                          busy: _busy || _picking || _createdId != null,
                          onPick: () => _selectPhotos(),
                          onRemove: (index) => setState(() {
                            _photos.removeAt(index);
                            _scheduleDraft();
                          }),
                          onMove: (from, to) => setState(() {
                            final photo = _photos.removeAt(from);
                            _photos.insert(to, photo);
                            _scheduleDraft();
                          }),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text('Photos temporairement indisponibles.'),
                        ),
                      if (_picking)
                        const LinearProgressIndicator(
                          semanticsLabel: 'Préparation des photos',
                        ),
                      _section('Votre annonce'),
                      _field(
                        'listing-title',
                        'Titre',
                        _title,
                        validateListingTitle,
                      ),
                      _field(
                        'listing-description',
                        'Description',
                        _description,
                        validateListingDescription,
                        multiline: true,
                      ),
                      _field(
                        'listing-price',
                        'Prix en XAF (facultatif)',
                        _price,
                        validateListingPrice,
                        numeric: true,
                      ),
                      DropdownButtonFormField<String>(
                        key: const ValueKey('listing-category'),
                        initialValue: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                        ),
                        items: [
                          for (final category in _categories!)
                            DropdownMenuItem(
                              value: category.id,
                              child: Text(
                                category.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _busy || _createdId != null
                            ? null
                            : (value) => setState(() {
                                _category = value;
                                _scheduleDraft();
                              }),
                        validator: (value) =>
                            value == null ? 'Choisissez une catégorie.' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Type'),
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
                        onChanged: _busy || _createdId != null
                            ? null
                            : (value) => setState(() {
                                _type = value!;
                                _scheduleDraft();
                              }),
                      ),
                      const SizedBox(height: 16),
                      _section('Localisation'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CongoCityField(
                          fieldKey: const ValueKey('listing-city'),
                          controller: _city,
                          enabled: !_busy && _createdId == null,
                          validator: validateListingCity,
                        ),
                      ),
                      _field(
                        'listing-neighborhood',
                        'Quartier',
                        _neighborhood,
                        (_) => null,
                      ),
                      if (widget.draftStore != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Brouillon sur cet appareil',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _createdId == null
                                      ? 'Sauvegarde locale du texte et des photos compressées, liée à ce compte. Vous pourrez reprendre votre brouillon ici.'
                                      : 'L’annonce est déjà créée. Ce brouillon conserve les photos restant à envoyer.',
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton.icon(
                                      onPressed: _busy || _picking
                                          ? null
                                          : _persistDraft,
                                      icon: const Icon(Icons.save_outlined),
                                      label: const Text(
                                        'Enregistrer le brouillon',
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _busy || _picking
                                          ? null
                                          : _discardDraft,
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text(
                                        'Effacer le brouillon local',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_message != null)
                        Semantics(liveRegion: true, child: Text(_message!)),
                      FilledButton(
                        onPressed: _busy || _picking ? null : _save,
                        child: Text(
                          _busy
                              ? 'Publication…'
                              : _createdId != null
                              ? 'Réessayer les photos'
                              : 'Publier l’annonce',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _busy || _picking ? null : _preview,
                        child: const Text('Aperçu de l’annonce'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label,
    TextEditingController controller,
    FormFieldValidator<String> validator, {
    bool multiline = false,
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      enabled: !_busy && _createdId == null,
      maxLength: key == 'listing-description'
          ? 10000
          : key == 'listing-price'
          ? null
          : 120,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 8 : 1,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : multiline
          ? TextInputType.multiline
          : TextInputType.text,
      textInputAction: multiline
          ? TextInputAction.newline
          : key == 'listing-neighborhood'
          ? TextInputAction.done
          : TextInputAction.next,
      textCapitalization: numeric
          ? TextCapitalization.none
          : TextCapitalization.sentences,
      onFieldSubmitted: key == 'listing-neighborhood'
          ? (_) => FocusScope.of(context).unfocus()
          : null,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        labelText: label,
        errorMaxLines: 4,
        helperText: key == 'listing-price'
            ? 'Laissez vide pour afficher « Prix à négocier ».'
            : key == 'listing-neighborhood'
            ? 'Facultatif'
            : null,
        hintText: key == 'listing-title'
            ? 'Ex. Canapé 3 places, bon état'
            : key == 'listing-description'
            ? 'État, caractéristiques et conditions'
            : null,
      ),
      validator: validator,
    ),
  );

  Widget _section(String title) => KiboSection(
    title: title,
    icon: title == 'Vos photos'
        ? Icons.add_photo_alternate_outlined
        : title == 'Localisation'
        ? Icons.location_on_outlined
        : Icons.article_outlined,
  );
}
