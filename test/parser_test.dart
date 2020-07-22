import 'dart:io';

import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/lexer.dart';
import 'package:Birb/utils/parser.dart';
import 'package:test/test.dart' as test;

void main() {
  test.test('Parser doesn\'t crash' , () {
    Lexer lexer = initLexer(
        File('test/TestPrograms/test_parser.birb').readAsStringSync());
    Parser parser = initParser(lexer);
    AST ast = parse(parser);

    assert(parser != null);
    test.expect(ast.type, test.equals(ASTType.AST_COMPOUND));
  });
}
