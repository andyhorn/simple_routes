import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/simple_route_generator.dart';

Builder simpleRouteBuilder(BuilderOptions options) => SharedPartBuilder(
      [SimpleRouteGenerator()],
      'simple_routes',
    );
