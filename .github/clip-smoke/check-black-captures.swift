import CoreGraphics
import Foundation
import ImageIO

struct TestRecord: Decodable { let attachments: [Attachment] }
struct Attachment: Decodable {
    let suggestedHumanReadableName: String
    let exportedFileName: String
    let isAssociatedWithFailure: Bool?
}

let wanted = ["qa-black-tap", "qa-black-up", "qa-black-down", "10-black-waiting"]
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let manifest = try JSONDecoder().decode([TestRecord].self, from: Data(contentsOf: directory.appendingPathComponent("manifest.json")))
var checked: Set<String> = []
for entry in manifest.flatMap(\.attachments) {
    guard entry.isAssociatedWithFailure != true,
          let label = wanted.first(where: { entry.suggestedHumanReadableName.hasPrefix($0 + "_") }) else { continue }
    let url = directory.appendingPathComponent(entry.exportedFileName)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("Invalid screenshot: " + label)
    }
    precondition(image.width == 1206 && image.height == 2622)
    var pixels = [UInt8](repeating: 0, count: image.width * image.height)
    pixels.withUnsafeMutableBytes { samples in
        let ctx = CGContext(data: samples.baseAddress, width: image.width, height: image.height,
                            bitsPerComponent: 8, bytesPerRow: image.width, space: CGColorSpaceCreateDeviceGray(),
                            bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
    }
    let brightest = pixels.max()!
    precondition(brightest < 6, "Unexpected app-owned volume drawing in \(label): brightness \(brightest)")
    print("No overlay in", label, "maximum grayscale", brightest)
    checked.insert(label)
}
precondition(checked == Set(wanted), "Missing black-screen captures: \(Set(wanted).subtracting(checked))")
