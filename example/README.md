# FluxTasks - Real-World Flux Framework Demo

A comprehensive Flutter application demonstrating all three core Flux framework systems working together in a real-world scenario.

## 🎯 What This Demo Shows

### **Complete Flux Architecture in Action**
- **🔗 Dependency System** - Services declare dependencies and initialize in correct order
- **🔄 Service Proxy System** - Transparent local/remote service calls
- **📡 Event System** - Real-time cross-isolate event communication

## 🚀 Running the Demo

```bash
cd example
flutter pub get
dart run build_runner build
flutter run -d chrome  # Or any Flutter target
```

## 🏗️ Architecture Overview

```
Main Isolate (UI)              Worker Isolate 1           Worker Isolate 2
┌─────────────────┐           ┌─────────────────┐        ┌─────────────────┐
│ TaskService      │◄─events─►│NotificationService│      │ AnalyticsService│
│ UserService      │          │                 │◄─────►│                 │
│ StorageService   │          │                 │ events │                 │
│ (UI Components)  │          │                 │        │                 │
└─────────────────┘          └─────────────────┘        └─────────────────┘
         ▲                            ▲                           ▲
         │                            │                           │
    FluxRuntime ◄──────────────────────┼───────────────────────────┘
    (Automatic orchestration)
```

## 🔍 Key Features Demonstrated

### **1. Zero-Boilerplate Service Creation**
```dart
// 🚀 Service registration
runtime.register<StorageService>(() => StorageServiceImpl());
runtime.register<UserService>(() => UserServiceImpl());
runtime.register<TaskService>(() => TaskServiceImpl());
runtime.register<NotificationService>(() => NotificationServiceImpl()); // remote
runtime.register<AnalyticsService>(() => AnalyticsServiceImpl());       // remote

await runtime.initializeAll(); // Dependencies resolved automatically
```

### **2. Transparent Service Calls**
```dart
// 🔄 Same API for local and remote services
final taskService = runtime.get<TaskService>();                 // Local
final notificationService = runtime.get<NotificationService>(); // Remote (worker isolate)

// Both calls look identical - complete transparency!
await taskService.createTask(...);           // Runs locally
await notificationService.sendNotification(...); // Runs in worker isolate
```

### **3. Automatic Event Flow**
```dart
// 📡 Events automatically flow across isolates
await sendEvent(TaskCreatedEvent(...)); 

// NotificationService (worker isolate) receives event automatically
// AnalyticsService (worker isolate) receives event automatically
// No manual routing or serialization needed!
```

## 🎮 Interactive Demo Features

### **Task Management**
- ✅ Create tasks with different priorities and assignments
- ✅ Update task status (triggers cross-isolate events)
- ✅ View task statistics calculated in real-time
- ✅ Delete tasks and see immediate updates

### **Real-Time Events**
- ✅ **TaskCreatedEvent** → Automatic notifications sent via worker isolate
- ✅ **TaskStatusChangedEvent** → Analytics tracking in separate isolate
- ✅ **NotificationEvent** → Cross-service communication
- ✅ **AnalyticsEvent** → Background processing and insights

### **Cross-Isolate Processing**
- ✅ **NotificationService** runs in worker isolate (non-blocking)
- ✅ **AnalyticsService** runs in worker isolate (heavy computation)
- ✅ **UI remains responsive** during background processing
- ✅ **Automatic infrastructure** - no manual isolate management

## 🔧 Framework Features Showcased

### **Dependency System** 🔗
- **Automatic Resolution**: Services declare dependencies, framework resolves order
- **Optional Dependencies**: Services gracefully handle missing optional dependencies
- **Initialization Order**: Complex dependency graphs resolved automatically

### **Service Proxy System** 🔄
- **Local Services**: Fast, direct method calls within main isolate
- **Remote Services**: Transparent calls to worker isolates via Squadron
- **Type Safety**: Full type safety maintained across isolate boundaries
- **Error Propagation**: Exceptions properly propagated from workers to main

### **Event System** 📡
- **Cross-Isolate Events**: Events automatically route between isolates
- **Serialization**: Automatic JSON serialization/deserialization
- **Event Types**: Strongly-typed events with proper reconstruction
- **Broadcasting**: Events delivered to all interested services automatically

## 🎯 Try These Interactions

1. **Create a Task** (Tap +)
   - Watch console logs show events flowing to worker isolates
   - NotificationService processes TaskCreatedEvent in background
   - AnalyticsService tracks the creation automatically

2. **Update Task Status** (Tap task → Start/Complete)
   - TaskStatusChangedEvent sent to all services
   - Background analytics processing doesn't block UI
   - Real-time updates across the application

3. **Framework Info** (Tap info icon)
   - See detailed explanation of what's happening under the hood
   - Understand how the three systems work together

## 💡 Key Insights

### **What Makes This Special**
- **Zero Configuration** - No manual event dispatcher setup
- **Complete Transparency** - Local and remote services identical
- **Automatic Infrastructure** - Worker isolates get full event capabilities
- **Type Safety** - Strong typing maintained across isolate boundaries
- **Real-World Ready** - Production-ready patterns and error handling

### **Perfect for Production**
- **Non-Blocking UI** - Heavy operations run in worker isolates
- **Scalable Architecture** - Easy to add new services and events
- **Maintainable Code** - Clean separation of concerns
- **Robust Error Handling** - Graceful failure and recovery

## 🚀 Next Steps

This demo shows Flux at its core. In a real application, you could extend this with:
- Database integration (local/remote services)
- Real-time collaboration (event system)
- Background sync (worker isolates)
- Push notifications (cross-isolate events)
- Analytics and monitoring (transparent service calls)

**Flux makes complex distributed systems feel like simple local code!** 🎉