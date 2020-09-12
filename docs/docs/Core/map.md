---
id: map
title: Map
---

A collection of key/value pairs, from which you retrieve a value using its associated key.


```dart
Map map = {
    "content": "This is a message"
};

screm(map);
```

## Properties

## isEmpty

`bool isEmpty`

True is this String is empty

**Example**
```dart
Map map = {
    "content": "This is a message"
};
bool isEmpty = map.isEmpty; // false
```

### isNotEmpty

`bool isNotEmpty`

True if this String is not empty.

**Example**
```dart
Map map = {
    "content": "This is a message"
};
bool isNotEmpty = map.isNotEmpty; // true
```

### length

`int length`

Returns an int containing the length of this String.

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

### hashCode

`int hashCode`

Returns the hash code of this

**Example**
```dart
Map map = {
    "content": "This is a message"
};
int hashCode = map.hashCode; // Hash Code
```

## Methods

### toString

`String string`

Returns the string value of this

**Example**
```dart
Map map = {
    "content": "This is a message"
};
String stringValue = map.toString(); // {"content": "This is a message"}
```