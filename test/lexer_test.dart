import 'dart:io';

import 'package:Birb/utils/lexer.dart';
import 'package:Birb/utils/token.dart';
import 'package:test/test.dart' as test;

void main() {
  test.test('Lexer gets tokens correctly', () {
    Lexer lexer =
        initLexer(File('test/TestPrograms/test_lexer.birb').readAsStringSync());

    assert(lexer != null);
    test.expect(lexer.currentChar, test.equals('v'));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_ID));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_ID));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_LPAREN));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_ID));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_ID));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_RPAREN));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_LBRACE));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_ID));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_ID));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_SEMI));
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_RBRACE));

    test.expect(lexer.currentIndex, test.equals(lexer.contents.length));
  });
}
