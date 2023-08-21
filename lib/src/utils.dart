String join(List<String> segments) {
  return segments.join('/').replaceAll('//', '/');
}

String withPrefix(Enum value) => ':${value.name}';

extension StringExtensions on String {
  String setParam<Param extends Enum>(Param param, String value) {
    return replaceAll(withPrefix(param), value);
  }
}
