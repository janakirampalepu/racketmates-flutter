import 'dart:convert';
import 'dart:io';

/// Loads a recorded API response from `test/fixtures/api/`.
Map<String, dynamic> apiFixture(String name) =>
    jsonDecode(File('test/fixtures/api/$name.json').readAsStringSync())
        as Map<String, dynamic>;
