import 'package:test/test.dart' as test;
import 'package:test_process/test_process.dart';

void main() {
  test.test('No analysis issues', () async {
    final process = await TestProcess.start('dartanalyzer', ['.'], runInShell: true);

    test.expect(await process.stdout.next, 'Analyzing BirbLang...');
    test.expect(await process.stdout.next, 'No issues found!');
  });
}