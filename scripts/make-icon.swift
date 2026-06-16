// Renders the Hanahuac app icon (1024×1024, opaque PNG) from the SwiftUI brand mark.
// Run via `just icon` (which provides the Xcode toolchain). Output: the AppIcon asset PNG.
//
// The icon view is self-contained here (it can't import the app module), but mirrors
// Hanahuac/Views/Brand/HanahuacLogo.swift and Hanahuac/Theme.swift.

import CoreGraphics
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Palette (mirror of Theme.Palette)

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum P {
    static let canvas = Color(hex: 0xFBF7F0)
    static let sand = Color(hex: 0xF0E1CF)
    static let country = Color(hex: 0x7E97D6)
    static let sea = Color(hex: 0x4FB6A4)
    static let accent = Color(hex: 0xE0917F)
    static let surface = Color(hex: 0xFFFFFF)
}

// MARK: - Shapes (mirror of GlobeGrid / MapPin)

struct GlobeGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        for dy in [CGFloat(0), r * 0.52, -r * 0.52] {
            let halfW = (r * r - dy * dy).squareRoot()
            let ry = max(halfW * 0.16, 0.5)
            p.addEllipse(in: CGRect(x: cx - halfW, y: cy + dy - ry, width: halfW * 2, height: ry * 2))
        }
        p.move(to: CGPoint(x: cx, y: cy - r))
        p.addLine(to: CGPoint(x: cx, y: cy + r))
        let mx = r * 0.5
        p.addEllipse(in: CGRect(x: cx - mx, y: cy - r, width: mx * 2, height: r * 2))
        return p
    }
}

struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct IconView: View {
    let s: CGFloat = 1024
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [P.canvas, P.sand],
                startPoint: .top,
                endPoint: .bottom
            )

            // Globe
            let g = s * 0.62
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [P.country, P.sea],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                GlobeGrid()
                    .stroke(Color.white.opacity(0.5), lineWidth: g * 0.016)
                    .clipShape(Circle())
                Circle().fill(RadialGradient(
                    colors: [Color.white.opacity(0.35), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: g * 0.75
                ))
                Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: g * 0.02)
            }
            .frame(width: g, height: g)
            .shadow(color: Color(hex: 0x6B5B47).opacity(0.18), radius: g * 0.04, y: g * 0.02)
            .offset(y: s * 0.02)

            // Pin
            let pw = s * 0.26
            ZStack(alignment: .top) {
                DownTriangle().fill(P.accent).frame(width: pw * 0.60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, pw * 0.46)
                Circle().fill(P.accent).frame(width: pw, height: pw)
                Circle().fill(P.surface).frame(width: pw * 0.38, height: pw * 0.38)
                    .padding(.top, pw * 0.31)
            }
            .frame(width: pw, height: pw * 1.3)
            .shadow(color: Color(hex: 0x6B5B47).opacity(0.22), radius: s * 0.012, y: s * 0.008)
            .offset(x: s * 0.10, y: -s * 0.10)
        }
        .frame(width: s, height: s)
    }
}

// MARK: - Render

@MainActor
func render(to path: String) {
    let renderer = ImageRenderer(content: IconView())
    renderer.scale = 1
    guard let cg = renderer.cgImage else {
        FileHandle.standardError.write("ERROR: ImageRenderer produced no image\n".data(using: .utf8)!)
        exit(1)
    }
    // Flatten onto an opaque context (app icons must not have an alpha channel).
    let w = cg.width, h = cg.height
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: w,
        height: h,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        FileHandle.standardError.write("ERROR: could not create context\n".data(using: .utf8)!)
        exit(1)
    }
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    guard let flat = ctx.makeImage() else { exit(1) }

    let url = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        exit(1)
    }
    CGImageDestinationAddImage(dest, flat, nil)
    if CGImageDestinationFinalize(dest) {
        print("Wrote icon: \(path) (\(w)x\(h))")
    } else {
        exit(1)
    }
}

let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Hanahuac/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
DispatchQueue.main.async { render(to: outPath) }
RunLoop.main.run(until: Date().addingTimeInterval(3))
