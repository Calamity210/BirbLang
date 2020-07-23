enum TokenType {
  TOKEN_STRING_VALUE,
  TOKEN_VAR_VALUE,
  TOKEN_INT_VALUE,
  TOKEN_DOUBLE_VALUE,
  TOKEN_NUMBER_VALUE,
  TOKEN_BOOL_VALUE,
  TOKEN_ID,
  TOKEN_ANON_ID,
  TOKEN_LBRACE,
  TOKEN_RBRACE,
  TOKEN_LPAREN,
  TOKEN_RPAREN,
  TOKEN_LBRACKET,
  TOKEN_RBRACKET,
  TOKEN_EQUAL,
  TOKEN_EQUALITY,
  TOKEN_NOT_EQUAL,
  TOKEN_NOT,
  TOKEN_SEMI,
  TOKEN_COMMA,
  TOKEN_PLUS,
  TOKEN_PLUS_EQUAL,
  TOKEN_SUB,
  TOKEN_SUB_EQUAL,
  TOKEN_MUL,
  TOKEN_MUL_EQUAL,
  TOKEN_DIV,
  TOKEN_MOD,
  TOKEN_DOT,
  TOKEN_LESS_THAN,
  TOKEN_GREATER_THAN,
  TOKEN_AND,
  TOKEN_OR,
  TOKEN_QUESTION,
  TOKEN_COLON,
  TOKEN_EOF
}

class Token {
  TokenType type;
  String value;
}

Token initToken(TokenType type, String value) {
  var token = Token();
  token.type = type;
  token.value = value;
  return token;
}

Token copyToken(Token token) {
  return initToken(token.type, token.value);
}
