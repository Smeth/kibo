// Entry point réservé aux mesures locales. Aucun client Supabase ni stockage.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/core/widgets/kibo_bottom_navigation.dart';
import 'package:kibo/features/listings/listing_detail_page.dart';
import 'package:kibo/features/listings/listing_feed.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:kibo/features/listings/listing_photo_widgets.dart';
import 'package:kibo/features/listings/listing_query.dart';
import '../test/support/listing_fake.dart';

class _Listings extends FakeListingRepository {
  _Listings() {
    listings = List.generate(
      200,
      (i) => PublicListing(
        id: 'fixture-$i',
        title: 'Annonce locale $i',
        description: 'Description fictive pour la mesure locale. ' * 12,
        price: '95000',
        city: 'Brazzaville',
        categoryName: 'Téléphones et informatique',
        photoPaths: ['photo-$i'],
      ),
    );
  }
  @override
  Future<List<PublicListing>> published({
    int offset = 0,
    ListingQuery query = const ListingQuery(),
  }) async => listings;
}

class _Photos implements ListingPhotoRepository, ListingPhotoPicker {
  _Photos(this.port);
  final int port;
  @override
  bool get enabled => true;
  @override
  Future<String> signedUrl(String path) async => 'http://127.0.0.1:$port/$path';
  @override
  Future<void> attach(
    String listingId,
    List<ListingPhotoDraft> photos,
    String owner,
  ) async => throw StateError('Lecture seule');
  @override
  Future<List<ListingPhotoDraft>> pick(String owner) async => [];
  @override
  Future<List<ListingPhotoDraft>> recover(String owner) async => [];
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pixels = image.Image(width: 1600, height: 1200);
  image.fill(pixels, color: image.ColorRgb8(8, 127, 91));
  final bytes = image.encodeJpg(pixels);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) {
    request.response.headers.contentType = ContentType('image', 'jpeg');
    request.response.add(bytes);
    unawaited(request.response.close());
  });
  runApp(_Benchmark(photos: _Photos(server.port)));
}

class _Benchmark extends StatefulWidget {
  const _Benchmark({required this.photos});
  final _Photos photos;
  @override
  State<_Benchmark> createState() => _BenchmarkState();
}

class _BenchmarkState extends State<_Benchmark> {
  final repository = _Listings();
  final scroll = ScrollController();
  final navigator = GlobalKey<NavigatorState>();
  final timings = <ui.FrameTiming>[];
  int tab = 0;
  bool recording = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addTimingsCallback(_record);
    unawaited(_run());
  }

  void _record(List<ui.FrameTiming> frames) {
    if (recording) timings.addAll(frames);
  }

  Future<void> _pause() =>
      Future<void>.delayed(const Duration(milliseconds: 700));
  Future<void> _run() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    for (var run = 1; run <= 3; run++) {
      PaintingBinding.instance.imageCache.clear();
      timings.clear();
      recording = true;
      for (var cycle = 0; cycle < 3; cycle++) {
        await scroll.animateTo(
          2400,
          duration: const Duration(seconds: 2),
          curve: Curves.linear,
        );
        await scroll.animateTo(
          0,
          duration: const Duration(seconds: 2),
          curve: Curves.linear,
        );
        final route = navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => ListingPhotoScope(
              repository: widget.photos,
              picker: widget.photos,
              child: ListingDetailPage(id: 'fixture-0', repository: repository),
            ),
          ),
        );
        await _pause();
        navigator.currentState!.pop();
        await route;
        await _pause();
        setState(() => tab = 1);
        await _pause();
        setState(() => tab = 0);
        await _pause();
      }
      await _pause();
      recording = false;
      double percentile(List<double> values, double p) {
        values.sort();
        return values[(values.length * p).floor().clamp(0, values.length - 1)];
      }

      final build = timings
          .map((f) => f.buildDuration.inMicroseconds / 1000)
          .toList();
      final raster = timings
          .map((f) => f.rasterDuration.inMicroseconds / 1000)
          .toList();
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final budget = 1000 / view.display.refreshRate;
      debugPrint(
        'KIBO_M3_BENCH ${jsonEncode({'version': const String.fromEnvironment('KIBO_BENCH_VERSION', defaultValue: 'before'), 'run': run, 'frames': timings.length, 'hz': view.display.refreshRate, 'buildP95Ms': percentile(build, .95), 'rasterP95Ms': percentile(raster, .95), 'overBudget': timings.where((f) => f.buildDuration.inMicroseconds / 1000 > budget || f.rasterDuration.inMicroseconds / 1000 > budget).length, 'imageCacheBytes': PaintingBinding.instance.imageCache.currentSizeBytes})}',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeTimingsCallback(_record);
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    navigatorKey: navigator,
    theme: KiboTheme.light,
    home: Scaffold(
      appBar: AppBar(title: const Text('Mesure locale · données fictives')),
      body: ListingPhotoScope(
        repository: widget.photos,
        picker: widget.photos,
        child: PrimaryScrollController(
          controller: scroll,
          child: ListingFeed(
            key: ValueKey(tab),
            repository: repository,
            searchEnabled: tab == 1,
          ),
        ),
      ),
      bottomNavigationBar: KiboBottomNavigation(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Recherche'),
        ],
      ),
    ),
  );
}
