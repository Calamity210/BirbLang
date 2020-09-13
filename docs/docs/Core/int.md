---
id: int
title: int
---

An integer number.

```dart
int number = 10;
screm(number);
```

## Properties

### isEven

`bool isEven`

Returns true if the integer is even.

**Example**
```dart
int number = 10;
bool isEven = number.isEven; // true
```

### isFinite

`bool isFinite`

Returns true if the integer is finite.

**Example**
```dart
int number = 10;
bool isFinite = number.isFinite; // true
```

### isInfinite

`bool isInfinite`

Returns true if the integer is infinite.

**Example**
```dart
int number = 10;
bool isInfinite = number.isInfinite; // false
```

### isNaN

`bool isNaN`

Returns true if the number is the double Not-a-Number value

**Example**
```dart
int number = 10;
bool isNaN = number.isNaN; // false
```


### isNegative

`bool isNegative`

True if the number is negative

**Example**
```dart
int number = 10;
bool isNegative = number.isNegative; // false
```

### isOdd

`bool isOdd`

True if the number is odd.

**Example**
```dart
int number = 10;
bool isOdd = number.isOdd; // false
```

### sign

`int sign`

Returns the sign of this integer. Returns 0, -1 for values less than zero and +1 for values greater than zero.

**Example**
```dart
int number = 10;
bool signValue = number.sign; // 1
```

### runtimeType

`String runtimeType`

Returns the runtime type of this

**Example**
```dart
int number = 10;
bool type = number.runtimeType; // int
```

### bitLength

`int bitLength`

Returns the minimum number of bits required to store this integer.

**Example**
```dart
int number = 10;
bool bitLength = number.bitLength;
```