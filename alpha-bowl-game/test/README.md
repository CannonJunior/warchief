# Warchief Game Tests

This directory contains unit and integration tests for the Warchief game refactoring.

## Structure

```
test/
├── models/          # Tests for data models (Projectile, Ally, etc.)
├── systems/         # Tests for game systems (Physics, AI, Abilities, etc.)
└── integration/     # End-to-end integration tests
```

## Running Tests

```bash
flutter test
```

## Test Coverage Goals

- **Models**: 80%+ coverage
- **Systems**: 70%+ coverage
- **Integration**: Critical user flows

## Writing Tests

Follow these conventions:
1. One test file per source file
2. Use descriptive test names
3. Test expected behavior, edge cases, and failure modes
4. Use AAA pattern (Arrange, Act, Assert)

## Example

```dart
test('Projectile moves in correct direction', () {
  // Arrange
  final projectile = Projectile(...);

  // Act
  projectile.update(1.0);

  // Assert
  expect(projectile.position.x, closeTo(expected, 0.01));
});
```
