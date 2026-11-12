// Measures the sheet and its red content in an end-frame screenshot.
//   scripts/measure <png> <scale>
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
print("\(url.lastPathComponent): \(w)x\(h) px")
