---
id: string
title: String
---

# String type

An array of chars (UTF-16) code units.

A data type used mainly to represent text, denoted by the `'` or `"`s its wrapped within.

Strings in birb are multiline by default:

```dart
screm("This string will print on one line");

// OR

screm("
This String
will print on two lines
");
```

You can use the `+` operator to concat Strings:

```dart
screm("Henlo " + "birb!") // "Henlo birb!"
```

## Properties
- [codeUnits](#codeunits)
- [isEmpty](#isempty)
- [isNotEmpty](#isnotempty)
- [length](#length)

## Methods
- [codeUnitAt](#codeunitat)
- [compareTo](#compareto)
- [contains](#contains)
- [endsWith](#endswith)
- [indexOf](#indexof)
- [input](#input)

# Properties

## codeUnits

List codeUnits

Returns a list containing the 16-bit Unicode code units of this String.

### Example
```dart
String birb = "birb";
List codeUnits = birb.codeUnits; // [98, 105, 114, 98]
```


## isEmpty

bool isEmpty

True if this String is empty

### Example
```dart
String birb = "birb";
bool isEmpty = birb.isEmpty; // false
```

## isNotEmpty

bool isNotEmpty

True if this String is not empty

### Example
```dart
String birb = "birb";
bool isNotEmpty = birb.isNotEmpty; // true
```

## length

int length

Returns an int containing the length of this String

### Example
```dart
String birb = "birb";
int length = birb.length; // 4
```

# Methods

## codeUnitAt

int codeUnitAt(int index)

Returns the codeUnit at the given index

### Example
```dart
String birb = "birb";
int codeUnit = birb.codeUnitAt(0); // 98
```

## compareTo

int compareTo(String str)

Compares the codeUnits of this String to `str`. The returned in is negative if this String is ordered before `str`, positive if after and zero if they are the same. 

### Example
```dart
String birb = "birb";
 int compareValue = birb.compareTo("seeb"); // -1
```

## contains

bool contains(String other, int startIndex)

Returns true if this String contains `other` at or after the startIndex

### Example
```dart
String birb = "birb";
 int compareValue = birb.contains("seeb"); // false
```

## endsWith

bool endsWith(String str)

Returns true if this String ends with `str` 

### Example
```dart
String birb = "birb";
int compareValue = birb.endsWith("seeb"); // false
```

# indexOf

int indexOf(String str, int start)

Returns the index of the first match of `str` starting from `start` within this `String`

## Example
```dart
String birb = "birb";
 int compareValue = birb.indexOf("b", 0); // 0
```

# input 

int input(String str)

Prints this String before reading a line from StdIn

### Example
```dart
String birb = "birb";
 int compareValue = birb.input("b");
```