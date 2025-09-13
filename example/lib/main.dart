import 'package:flutter/material.dart';
import 'package:fluxon/fluxon.dart';
import 'services/image_filter_service.dart';
import 'services/local_image_filter_service.dart';
import 'services/image_filter_coordinator.dart';
import 'screens/image_filters_screen.dart';

// part 'main.g.dart'; // Generated code - not needed for main files

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Create FluxRuntime and register all services
  final runtime = FluxonRuntime();

  // ImageFilterService runs in worker isolate
  runtime.register<ImageFilterService>(() => ImageFilterServiceImpl());
  // Local service for comparison (non-remote)
  runtime.register<LocalImageFilterService>(() => LocalImageFilterService());
  // Coordinator for event-driven requests
  runtime.register<ImageFilterCoordinator>(() => ImageFilterCoordinatorImpl());

  // 🚀 Initialize all services (dependencies resolved automatically)
  await runtime.initializeAll();

  runApp(ImageStudioApp(runtime: runtime));
}

class ImageStudioApp extends StatelessWidget {
  const ImageStudioApp({super.key, required this.runtime});

  final FluxonRuntime runtime;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flux Image Studio — Powered by Flux',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
      ),
      home: ImageFiltersScreen(runtime: runtime),
      debugShowCheckedModeBanner: false,
    );
  }
}
