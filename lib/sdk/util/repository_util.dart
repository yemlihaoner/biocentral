Set<String> getKeysWhereDataIsAvailableForAllEntries(List<MapEntry<String, String>> entries, int repositoryLength) {
  Set<String> result = {};
  // category name -> number of occurrences
  Map<String, int> uniqueMap = {};
  for (MapEntry<String, String> keyValue in entries) {
    uniqueMap.putIfAbsent(keyValue.key, () => 0);

    if (keyValue.value != "") {
      int count = uniqueMap[keyValue.key]! + 1;
      uniqueMap[keyValue.key] = count;
    }
  }

  for (MapEntry<String, int> categoryOccurrences in uniqueMap.entries) {
    if (categoryOccurrences.value == repositoryLength) {
      result.add(categoryOccurrences.key);
    }
  }
  return result;
}