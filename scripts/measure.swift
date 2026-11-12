// Measures the sheet and its red content in an end-frame screenshot.
//   scripts/measure <png> <scale>
// Finds the rows that contain the red content, takes the row through its middle, and reports the
// horizontal extent of the sheet (the contiguous run of bright or red pixels around the content,
// everything else is dimmed by the sheet's backdrop) and of the red content, in points.
import Foundation
import CoreGraphics
import ImageIO

let args = CommandLine.arguments
let url = URL(fileURLWithPath: args[1])
let scale = Double(args[2]) ?? 3
guard let src = CGImageSourceCreateWithURL(url as CFURL, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
  print("cannot read \(args[1])"); exit(1)
}
let w = img.width, h = img.height
var data = [UInt8](repeating: 0, count: w * h * 4)
let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
func px(_ x: Int, _ y: Int) -> (Int, Int, Int) {
  let i = (y * w + x) * 4
  return (Int(data[i]), Int(data[i + 1]), Int(data[i + 2]))
}
func isRed(_ p: (Int, Int, Int)) -> Bool { p.0 > 200 && p.1 < 150 && p.2 < 130 }
func isBright(_ p: (Int, Int, Int)) -> Bool { p.0 > 225 && p.1 > 225 && p.2 > 225 }
var redRows: [Int] = []
for y in 0..<h {
  var count = 0
  for x in 0..<w where isRed(px(x, y)) { count += 1 }
  if count > w / 10 { redRows.append(y) }
}
guard let first = redRows.first, let last = redRows.last else { print("no red content found"); exit(1) }
let y = (first + last) / 2
var redMin = w, redMax = -1
for x in 0..<w where isRed(px(x, y)) { redMin = min(redMin, x); redMax = max(redMax, x) }
var sheetMin = redMin, sheetMax = redMax
while sheetMin > 0, isBright(px(sheetMin - 1, y)) || isRed(px(sheetMin - 1, y)) { sheetMin -= 1 }
while sheetMax < w - 1, isBright(px(sheetMax + 1, y)) || isRed(px(sheetMax + 1, y)) { sheetMax += 1 }
func pt(_ v: Int) -> String { String(format: "%.1f", Double(v) / scale) }
let shortLeft = redMin - sheetMin, shortRight = sheetMax - redMax
let verdict = (shortLeft <= Int(2 * scale) && shortRight <= Int(2 * scale)) ? "PASS" : "FAIL"
print("\(url.lastPathComponent): window \(pt(w))x\(pt(h)) pt, row y=\(pt(y)) pt, sheet x=\(pt(sheetMin))..\(pt(sheetMax + 1)) (\(pt(sheetMax + 1 - sheetMin)) pt), content x=\(pt(redMin))..\(pt(redMax + 1)) (\(pt(redMax + 1 - redMin)) pt), gap left \(pt(shortLeft)) pt, gap right \(pt(shortRight)) pt | \(verdict)")
