import 'dart:io';

import 'package:test/test.dart' as test;
import 'package:test_process/test_process.dart';

void main() {
  test.test('Runs program correctly', () async {
    var process = await TestProcess.start(
        'dart', ['./lib/birb.dart', './test/TestPrograms/test_runtime.birb']);

    var line = await process.stdout.next;
    test.expect(line, test.equals('Henlo am Birb'));

    line = await process.stdout.next;
    test.expect(line, test.equals('I am 10 years old'));

    line = await process.stdout.next;
    test.expect(line, test.equals('I like Seeb'));

    line = await process.stdout.next;
    test.expect(line, test.equals('There is only 1 item in my good list'));
  });

  test.group('All programs run without errors', () {
    Directory directory = Directory('./examples/');
    directory.listSync().forEach((file) {
      test.test('${file.path}', () async {
        var process =
            await TestProcess.start('dart', ['./lib/birb.dart', file.path]);

        while (await process.stderr.hasNext) {
          var line = await process.stderr.next;
          test.expect(
              line.toLowerCase(), test.isNot(test.contains('exception')));
          test.expect(
              line.toLowerCase(), test.isNot(test.contains('error')));
        }
        while (await process.stdout.hasNext) {
          var line = await process.stdout.next;
          test.expect(
              line.toLowerCase(), test.isNot(test.contains('exception')));
          test.expect(
              line.toLowerCase(), test.isNot(test.contains('error')));
        }
        await process.shouldExit();
      });
    });
  });
}
