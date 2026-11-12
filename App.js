import { useEffect, useRef, useState } from 'react';
import { Button, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
import { SafeAreaProvider, useSafeAreaInsets } from 'react-native-safe-area-context';
import { BottomSheet } from '@expo/ui/community/bottom-sheet';

// Repro for expo/expo#53369: the community BottomSheet's content stops short of the sheet edge
// when the window has a horizontal safe-area inset (iPhone Duo folded, side rail on the right).
// With AUTORUN the sheet opens by itself 1.5 s after launch and one RESULT line is printed with
// the window size, the window insets, the content size and the insets a SafeAreaProvider inside
// the sheet reports for the hosted content.
const AUTORUN = true;

function fmt(i) {
  return `t${Math.round(i.top)} r${Math.round(i.right)} b${Math.round(i.bottom)} l${Math.round(i.left)}`;
}

function SheetContent({ window, windowInsets, onMeasure }) {
  const sheetInsets = useSafeAreaInsets();
  const [layout, setLayout] = useState(null);
  const latest = useRef({ layout: null, sheetInsets });
  latest.current.sheetInsets = sheetInsets;
  const onLayout = (e) => {
    setLayout(e.nativeEvent.layout);
    latest.current.layout = e.nativeEvent.layout;
  };
  // Report once the layout and the inner provider's insets have settled (the provider first
  // reports the window's insets, then the ones of the view inside the sheet).
  useEffect(() => {
    const id = setTimeout(() => {
      const { layout: l, sheetInsets: si } = latest.current;
      if (!l) return;
      const short = Math.round(window.width - l.width);
      const line =
        `RESULT window=${Math.round(window.width)}x${Math.round(window.height)} ` +
        `windowInsets=${fmt(windowInsets)} content=${Math.round(l.width)}x${Math.round(l.height)} ` +
        `short=${short}pt sheetInsets=${fmt(si)} | ${short <= 1 ? 'PASS' : 'FAIL'}`;
      console.log(line);
      onMeasure(line);
    }, 3000);
    return () => clearTimeout(id);
  }, []);
  return (
    <View style={styles.content} onLayout={onLayout}>
      <Text style={styles.label}>Window width: {Math.round(window.width)}pt</Text>
      <Text style={styles.label}>Content width: {layout ? `${Math.round(layout.width)}pt` : '…'}</Text>
      <Text style={styles.label}>Insets in the sheet: {fmt(sheetInsets)}</Text>
      <Text style={styles.label}>This red view should fill the sheet's width.</Text>
    </View>
  );
}

function Screen() {
  const [open, setOpen] = useState(false);
  const [result, setResult] = useState('');
  const window = useWindowDimensions();
  const windowInsets = useSafeAreaInsets();

  return (
    <View
      style={styles.screen}
      onLayout={() => AUTORUN && !open && setTimeout(() => setOpen(true), 1500)}>
      <Text>window {Math.round(window.width)}x{Math.round(window.height)} insets {fmt(windowInsets)}</Text>
      <Button title="Open sheet" onPress={() => setOpen(true)} />
      <Text style={styles.result}>{result}</Text>
      <BottomSheet index={open ? 0 : -1} enablePanDownToClose onDismiss={() => setOpen(false)}>
        <SafeAreaProvider>
          <SheetContent window={window} windowInsets={windowInsets} onMeasure={setResult} />
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
  result: { fontSize: 11, paddingHorizontal: 12, textAlign: 'center' },
  content: { height: 200, backgroundColor: 'tomato', padding: 16, gap: 8 },
  label: { color: '#fff', fontSize: 16 },
});
