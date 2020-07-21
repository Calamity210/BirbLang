enum DATATYPE {
  DATA_TYPE_VOID,
  DATA_TYPE_STRING,
  DATA_TYPE_INT,
  DATA_TYPE_DOUBLE,
  DATA_TYPE_BOOL,
  DATA_TYPE_OBJECT,
  DATA_TYPE_ENUM,
  DATA_TYPE_LIST,
  DATA_TYPE_SOURCE
}

class DataType {
  DATATYPE type;
  List<int> modifiers = List<int>(3);
}

DataType initDataType() {
  var dataType = DataType();
  dataType.type = DATATYPE.DATA_TYPE_VOID;
  dataType.modifiers[0] = 0;
  dataType.modifiers[1] = 0;
  dataType.modifiers[2] = 0;

  return dataType;
}

DataType initDataTypeAs(DATATYPE type) {
  var dataType = initDataType();
  dataType.type = type;

  return dataType;
}

DataType dataTypeCopy(DataType src) {
  var dataType = initDataType();
  dataType.type = src.type;
  dataType.modifiers[0] = src.modifiers[0];
  dataType.modifiers[1] = src.modifiers[1];
  dataType.modifiers[2] = src.modifiers[2];

  return dataType;
}

bool dataTypeHasModifier(DataType dataType, int modifier) {
  if (dataType == null) return false;

  for (var i = 0; i < 2; i++) {
    if (dataType.modifiers[i] == modifier) return true;
  }

  return false;
}
