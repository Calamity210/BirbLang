import 'package:test/test.dart' as test;
import 'package:test_process/test_process.dart';

void main() {
  test.test(
    'Starts and exits interactive mode successfully',
    () async {

      final process = await TestProcess.start('dart', ['./lib/birb.dart']);

      process.stdin.writeln('quit()');

      await for (final output in process.stdoutStream()) {
        test.expect(
          output.toLowerCase(),
          test.isNot(test.contains('exception')),
        );
      }

      await for (final output in process.stderrStream()) {
        test.expect(
          output.toLowerCase(),
          test.isNot(test.contains('exception')),
        );
      }

      test.expect(await process.exitCode, test.equals(0),
          reason: 'non-zero exit code');
    },
    timeout: const test.Timeout(Duration(seconds: 5)),
  );
}
