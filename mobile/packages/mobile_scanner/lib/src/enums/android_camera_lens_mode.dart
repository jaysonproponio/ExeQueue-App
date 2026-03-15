/// Android-only preference for selecting a specific rear camera lens.
enum AndroidCameraLensMode {
  /// Use the platform's default rear camera selection.
  normal(0),

  /// Prefer the widest available rear camera.
  ultraWide(1);

  const AndroidCameraLensMode(this.rawValue);

  final int rawValue;
}
