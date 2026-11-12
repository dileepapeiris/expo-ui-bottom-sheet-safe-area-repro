# community BottomSheet content and a side safe-area inset

Reproduction and measurements for [expo/expo#53369](https://github.com/expo/expo/issues/53369):
on iOS, the `@expo/ui/community/bottom-sheet` content stops short of the sheet's edge when the
window has a horizontal safe-area inset, and the component has no way to add modifiers.

Expo SDK 58 (`expo` 58.0.21, `@expo/ui` 58.0.28 built from source, `expo-modules-core` 58.0.28),
React Native 0.88.0, `react-native-safe-area-context` 5.10.1, Xcode 27.2, 11/12/26.
Simulators: iPhone Duo (iOS 27.1, folded, 466×678 pt, side rail = 84 pt right inset) and
iPhone 17 (iOS 26.5), portrait and pinned to landscape (874×402 pt, 62 pt insets on both sides).
