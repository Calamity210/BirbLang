import 'dart:io';
import 'package:http/http.dart';

Future<void> install(String package) async {
  Response content;

  try {
    content = await get(package);
  } catch (err) {
    print(err);
    exit(0);
  }

  print('Installing Packages ...');

  await Directory('.birb').create(recursive: true);
  await File('.birb/' + package.split('/').last).writeAsString(content.body);

  print('Done!');
}
