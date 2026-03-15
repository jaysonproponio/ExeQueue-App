package dev.steenbakker.mobile_scanner

enum class AndroidCameraLensMode(val rawValue: Int) {
    NORMAL(0),
    ULTRA_WIDE(1);

    companion object {
        fun fromRawValue(rawValue: Int): AndroidCameraLensMode {
            return values().firstOrNull { it.rawValue == rawValue } ?: NORMAL
        }
    }
}
