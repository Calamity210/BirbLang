import 'dart:io';

import 'package:test/test.dart' as test;
import 'package:test_process/test_process.dart';

class ExpectationsParser {
  ExpectationsParser(this.file) {
    _parseExpectations();
  }

  final File file;

  final _outputs = <String>[];
  int _matchedOutputs = 0;

  final _errors = <String>[];
  int _matchedErrors = 0;

  void _parseExpectations() {
    final content = file.readAsStringSync();
    final lines = content.split(RegExp(r'\n|(\r\n)'));
    // repeat variables
    bool isRepeat = false;
    List<String> repeatOutputs = [];
    int count = 0;

    lines.forEach((line) {
      final commentStart = line.indexOf('//');
      if (commentStart == -1)
        return;
      // skip the two forward slashes
      final comment = line.substring(commentStart+2).trimLeft();
      if (comment.startsWith('output ')) {
        if (isRepeat) {
          repeatOutputs.add(comment.substring('output '.length));
        } else {
          _outputs.add(comment.substring('output '.length));
        }
      } else if (comment.startsWith('error ')) {
        _errors.add(comment.substring('error '.length));
      } else if (comment.startsWith('ignore')) {
        if (isRepeat) {
          repeatOutputs.add(null);
        } else {
          _outputs.add(null);
        }
      } else if (comment.startsWith('repeat ')) {
        count = int.parse(comment.substring('repeat '.length));
        isRepeat = true;
      } else if (comment.startsWith('endrepeat')) {
        for (int i = 0; i < count; ++i)
          _outputs.addAll(repeatOutputs);
        isRepeat = false;
        repeatOutputs = [];
        count = 0;
      }
    });
    if (isRepeat) {
      print("Warning: repeat directive didn't find a matching endrepeat.");
    }
  }

  bool doesExpectOutput() => _outputs.isNotEmpty && _matchedOutputs != _outputs.length;

  String nextOutput() {
    assert(_matchedOutputs < _outputs.length);
    return _outputs[_matchedOutputs++];
  }

  bool doesExpectError() => _errors.isNotEmpty && _matchedErrors != _errors.length;

  String nextError() {
    assert(_matchedErrors < _errors.length);
    return _errors[_matchedErrors++];
  }

  String getError() => _matchedErrors == _errors.length ? null : _errors[_matchedErrors];
}

void main() {
  test.test('Runs program correctly', () async {
    final process = await TestProcess.start(
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

  test.group('All testFile programs run with expected results', () {
    final Directory directory = Directory('./test/testFiles');
    directory.listSync().forEach((file) {
      test.test(file.path, () async {
        await _testBirbScriptWithExpectations(file);
      });
    });
  });

  test.group('All example programs run with expected results', () {
    final Directory directory = Directory('./examples/');
    directory.listSync().forEach((file) {
      test.test(file.path, () async {
        await _testBirbScriptWithExpectations(file);
      });
    });
  });
}

Future _testBirbScriptWithExpectations(FileSystemEntity file) async {
  final expectations = ExpectationsParser(file);
  final process =
  await TestProcess.start('dart', ['./lib/birb.dart', file.path]);
  
  // skip dart Warning for interpreting ./lib/birb.dart as package URI
  final shouldFailOnError = !expectations.doesExpectError();
  await for (final line in process.stderrStream().skip(1)) {
    if (shouldFailOnError) {
      test.fail('Unexpected error');
    }
    if (expectations.doesExpectError() && line.contains(expectations.getError())) {
      expectations.nextError();
    }
  }
  if (expectations.doesExpectError()) {
    test.fail('expected ${expectations.nextError()} error next');
  }

  final ignored = <String>[];
  await for (final line in process.stdoutStream()) {
    if (expectations.doesExpectOutput()) {
      final expected = expectations.nextOutput();
      if (expected == null) {
        ignored.add(line);
      } else {
        test.expect(line, test.equals(expected));
      }
    } else {
      test.fail('Too many outputs: unexpected $line');
    }
  }
  if (expectations.doesExpectOutput()) {
    test.fail('Too few outputs: expected ${expectations.nextOutput()} next');
  }
  await process.shouldExit();
  
  if (ignored.isNotEmpty) {
    print('Warning: ignoring output lines:');
    print(ignored);
  }
}
