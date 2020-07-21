//typedef RemoveCallbackFunction = void Function(dynamic item);
//
//class List {
//  int size;
//  int itemSize;
//  List items;
//
//  List(this.size, this.itemSize, this.items);
//}
//
//List initList(int itemSize) {
//  var dynamicList = List(0, itemSize, []);
//
//  return dynamicList;
//}
//
//dynamic dynamicListAppend(List dynamicList, dynamic item) {
//  dynamicList.size++;
//  dynamicList.items.add(item);
//
//  return item;
//}
//
//void dynamicListShiftLeft(List dynamicList, int index) {
//  for (int i = index; i < dynamicList.size; i++) {
//    dynamicList.items[i] = dynamicList.items[i + 1];
//  }
//}
//
//void dynamicListRemove(List dynamicList, dynamic element,
//    RemoveCallbackFunction removeCallback) {
//  var index = 0;
//
//  if (element == null) return;
//
//  for (int i = 0; i < dynamicList.size; i++) {
//    if (dynamicList.items[i] == element) {
//      index = i;
//      break;
//    }
//  }
//
//  if (removeCallback != null) {
//    removeCallback(dynamicList.items[index]);
//  }
//
//  dynamicListShiftLeft(dynamicList, index);
//
//  dynamicList.size = dynamicList.size - 1;
//}
