import 'dart:io';

import 'package:Birb/lexer/lexer.dart';
import 'package:Birb/parser/parser.dart';
import 'package:Birb/ast/ast_node.dart';
import 'package:test/test.dart' as test;

void main() {
  test.test("Parser doesn't crash" , () {
    final Lexer lexer = initLexer(
        File('./test/TestPrograms/test_parser.birb').readAsStringSync());
    final Parser parser = initParser(lexer);
    final ASTNode ast = parse(parser);

    assert(parser != null);
    test.expect(ast.type, test.equals(ASTType.AST_COMPOUND));
  });
}
