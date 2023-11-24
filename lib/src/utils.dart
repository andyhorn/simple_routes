/// Join segments into a forward slash-separated path.
String join(List<String> segments) {
  return segments.join('/').replaceAll('//', '/');
}
