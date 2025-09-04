import 'package:flutter/material.dart';
import 'package:dart_service_framework/dart_service_framework.dart';
import 'events/task_events.dart';
import 'services/simple_task_service.dart';
import 'services/simple_user_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'screens/home_screen_simple.dart';

// part 'main_simple.g.dart'; // Generated code - not needed for main files

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

  // 🚀 Create FluxRuntime and register services
  final runtime = FluxRuntime();

  // 🔗 DEPENDENCY SYSTEM: Local services (no complex dependencies)
  runtime.register<SimpleUserService>(() => SimpleUserService());
  runtime.register<SimpleTaskService>(() => SimpleTaskService());

  // 🔄 SERVICE PROXY SYSTEM: Remote services (worker isolates)
  runtime.register<NotificationService>(() => NotificationServiceWorker());
  runtime.register<AnalyticsService>(() => AnalyticsServiceWorker());

  // 🚀 Initialize all services (automatic dependency resolution)
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
      home: HomeScreenSimple(runtime: runtime),
      debugShowCheckedModeBanner: false,
    );
  }
}
