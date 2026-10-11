/// A deterministic 64-bit content fingerprint, as 16 lowercase hex digits.
///
/// Used where a value must be stable across processes, releases and
/// platforms (cache keys, cache-busting query strings) - unlike
/// [Object.hashCode], which Dart seeds per run. It is not a cryptographic
/// hash and must never guard anything security-relevant.
///
/// [bytes] are octets: callers hash text as `utf8.encode(text)`, never as
/// UTF-16 code units, whose high bytes would otherwise be discarded.
///
/// Pure Dart with no Flutter imports, so `dart run` tooling can share it.
String contentHash64(List<int> bytes) {
  final low = _fnv1a32(bytes, 0x811c9dc5);
  final high = _fnv1a32(bytes, 0x811c9dc5 ^ 0x9747b28c);
  return high.toRadixString(16).padLeft(8, '0') +
      low.toRadixString(16).padLeft(8, '0');
}

/// 32-bit FNV-1a with a caller-chosen offset basis.
///
/// The multiply is decomposed into shifts (prime 16777619 = 2^24+2^8+0x93)
/// so every intermediate stays below 2^53 and the result is identical on
/// the VM and on the web's double-backed ints.
int _fnv1a32(List<int> bytes, int offsetBasis) {
  var hash = offsetBasis;
  for (final byte in bytes) {
    hash ^= byte & 0xff;
    hash =
        (((hash << 24) & 0xFFFFFFFF) +
            ((hash << 8) & 0xFFFFFFFF) +
            hash * 0x93) &
        0xFFFFFFFF;
  }
  return hash;
}
