import 'package:test/test.dart' as test;
import 'package:test_process/test_process.dart';

void main() {
  test.test('Runs program correctly', () async {
    var process = await TestProcess.start(
        'dart', ['lib/Birb.dart', 'test/TestPrograms/test_runtime.birb']);

    var line = await process.stdout.next;
    test.expect(line, test.equals('Henlo am Birb'));

    line = await process.stdout.next;
    test.expect(line, test.equals('I am 10 years old'));

    line = await process.stdout.next;
    test.expect(line, test.equals('I like Seeb'));

    line = await process.stdout.next;
    test.expect(line, test.equals('There is only 1 item in my good list'));
  });
}
