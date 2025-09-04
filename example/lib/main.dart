import 'package:flutter/material.dart';
import 'package:dart_service_framework/dart_service_framework.dart';
import 'events/task_events.dart';
import 'services/storage_service.dart';
import 'services/task_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'services/background_processor.dart';
import 'screens/home_screen.dart';

// part 'main.g.dart'; // Generated code - not needed for main files

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📡 Register event types for cross-isolate communication
  EventTypeRegistry.register<TaskCreatedEvent>(
    (json) => TaskCreatedEvent.fromJson(json),
  );
  EventTypeRegistry.register<TaskStatusChangedEvent>(
    (json) => TaskStatusChangedEvent.fromJson(json),
  );
  EventTypeRegistry.register<NotificationEvent>(
    (json) => NotificationEvent.fromJson(json),
  );
  EventTypeRegistry.register<AnalyticsEvent>(
    (json) => AnalyticsEvent.fromJson(json),
  );

  // 🚀 Create FluxRuntime and register all services
  final runtime = FluxRuntime();

  // 🔗 DEPENDENCY SYSTEM: Services automatically resolve dependencies
  // StorageService (no dependencies, use Impl for automatic registration)
  runtime.register<StorageService>(() => StorageServiceImpl());

  // UserService depends on StorageService (use Impl for automatic registration)
  runtime.register<UserService>(() => UserServiceImpl());

  // TaskService depends on StorageService (use Impl for automatic registration)
  runtime.register<TaskService>(() => TaskServiceImpl());

  // 🔄 SERVICE PROXY SYSTEM: Remote services auto-detected by Worker suffix
  // NotificationService runs in worker isolate (optional dependency on UserService)
  runtime.register<NotificationService>(() => NotificationServiceImpl());

  // AnalyticsService runs in worker isolate (no dependencies)
  runtime.register<AnalyticsService>(() => AnalyticsServiceImpl());

  // BackgroundProcessor runs in worker isolate (optional dependency on TaskService)
  runtime.register<BackgroundProcessor>(() => BackgroundProcessorImpl());

  // 🚀 Initialize all services (dependencies resolved automatically)
  await runtime.initializeAll();

  runApp(FluxTasksApp(runtime: runtime));
}

class FluxTasksApp extends StatelessWidget {
  const FluxTasksApp({super.key, required this.runtime});

  final FluxRuntime runtime;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FluxTasks - Powered by Flux Framework',
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
      home: HomeScreen(runtime: runtime),
      debugShowCheckedModeBanner: false,
    );
  }
}
