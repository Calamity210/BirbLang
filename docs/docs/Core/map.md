---
id: map
title: Map
---

A `Map` is a dictionary of key/value pairs, from which you can get a value associated with its key. A `Map` cannot contain duplicate keys, nor can a key hold more than one value.


```dart
Map map = {
    "content": "This is a message"
};

screm(map["content"]);
```

## Properties

### isEmpty

`bool isEmpty`

Returns a bool that is true if this Map is empty. 

**Example**
```dart
Map map = {
    "content": "This is a message"
};
bool isEmpty = map.isEmpty; // false
```

### isNotEmpty

`bool isNotEmpty`

Returns a bool that is true if this Map is not empty. 

**Example**
```dart
Map map = {
    "content": "This is a message"
};
bool isNotEmpty = map.isNotEmpty; // true
```

### length

`int length`

Returns an int containing the length of this Map.

**Example**
```dart
Map map = {
    "content": "This is a message"
};
int length = map.length; // 1
```

### runtimeType

`String runtimeType`

Returns the runtime type of this.

**Example**
```dart
Map map = {
    "content": "This is a message"
};
String type = map.runtimeType; // Map
```

## Methods

### toString

`String toString`

Returns the string value of this

**Example**
```dart
Map map = {
    "content": "This is a message"
};
String stringValue = map.toString(); // {"content": "This is a message"}
```