# fluxon_method_generator

Code generator for Fluxon service contracts. Generates client proxies and worker dispatchers for services extending `FluxonService`.

## Usage

Add dependencies in your pubspec:

```yaml
dependencies:
  fluxon: ^0.0.4

dev_dependencies:
  build_runner: ^2.4.0
  fluxon_method_generator: ^0.0.4
```

Annotate your service and include generated part:

```dart
import 'package:fluxon/fluxon.dart';

part 'my_service.g.dart';

@ServiceContract(remote: true)
class MyService extends FluxonService {
  Future<String> greet(String name) async => 'hi $name';
}
```

Run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This will generate `my_service.g.dart` with a client proxy and a worker dispatcher.
