# Dart Service Framework

A comprehensive service locator and services framework for Dart applications using Squadron worker isolates.

## Overview

This framework provides a robust, type-safe service architecture that allows you to:
- Register multiple services with a single registration API
- Initialize all services with automatic dependency resolution
- Run services in Squadron worker isolates for true parallelism
- Communicate between services transparently without manual message passing
- Manage service lifecycles with proper initialization and teardown order
- Provide structured logging with service-specific prefixes and metadata

## Architecture Specification

### Core Components

#### 1. Service Locator (`ServiceLocator`)
- **Purpose**: Central registry for all services
- **Responsibilities**:
  - Service registration with dependency declarations
  - Dependency graph construction and validation
  - Initialization order calculation using topological sort
  - Service lifecycle management
  - Service instance retrieval

#### 2. Base Service Class (`BaseService`)
- **Purpose**: Abstract base class for all services
- **Responsibilities**:
  - Common service APIs (initialize, destroy)
  - Dependency declaration interface
  - Integrated logging with service-specific prefixes
  - Metadata management for logging context
  - Service state management

#### 3. Service Proxy System (`ServiceProxy`)
- **Purpose**: Transparent communication between services
- **Responsibilities**:
  - Method call interception and routing
  - Squadron worker message serialization/deserialization
  - Type-safe method invocation across isolates
  - Error handling and propagation

#### 4. Dependency Resolver (`DependencyResolver`)
- **Purpose**: Manages service dependencies and initialization order
- **Responsibilities**:
  - Dependency graph validation (cycle detection)
  - Topological sorting for initialization order
  - Reverse order calculation for teardown
  - Dependency injection coordination

#### 5. Logging System (`ServiceLogger`)
- **Purpose**: Structured logging for services
- **Responsibilities**:
  - Service-specific log prefixes
  - Metadata attachment to log entries
  - Log level management
  - Integration with service lifecycle

#### 6. Squadron Integration (`ServiceWorker`)
- **Purpose**: Squadron worker wrapper for services
- **Responsibilities**:
  - Service instantiation in isolate
  - Message handling and method dispatch
  - Error handling and reporting
  - Resource cleanup on isolate termination

### Key Features

#### Type Safety
- Generic service registration: `ServiceLocator.register<T extends BaseService>()`
- Type-safe service retrieval: `ServiceLocator.get<T>()`
- Compile-time dependency validation where possible
- Strong typing for service method calls across isolates

#### Dependency Management
- Declarative dependency specification in service classes
- Automatic dependency resolution and initialization ordering
- Circular dependency detection with clear error messages
- Optional vs required dependency support

#### Service Lifecycle
- **Registration Phase**: Services declare dependencies and register with locator
- **Initialization Phase**: Services initialized in dependency order
- **Runtime Phase**: Services communicate via proxy system
- **Teardown Phase**: Services destroyed in reverse dependency order

#### Transparent Communication
- Services call other services' methods directly: `await otherService.someMethod()`
- Framework handles Squadron message passing internally
- Automatic serialization/deserialization of method parameters and return values
- Error propagation across isolate boundaries

#### Logging Integration
- Each service gets a logger with automatic prefix: `[ServiceName] Log message`
- Metadata support: `logger.setMetadata({'userId': '123'})`
- Structured logging with timestamps and service context
- Configurable log levels per service

## Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] **Project Setup**
  - [ ] Create Dart package structure
  - [ ] Configure pubspec.yaml with Squadron dependency
  - [ ] Set up test infrastructure
  - [ ] Configure analysis options

- [ ] **Base Service Implementation**
  - [ ] Create `BaseService` abstract class
  - [ ] Implement service state management
  - [ ] Add dependency declaration interface
  - [ ] Integrate logging system
  - [ ] Add lifecycle methods (initialize, destroy)

- [ ] **Service Locator Core**
  - [ ] Implement service registration system
  - [ ] Create type-safe service retrieval
  - [ ] Add basic lifecycle management
  - [ ] Implement service instance caching

### Phase 2: Dependency Management
- [ ] **Dependency Resolver**
  - [ ] Create dependency graph data structure
  - [ ] Implement topological sorting algorithm
  - [ ] Add circular dependency detection
  - [ ] Create initialization order calculator
  - [ ] Add teardown order calculation

- [ ] **Integration with Service Locator**
  - [ ] Connect dependency resolver to registration
  - [ ] Implement dependency-aware initialization
  - [ ] Add dependency validation during registration
  - [ ] Create dependency injection system

### Phase 3: Squadron Integration
- [ ] **Service Worker Implementation**
  - [ ] Create Squadron worker wrapper
  - [ ] Implement service instantiation in isolate
  - [ ] Add message handling for method calls
  - [ ] Implement error handling and reporting

- [ ] **Service Proxy System**
  - [ ] Create dynamic proxy generation
  - [ ] Implement method call interception
  - [ ] Add parameter serialization/deserialization
  - [ ] Implement return value handling
  - [ ] Add error propagation across isolates

### Phase 4: Logging System
- [ ] **Service Logger Implementation**
  - [ ] Create logger with service prefixes
  - [ ] Implement metadata management
  - [ ] Add structured logging format
  - [ ] Integrate with service lifecycle

- [ ] **Logging Integration**
  - [ ] Connect logger to base service
  - [ ] Add automatic service name prefixing
  - [ ] Implement metadata inheritance
  - [ ] Add log level configuration

### Phase 5: Advanced Features
- [ ] **Service Configuration**
  - [ ] Add configuration injection system
  - [ ] Implement environment-specific configs
  - [ ] Add configuration validation

- [ ] **Health Monitoring**
  - [ ] Add service health check interface
  - [ ] Implement health status aggregation
  - [ ] Add monitoring hooks

- [ ] **Error Handling**
  - [ ] Implement comprehensive error types
  - [ ] Add error recovery mechanisms
  - [ ] Create error reporting system

### Phase 6: Testing & Documentation
- [ ] **Unit Tests**
  - [ ] Test service registration and retrieval
  - [ ] Test dependency resolution
  - [ ] Test service lifecycle management
  - [ ] Test logging functionality

- [ ] **Integration Tests**
  - [ ] Test multi-service scenarios
  - [ ] Test Squadron worker integration
  - [ ] Test service communication
  - [ ] Test error handling across isolates

- [ ] **Performance Tests**
  - [ ] Benchmark service initialization
  - [ ] Test concurrent service calls
  - [ ] Measure memory usage
  - [ ] Profile isolate communication

- [ ] **Documentation**
  - [ ] API documentation
  - [ ] Usage examples
  - [ ] Best practices guide
  - [ ] Migration guide

## Usage Example

```dart
// Define a service
class DatabaseService extends BaseService {
  @override
  List<Type> get dependencies => [];
  
  @override
  Future<void> initialize() async {
    logger.info('Initializing database connection');
    // Initialize database
  }
  
  Future<User> getUser(String id) async {
    logger.debug('Fetching user', metadata: {'userId': id});
    // Database logic
  }
}

// Define a dependent service
class UserService extends BaseService {
  @override
  List<Type> get dependencies => [DatabaseService];
  
  late final DatabaseService _db;
  
  @override
  Future<void> initialize() async {
    _db = ServiceLocator.get<DatabaseService>();
    logger.info('User service initialized');
  }
  
  Future<UserProfile> getUserProfile(String id) async {
    final user = await _db.getUser(id); // Transparent cross-isolate call
    // Process user data
  }
}

// Register and initialize services
void main() async {
  final locator = ServiceLocator();
  
  // Register services
  locator.register<DatabaseService>(() => DatabaseService());
  locator.register<UserService>(() => UserService());
  
  // Initialize all services (automatic dependency order)
  await locator.initializeAll();
  
  // Use services
  final userService = locator.get<UserService>();
  final profile = await userService.getUserProfile('123');
  
  // Cleanup
  await locator.destroyAll();
}
```

## Technical Requirements

### Dependencies
- **Squadron**: For worker isolate management
- **Test**: For unit and integration testing
- **Mockito** (dev): For mocking in tests

### Dart Version
- Minimum Dart SDK: 3.0.0
- Null safety: Required
- Modern Dart features: Utilized throughout

### Performance Goals
- Service initialization: < 100ms per service
- Cross-isolate method calls: < 10ms latency
- Memory overhead: < 1MB per service isolate
- Concurrent service limit: 100+ services

### Type Safety Goals
- Zero runtime type errors in service communication
- Compile-time dependency validation where possible
- Strong typing for all public APIs
- Generic constraints for service registration

This specification provides a comprehensive roadmap for building a robust, type-safe service framework that leverages Dart's modern features and Squadron's isolate capabilities.