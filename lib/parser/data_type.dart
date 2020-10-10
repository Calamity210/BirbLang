enum DATATYPE {
  DATA_TYPE_VOID,
  DATA_TYPE_STRING,
  DATA_TYPE_STRING_BUFFER,
  DATA_TYPE_VAR,
  DATA_TYPE_INT,
  DATA_TYPE_DOUBLE,
  DATA_TYPE_BOOL,
  DATA_TYPE_CLASS,
  DATA_TYPE_ENUM,
  DATA_TYPE_LIST,
  DATA_TYPE_MAP,
  DATA_TYPE_SOURCE
}

class DataType {

  DataType() {
    modifiers.fillRange(0, 2, 0);
  }

  DataType.as(this.type) {
    modifiers.fillRange(0, 2, 0);
  }

  DATATYPE type = DATATYPE.DATA_TYPE_VOID;
  List<int> modifiers = List<int>(3);
}

bool dataTypeHasModifier(DataType dataType, int modifier) {
  if (dataType == null)
    return false;

  for (int i = 0; i < 2; i++) {
    if (dataType.modifiers[i] == modifier)
      return true;
  }

  return false;
}
