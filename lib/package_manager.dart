import 'dart:io';
import 'package:http/http.dart';

void install(String package) async {
  Response content;

  try {
    content = await get(package);
  } catch (err) {
    print(err);
    exit(0);
  }

  print(content.body);
}
