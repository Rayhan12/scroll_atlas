/// xorshift32 generator. Uses only 32-bit masked shifts and xors, so a seed
/// gives the same sequence on the Dart VM, Android, iOS and the web, which
/// `dart:math` Random does not promise.
final class DeterministicRandom {
  /// Creates a generator. A zero seed is replaced, since xorshift needs a
  /// non-zero state.
  DeterministicRandom(int seed)
      : _state = (seed & _mask) == 0 ? 0x9E3779B9 : seed & _mask;

  static const int _mask = 0xFFFFFFFF;
  int _state;

  /// Next unsigned 32-bit value.
  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & _mask;
    x ^= x >> 17;
    x ^= (x << 5) & _mask;
    return _state = x & _mask;
  }

  /// Uniform double in [0, 1).
  double nextDouble() => nextUint32() / 4294967296.0;

  /// Uniform double in [min, max).
  double nextInRange(double min, double max) =>
      min + nextDouble() * (max - min);

  /// Uniform int in [0, max).
  int nextInt(int max) => (nextDouble() * max).floor();
}
