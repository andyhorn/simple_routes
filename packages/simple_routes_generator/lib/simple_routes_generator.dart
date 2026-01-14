import 'package:build/build.dart';
import 'package:simple_routes_generator/src/simple_route_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder simpleRouteBuilder(BuilderOptions options) => SharedPartBuilder(
      [SimpleRouteGenerator()],
      'simple_routes',
    );
