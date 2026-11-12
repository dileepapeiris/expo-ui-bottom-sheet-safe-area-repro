import { useState } from 'react';
import { Button, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
import { SafeAreaProvider, useSafeAreaInsets } from 'react-native-safe-area-context';
import { BottomSheet } from '@expo/ui/community/bottom-sheet';

// Repro for expo/expo#53369: the community BottomSheet's content stops short of the sheet edge
// when the window has a horizontal safe-area inset (iPhone Duo folded, side rail on the right).
// With AUTORUN the sheet opens by itself 1.5 s after launch, so every run is recorded the same way.
const AUTORUN = true;

function fmt(i) {
  return `t${Math.round(i.top)} r${Math.round(i.right)} b${Math.round(i.bottom)} l${Math.round(i.left)}`;
}

function SheetContent({ window }) {
  const sheetInsets = useSafeAreaInsets();
  const [layout, setLayout] = useState(null);
  return (
    <View style={styles.content} onLayout={(e) => setLayout(e.nativeEvent.layout)}>
      <Text style={styles.label}>Window width: {Math.round(window.width)}pt</Text>
      <Text style={styles.label}>Content width: {layout ? `${Math.round(layout.width)}pt` : '…'}</Text>
      <Text style={styles.label}>Insets in the sheet: {fmt(sheetInsets)}</Text>
      <Text style={styles.label}>This red view should fill the sheet's width.</Text>
    </View>
  );
}

function Screen() {
  const [open, setOpen] = useState(false);
  const window = useWindowDimensions();
  const windowInsets = useSafeAreaInsets();

  return (
    <View
      style={styles.screen}
      onLayout={() => AUTORUN && !open && setTimeout(() => setOpen(true), 1500)}>
      <Text>window {Math.round(window.width)}x{Math.round(window.height)} insets {fmt(windowInsets)}</Text>
      <Button title="Open sheet" onPress={() => setOpen(true)} />
      <BottomSheet index={open ? 0 : -1} enablePanDownToClose onDismiss={() => setOpen(false)}>
        <SafeAreaProvider>
          <SheetContent window={window} />
        </SafeAreaProvider>
      </BottomSheet>
    </View>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <Screen />
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#fff', gap: 12 },
  content: { height: 200, backgroundColor: 'tomato', padding: 16, gap: 8 },
  label: { color: '#fff', fontSize: 16 },
});
