import 'dart:io';

import 'package:Birb/lexer/lexer.dart';
import 'package:Birb/lexer/token.dart';
import 'package:test/test.dart' as test;

void main() {
  test.test('Lexer handles empty input correctly', () {
    final Lexer lexer = initLexer('');
    test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_EOF));
  });

  test.test('Lexer handles equal char after double char tokens correctly', () {
    void testInput(String input, List<TokenType> expectations) {
      // new line so that end of input errors don't get mixed up in this test
      final lexer = initLexer(input + '\n');
      for (final token in expectations) {
        test.expect(getNextToken(lexer).type, test.equals(token));
      }
      test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_EOF));
    }
    
    testInput('++=', [TokenType.TOKEN_PLUS_PLUS, TokenType.TOKEN_EQUAL]);
    testInput('--=', [TokenType.TOKEN_SUB_SUB, TokenType.TOKEN_EQUAL]);
    testInput('**=', [TokenType.TOKEN_MUL_MUL, TokenType.TOKEN_EQUAL]);
  });

  test.group('Lexer handles end of input correctly for', () {
    test.test('comment', () {
      final Lexer lexer = initLexer("// this is a comment that doesn't end with a new line");
      test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_EOF));
    });

    test.test('single character tokens', () {
      void testInput(String input, TokenType type, TokenType notType) {
        final Lexer lexer = initLexer(input);
        final token = getNextToken(lexer);
        test.expect(token.type, test.equals(type));
        test.expect(token, test.isNot(test.equals(notType)));
        test.expect(getNextToken(lexer).type, test.equals(TokenType.TOKEN_EOF));
      }

      testInput('+', TokenType.TOKEN_PLUS, TokenType.TOKEN_PLUS_PLUS);
      testInput('-', TokenType.TOKEN_SUB, TokenType.TOKEN_SUB_SUB);
      testInput('*', TokenType.TOKEN_MUL, TokenType.TOKEN_MUL_MUL);
      testInput('=', TokenType.TOKEN_EQUAL, TokenType.TOKEN_EQUALITY);
      // since comment tokens are ignored we check that the returned token isn't EOF
      testInput('/', TokenType.TOKEN_DIV, TokenType.TOKEN_EOF);
    });
  });

  test.test('Lexer gets tokens correctly', () {
    final Lexer lexer =
        initLexer(File('./test/TestPrograms/test_lexer.birb').readAsStringSync());

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

    test.expect(lexer.currentIndex, test.equals(lexer.program.length));
  });
}
