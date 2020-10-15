import 'package:Birb/utils/exceptions.dart';

import 'package:Birb/lexer/token.dart';

class Lexer {
  Lexer(String program) {
    this.program = program.trim();
    currentChar = program.isEmpty ? '' : program[currentIndex];
  }

  String program;
  String currentChar;
  int currentIndex = 0;
  int lineNum = 1;


  /// Grabs next token from the lexer
  Token getNextToken() {
    while (
    currentIndex < program.length && currentChar != null) {
      // Skip
      if (currentChar == ' '
          || currentChar == '\n'
          || currentChar == '\r')
        skipWhitespace();

      // Collect a num
      if (isNumeric(currentChar)) {
        return collectNumber();
      }

      if (currentChar == 'r') {
        advance();

        if (currentChar == '"')
          collectString(true);
        else if (currentChar == "'")
          collectSingleQuoteString(true);

        if (RegExp('[a-zA-Z_]').hasMatch(currentChar)) {
          return collectId('r');
        }
      }

      // Collect identifiers
      if (RegExp('[a-zA-Z_]').hasMatch(currentChar)) {
        return collectId();
      }

      switch (currentChar) {
        case '+':
          String value = currentChar;
          TokenType type = TokenType.TOKEN_PLUS;
          advance();

          // ++
          if (currentChar == '+') {
            type = TokenType.TOKEN_PLUS_PLUS;
            value += currentChar;
            advance();
          }

          // +=
          else if (currentChar == '=') {
            type = TokenType.TOKEN_PLUS_EQUAL;
            value += currentChar;
            advance();
          }

          return Token(type, value);
        case '-':
          String value = currentChar;
          TokenType type = TokenType.TOKEN_SUB;

          advance();

          // --
          if (currentChar == '-') {
            type = TokenType.TOKEN_SUB_SUB;
            value += currentChar;

            advance();
          }

          // -=
          else if (currentChar == '=') {
            type = TokenType.TOKEN_SUB_EQUAL;
            value += currentChar;

            advance();
          }

          return Token(type, value);
        case '*':
          String value = currentChar;
          TokenType type = TokenType.TOKEN_MUL;
          advance();

          // **
          if (currentChar == '*') {
            type = TokenType.TOKEN_MUL_MUL;
            value += currentChar;
            advance();
          }

          // *=
          else if (currentChar == '=') {
            type = TokenType.TOKEN_MUL_EQUAL;
            value += currentChar;
            advance();
          }

          return Token(type, value);
        case '&':
          String value = currentChar;
          advance();

          // &&
          if (currentChar == '&') {
            value += currentChar;

            advance();

            return Token(TokenType.TOKEN_AND, value);
          }

          return Token(TokenType.TOKEN_BITWISE_AND, value);
          break;
        case '|':
          String value = currentChar;
          advance();

          // ||
          if (currentChar == '|') {
            value += currentChar;
            advance();
            return Token(TokenType.TOKEN_OR, value);
          }

          return Token(TokenType.TOKEN_BITWISE_OR, value);

        case '<':
          String value = currentChar;
          advance();

          // <<
          if (currentChar == '<') {
            value += currentChar;
            advance();
            return Token(TokenType.TOKEN_LSHIFT, value);
          }

          // <=
          if (currentChar == '=') {
            value += currentChar;
            advance();
            return Token(TokenType.TOKEN_LESS_THAN_EQUAL, value);
          }

          return Token(TokenType.TOKEN_LESS_THAN, value);
        case '>':
          String value = currentChar;
          advance();

          // >>
          if (currentChar == '>') {
            value += currentChar;
            advance();
            return Token(TokenType.TOKEN_RSHIFT, value);
          }

          // >=
          if (currentChar == '=') {
            value += currentChar;
            advance();
            return Token(TokenType.TOKEN_GREATER_THAN_EQUAL, value);
          }

          return Token(TokenType.TOKEN_GREATER_THAN, value);
        case '=':
          String value = currentChar;
          TokenType type = TokenType.TOKEN_EQUAL;

          advance();

          // ==
          if (currentChar == '=') {
            type = TokenType.TOKEN_EQUALITY;
            value += currentChar;

            advance();
          }

          // =>
          if (currentChar == '>') {
            type = TokenType.TOKEN_INLINE;
            value += currentChar;

            advance();
          }

          return Token(type, value);
        case '!':
          String value = currentChar;
          TokenType type = TokenType.TOKEN_NOT;
          advance();

          // !=
          if (currentChar == '=') {
            type = TokenType.TOKEN_NOT_EQUAL;
            value += currentChar;
            advance();
          }

          return Token(type, value);
        case '/':
          advance();

          // Inline comment
          if (currentChar == '/') {
            advance();
            skipInlineComment();
            continue;
          } else if (currentChar == '*') {
            // Block comment
            advance();
            skipBlockComment();
            continue;
          } else {
            return Token(TokenType.TOKEN_DIV, '/');
          }
      }

      // END OF FILE
      if (currentChar == '' || currentChar == null)
        return Token(TokenType.TOKEN_EOF, '');

      switch (currentChar) {
        case '"':
          return collectString();
        case "'":
          return collectSingleQuoteString();
        case '{':
          return advanceWithToken(TokenType.TOKEN_LBRACE);
        case '}':
          return advanceWithToken(TokenType.TOKEN_RBRACE);
        case '(':
          return advanceWithToken(TokenType.TOKEN_LPAREN);
        case ')':
          return advanceWithToken(TokenType.TOKEN_RPAREN);
        case '[':
          return advanceWithToken(TokenType.TOKEN_LBRACKET);
        case ']':
          return advanceWithToken(TokenType.TOKEN_RBRACKET);
        case ';':
          return advanceWithToken(TokenType.TOKEN_SEMI);
        case ',':
          return advanceWithToken(TokenType.TOKEN_COMMA);
        case '.':
          return advanceWithToken(TokenType.TOKEN_DOT);
        case '%':
          return advanceWithToken(TokenType.TOKEN_MOD);
        case '~':
          return advanceWithToken(TokenType.TOKEN_ONES_COMPLEMENT);
        case '^':
          return advanceWithToken(TokenType.TOKEN_BITWISE_XOR);
        case '@':
          return advanceWithToken(TokenType.TOKEN_ANON_ID);
        case '?':
          String value = currentChar;
          TokenType type = TokenType.TOKEN_QUESTION;
          advance();

          // ??
          if (currentChar == '?') {
            type = TokenType.NOSEEB_AWARE_OPERATOR;
            value += currentChar;
            advance();

            // ??=
            if (currentChar == '=') {
              type = TokenType.TOKEN_NOSEEB_ASSIGNMENT;
              value += currentChar;
              advance();
            }
          }

          if (currentChar == '.') {
            type = TokenType.TOKEN_NOSEEB_ACCESS;
            value += currentChar;
            advance();
          }

          return Token(type, value);
        case ':':
          return advanceWithToken(TokenType.TOKEN_COLON);
        default:
          throw UnexpectedTokenException(
              '[Line $lineNum] Unexpected $currentChar');
          break;
      }
    }

    // END OF FILE
    return Token(TokenType.TOKEN_EOF, '');
  }

  /// Advances to the next character
  void advance() {
    if (currentChar != '' &&
        currentIndex < program.length - 1) {
      currentIndex += 1;
      currentChar = program[currentIndex];
    } else if (currentIndex == program.length - 1) {
      currentIndex++;
      currentChar = null;
    }
  }

  /// Checks whether the input has been fully consumed
  bool isAtEnd() {
    return currentIndex == program.length;
  }

  /// Advances while returning a Token
  Token advanceWithToken(TokenType type) {
    final String value = currentChar;
    final Token token = Token(type, value);

    advance();
    skipWhitespace();

    return token;
  }

  /// Expects a character and throws UnexpectedTokenException if
  /// the wrong character is received
  void expect(String c) {
    if (currentChar != c)
      throw UnexpectedTokenException(
          'Error: [Line $lineNum] Lexer expected the current char to be `$c`, but it was `$currentChar`.');
  }

  /// Skips any whitespaces since we don't want to have whitespace tokens
  void skipWhitespace() {
    while (currentChar == ' ' ||
        currentChar == '\n' ||
        currentChar == '\r') {

      if (currentChar == '')
        return;

      if (currentChar == '\n')
        ++lineNum;
      advance();
    }
  }

  /// Skip comments since they are only notes for the developers
  void skipInlineComment() {
    while (currentChar != '\n' &&
        currentChar != '\n' &&
        !isAtEnd()) {
      advance();
    }
  }

  /// Skips block comments
  void skipBlockComment() {
    while (true) {
      advance();

      if (currentChar == '*') {
        advance();

        if (currentChar == '/') {
          advance();
          return;
        }
      }
    }
  }

  /// Collect a string from within double quotation marks
  Token collectString([bool isRaw = false]) {
    expect('"');
    advance();

    final int initialIndex = currentIndex;

    while (currentChar != '"') {
      if (currentIndex == program.length - 1)
        throw UnexpectedTokenException(
            '[Line $lineNum] Missing closing `"`');

      advance();
    }

    final String value = program.substring(initialIndex, currentIndex);
    final Token token = Token(TokenType.TOKEN_STRING_VALUE, isRaw ? value : value.escape());

    advance();

    return token;
  }

  /// Collect a string from within single quotation marks
  Token collectSingleQuoteString([bool isRaw = false]) {
    expect('\'');
    advance();

    final int initialIndex = currentIndex;

    while (currentChar != '\'') {
      if (currentIndex == program.length - 1)
        throw UnexpectedTokenException(
            '[Line $lineNum] Missing closing `\'`');

      advance();
    }

    final String value = program.substring(initialIndex, currentIndex);
    final Token token = Token(TokenType.TOKEN_STRING_VALUE, isRaw ? value : value.escape());

    advance();

    return token;
  }

  /// Collect numeric tokens
  Token collectNumber() {
    TokenType type = TokenType.TOKEN_INT_VALUE;
    String value = '';

    if (currentChar == '0') {
      value += currentChar;
      advance();

      // 0x | 0X
      if (currentChar == 'x' || currentChar == 'X') {
        value += currentChar;
        advance();

        while (RegExp('[0-9a-fA-F]').hasMatch(currentChar)) {
          value += currentChar;
          advance();
        }

        return Token(TokenType.TOKEN_INT_VALUE, value);
      }
    }

    while (isNumeric(currentChar)) {
      value += currentChar;
      advance();
    }

    // double
    if (currentChar == '.') {
      if (isNumeric(program[currentIndex + 1])) {
        type = TokenType.TOKEN_DOUBLE_VALUE;
        value += currentChar;

        advance();

        while (isNumeric(currentChar)) {
          value += currentChar;
          advance();
        }
      }
    }

    if (currentChar == 'e') {
      type = TokenType.TOKEN_DOUBLE_VALUE;
      value += currentChar;

      advance();

      if (currentChar == '+' || currentChar == '-') {
        value += currentChar;

        advance();
      }

      while (isNumeric(currentChar)) {
        value += currentChar;
        advance();
      }
    }

    return Token(type, value);
  }

  /// Collects identifiers
  Token collectId([String prefix = '']) {
    final int initialIndex = currentIndex;

    // Identifiers can only start with `_` or any alphabet
    if (RegExp('[a-zA-Z_]').hasMatch(currentChar)) {
      advance();

      while (RegExp('[a-zA-Z0-9_]').hasMatch(currentChar))
        advance();
    }

    // Nullable?
    if (currentChar == '?' && RegExp(r'\s').hasMatch(program[currentIndex + 1])) {
      advance();
    }

    return Token(TokenType.TOKEN_ID,
        prefix + program.substring(initialIndex, currentIndex));
  }

  /// Check if the character is numeric
  bool isNumeric(String s) {
    if (s == null) {
      return false;
    } else {
      return double.tryParse(s) != null || int.tryParse(s) != null;
    }
  }
}

  extension on String {
  String escape() {
    String escapedString = this;

    escapedString = escapedString
        .replaceAll(r'\f', '\x0C')
        .replaceAll(r'\n', '\x0A')
        .replaceAll(r'\r', '\x0D')
        .replaceAll(r'\t', '\x09')
        .replaceAll(r'\v', '\x0B')
        .replaceAll(r'\\', '\x5C')
        .replaceAll(r"\'", '\x27')
        .replaceAll(r'\"', '\x22')
        .replaceAllMapped(RegExp(r'\\x(.){2}'), (m) => String.fromCharCode(int.parse(m.group(1), radix: 16)))
        .replaceAllMapped(RegExp(r'\\u(.{1,5});'), (m) => String.fromCharCode(int.parse(m.group(1), radix: 16)))
        .replaceAll(r'\$', '\$')
        .replaceAll(r'$', '\x1B[');

    return escapedString;
  }
}
