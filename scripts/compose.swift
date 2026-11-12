// Puts two captures side by side, with a label above each.
//   swift scripts/compose.swift image <left.png> <right.png> <out.png> <left label> <right label>
//   swift scripts/compose.swift video <left.mp4> <right.mp4> <out.mp4> <left label> <right label>
//   swift scripts/compose.swift gif   <left.mp4> <right.mp4> <out.gif> <left label> <right label> [fps] [scale]
//   swift scripts/compose.swift frames <video.mp4> <out dir> <fps> [scale]      one PNG per frame, named by ms
//   swift scripts/compose.swift strip <out.png> <row label> <scale> <img> <caption> [<img> <caption> ...]
//   swift scripts/compose.swift stack <top.png> <bottom.png> <out.png>          one above the other
//   swift scripts/compose.swift crop <in.png> <out.png> <x> <y> <w> <h>          in source pixels
//   swift scripts/compose.swift slowgif <left.mp4> <right.mp4> <out.gif> <left label> <right label> <left from s> <right from s> <duration s> <sample fps> <play fps> <scale>
//       a slowed-down side-by-side GIF of one window of each video
import AVFoundation
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let gap: CGFloat = 24
let labelHeight: CGFloat = 110

func loadImage(_ path: String) -> CGImage {
  guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("cannot read \(path)")
  }
  return image
}

func drawLabel(_ text: String, in rect: CGRect, context: CGContext, size: CGFloat = 64) {
  let font = CTFontCreateWithName("Helvetica-Bold" as CFString, size, nil)
  let attributes = [
    kCTFontAttributeName: font,
    kCTForegroundColorAttributeName: CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
  ] as CFDictionary
  let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, text as CFString, attributes))
  let bounds = CTLineGetBoundsWithOptions(line, [])
  context.textPosition = CGPoint(x: rect.midX - bounds.width / 2, y: rect.midY - bounds.height / 2 + 8)
  CTLineDraw(line, context)
}

func compose(_ left: CGImage, _ right: CGImage, labels: (String, String), scale: CGFloat = 1) -> CGImage {
  let width = CGFloat(left.width + right.width) + gap
  let height = CGFloat(max(left.height, right.height)) + labelHeight
  let outWidth = Int(width * scale), outHeight = Int(height * scale)
  let space = CGColorSpace(name: CGColorSpace.sRGB)!
  let context = CGContext(data: nil, width: outWidth, height: outHeight, bitsPerComponent: 8, bytesPerRow: 0,
                          space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  context.scaleBy(x: scale, y: scale)
  context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  let leftWidth = CGFloat(left.width)
  context.draw(left, in: CGRect(x: 0, y: 0, width: leftWidth, height: CGFloat(left.height)))
  context.draw(right, in: CGRect(x: leftWidth + gap, y: 0, width: CGFloat(right.width), height: CGFloat(right.height)))
  drawLabel(labels.0, in: CGRect(x: 0, y: height - labelHeight, width: leftWidth, height: labelHeight), context: context)
  drawLabel(labels.1, in: CGRect(x: leftWidth + gap, y: height - labelHeight, width: CGFloat(right.width), height: labelHeight), context: context)
  return context.makeImage()!
}

/// A copy of the image at the given scale.
func scaled(_ image: CGImage, by scale: CGFloat) -> CGImage {
  if scale == 1 { return image }
  let width = Int(CGFloat(image.width) * scale), height = Int(CGFloat(image.height) * scale)
  let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  context.interpolationQuality = .high
  context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
  return context.makeImage()!
}

func writeImage(_ image: CGImage, to path: String) {
  let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(destination, image, nil)
  CGImageDestinationFinalize(destination)
}

/// Frames of a video at a fixed rate.
func frames(of path: String, fps: Double, duration: Double) -> [CGImage] {
  let asset = AVURLAsset(url: URL(fileURLWithPath: path))
  let generator = AVAssetImageGenerator(asset: asset)
  generator.appliesPreferredTrackTransform = true
  generator.requestedTimeToleranceBefore = .zero
  generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5 / fps, preferredTimescale: 600)
  var result: [CGImage] = []
  var t = 0.0
  while t < duration {
    let time = CMTime(seconds: t, preferredTimescale: 600)
    if let image = try? generator.copyCGImage(at: time, actualTime: nil) {
      result.append(image)
    } else if let last = result.last {
      result.append(last)
    }
    t += 1 / fps
  }
  return result
}

func seconds(of path: String) -> Double {
  CMTimeGetSeconds(AVURLAsset(url: URL(fileURLWithPath: path)).duration)
}

func writeGif(_ images: [CGImage], fps: Double, to path: String) {
  let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.gif.identifier as CFString, images.count, nil)!
  CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
  for image in images {
    let props = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / fps]] as CFDictionary
    CGImageDestinationAddImage(destination, image, props)
  }
  CGImageDestinationFinalize(destination)
}

func writeVideo(_ images: [CGImage], fps: Double, to path: String) throws {
  try? FileManager.default.removeItem(atPath: path)
  let writer = try AVAssetWriter(outputURL: URL(fileURLWithPath: path), fileType: .mp4)
  let width = images[0].width, height = images[0].height
  let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height
  ])
  let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height
  ])
  writer.add(input)
  writer.startWriting()
  writer.startSession(atSourceTime: .zero)
  for (index, image) in images.enumerated() {
    while !input.isReadyForMoreMediaData { usleep(5000) }
    var buffer: CVPixelBuffer?
    CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32ARGB, nil, &buffer)
    guard let buffer else { fatalError("no pixel buffer") }
    CVPixelBufferLockBaseAddress(buffer, [])
    let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    CVPixelBufferUnlockBaseAddress(buffer, [])
    adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: CMTimeScale(fps)))
  }
  input.markAsFinished()
  let done = DispatchSemaphore(value: 0)
  writer.finishWriting { done.signal() }
  done.wait()
  if let error = writer.error { throw error }
}

/// A row of frames with a caption under each and a label above the row.
func strip(_ images: [CGImage], captions: [String], label: String, scale: CGFloat) -> CGImage {
  let captionHeight: CGFloat = 70
  let scaledImages = images.map { scaled($0, by: scale) }
  let cell = CGFloat(scaledImages.map(\.width).max()!)
  let imageHeight = CGFloat(scaledImages.map(\.height).max()!)
  let width = cell * CGFloat(images.count) + gap * CGFloat(images.count - 1)
  let height = imageHeight + labelHeight + captionHeight
  let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  for (index, image) in scaledImages.enumerated() {
    let x = CGFloat(index) * (cell + gap)
    context.draw(image, in: CGRect(x: x, y: captionHeight, width: CGFloat(image.width), height: CGFloat(image.height)))
    drawLabel(captions[index], in: CGRect(x: x, y: 0, width: cell, height: captionHeight), context: context, size: 40)
  }
  drawLabel(label, in: CGRect(x: 0, y: height - labelHeight, width: width, height: labelHeight), context: context)
  return context.makeImage()!
}

/// One image above the other, left aligned on a white background.
func stack(_ top: CGImage, _ bottom: CGImage) -> CGImage {
  let width = CGFloat(max(top.width, bottom.width))
  let height = CGFloat(top.height + bottom.height) + gap
  let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  context.draw(bottom, in: CGRect(x: 0, y: 0, width: CGFloat(bottom.width), height: CGFloat(bottom.height)))
  context.draw(top, in: CGRect(x: 0, y: CGFloat(bottom.height) + gap, width: CGFloat(top.width), height: CGFloat(top.height)))
  return context.makeImage()!
}

/// Frames of one window of a video at a fixed rate.
func frames(of path: String, from start: Double, duration: Double, fps: Double) -> [CGImage] {
  let asset = AVURLAsset(url: URL(fileURLWithPath: path))
  let generator = AVAssetImageGenerator(asset: asset)
  generator.appliesPreferredTrackTransform = true
  generator.requestedTimeToleranceBefore = .zero
  generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5 / fps, preferredTimescale: 600)
  var result: [CGImage] = []
  var t = start
  while t < start + duration {
    if let image = try? generator.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) {
      result.append(image)
    } else if let last = result.last {
      result.append(last)
    }
    t += 1 / fps
  }
  return result
}

let args = CommandLine.arguments
if args.count == 13, args[1] == "slowgif" {
  let (left, right, out) = (args[2], args[3], args[4])
  let labels = (args[5], args[6])
  let leftFrom = Double(args[7]) ?? 0, rightFrom = Double(args[8]) ?? 0, duration = Double(args[9]) ?? 1
  let sampleFps = Double(args[10]) ?? 60, playFps = Double(args[11]) ?? 15, scale = Double(args[12]) ?? 0.3
  let pairs = zip(frames(of: left, from: leftFrom, duration: duration, fps: sampleFps),
                  frames(of: right, from: rightFrom, duration: duration, fps: sampleFps))
  let composed = pairs.map { compose($0, $1, labels: labels, scale: CGFloat(scale)) }
  writeGif(composed, fps: playFps, to: out)
  print("wrote \(out) (\(composed.count) frames)"); exit(0)
}
if args.count == 8, args[1] == "crop" {
  let values = args[4...7].map { Int($0) ?? 0 }
  let rect = CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
  writeImage(loadImage(args[2]).cropping(to: rect)!, to: args[3])
  print("wrote \(args[3])"); exit(0)
}
if args.count >= 6, args[1] == "strip" {
  let pairs = stride(from: 5, to: args.count - 1, by: 2).map { (loadImage(args[$0]), args[$0 + 1]) }
  writeImage(strip(pairs.map(\.0), captions: pairs.map(\.1), label: args[3], scale: CGFloat(Double(args[4]) ?? 0.25)), to: args[2])
  print("wrote \(args[2])"); exit(0)
}
if args.count == 5, args[1] == "stack" {
  writeImage(stack(loadImage(args[2]), loadImage(args[3])), to: args[4])
  print("wrote \(args[4])"); exit(0)
}
if args.count >= 5, args[1] == "frames" {
  let fps = Double(args[4]) ?? 10
  let scale = args.count > 5 ? Double(args[5]) ?? 1 : 1
  try? FileManager.default.createDirectory(atPath: args[3], withIntermediateDirectories: true)
  for (index, frame) in frames(of: args[2], fps: fps, duration: seconds(of: args[2])).enumerated() {
    let ms = Int(Double(index) * 1000 / fps)
    writeImage(scaled(frame, by: CGFloat(scale)), to: String(format: "%@/f_%05d.png", args[3], ms))
  }
  print("wrote frames to \(args[3])"); exit(0)
}
guard args.count >= 7 else {
  print("usage: see header comment"); exit(2)
}
let mode = args[1], left = args[2], right = args[3], out = args[4]
let labels = (args[5], args[6])
switch mode {
case "image":
  writeImage(compose(loadImage(left), loadImage(right), labels: labels), to: out)
case "video", "gif":
  let fps = args.count > 7 ? Double(args[7]) ?? 10 : (mode == "gif" ? 8 : 20)
  let scale = args.count > 8 ? Double(args[8]) ?? 1 : (mode == "gif" ? 0.3 : 0.5)
  let duration = min(seconds(of: left), seconds(of: right))
  let pairs = zip(frames(of: left, fps: fps, duration: duration), frames(of: right, fps: fps, duration: duration))
  let composed = pairs.map { compose($0, $1, labels: labels, scale: CGFloat(scale)) }
  if mode == "gif" { writeGif(composed, fps: fps, to: out) } else { try writeVideo(composed, fps: fps, to: out) }
default:
  print("unknown mode \(mode)"); exit(2)
}
print("wrote \(out)")
