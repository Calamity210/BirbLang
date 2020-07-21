typedef RemoveCallbackFunction = void Function(dynamic item);

class DynamicList {
  int size;
  int itemSize;
  List items;

  DynamicList(this.size, this.itemSize, this.items);
}

DynamicList initDynamicList(int itemSize) {
  var dynamicList = DynamicList(0, itemSize, []);

  return dynamicList;
}

dynamic dynamicListAppend(DynamicList dynamicList, dynamic item) {
  dynamicList.size++;
  dynamicList.items.add(item);

  return item;
}

void dynamicListShiftLeft(DynamicList dynamicList, int index) {
  for (var i = index; i < dynamicList.size; i++) {
    dynamicList.items[i] = dynamicList.items[i + 1];
  }
}

void dynamicListRemove(DynamicList dynamicList, dynamic element,
    RemoveCallbackFunction removeCallback) {
  var index = 0;

  if (element == null) return;

  for (var i = 0; i < dynamicList.size; i++) {
    if (dynamicList.items[i] == element) {
      index = i;
      break;
    }
  }

  if (removeCallback != null) {
    removeCallback(dynamicList.items[index]);
  }

  dynamicListShiftLeft(dynamicList, index);

  dynamicList.size = dynamicList.size - 1;
}
