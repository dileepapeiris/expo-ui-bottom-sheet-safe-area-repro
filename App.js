import { StyleSheet, Text, View, useWindowDimensions } from 'react-native';

// Repro for expo/expo#53369: the community BottomSheet's content stops short of the sheet edge
// when the window has a horizontal safe-area inset (iPhone Duo folded, side rail on the right).

export default function App() {
  const window = useWindowDimensions();

  return (
    <View style={styles.screen}>
      <Text>window {Math.round(window.width)}x{Math.round(window.height)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff', gap: 12 },
});
