import SwiftUI

/// Hanahuac's brand mark — a soft pastel globe ("one world") planted with a coral location pin.
/// Pure SwiftUI, no image asset; scales to its frame. Used on the home header and rendered into
/// the app icon.
struct HanahuacLogo: View {
    var showPin: Bool = true

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                GlobeMark()
                    .frame(width: s, height: s)
                if showPin {
                    MapPin()
                        .frame(width: s * 0.40, height: s * 0.52)
                        .shadow(color: Theme.cardShadow, radius: s * 0.025, y: s * 0.012)
                        .offset(y: -s * 0.06)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// The pastel wireframe globe (sphere + lat/long grid + highlight).
struct GlobeMark: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Palette.country, Theme.Palette.sea],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    GlobeGrid()
                        .stroke(Color.white.opacity(0.5), lineWidth: max(s * 0.016, 0.5))
                        .clipShape(Circle())
                )
                .overlay(
                    Circle().fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.35), .clear],
                            center: .topLeading, startRadius: 0, endRadius: s * 0.75
                        )
                    )
                )
                .overlay(Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: max(s * 0.02, 0.5)))
                .frame(width: s, height: s)
        }
    }
}

/// Latitude (parallels) + longitude (meridians) drawn with perspective-flattened ellipses.
private struct GlobeGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2

        // Parallels: equator + two flattened circles
        for dy in [CGFloat(0), r * 0.52, -r * 0.52] {
            let halfW = (r * r - dy * dy).squareRoot()
            let ry = max(halfW * 0.16, 0.5)
            p.addEllipse(in: CGRect(x: cx - halfW, y: cy + dy - ry, width: halfW * 2, height: ry * 2))
        }

        // Central meridian (vertical line) + one side meridian (ellipse)
        p.move(to: CGPoint(x: cx, y: cy - r))
        p.addLine(to: CGPoint(x: cx, y: cy + r))
        let mx = r * 0.5
        p.addEllipse(in: CGRect(x: cx - mx, y: cy - r, width: mx * 2, height: r * 2))

        return p
    }
}

/// A classic map pin: round head with a white center dot, tapering to a point.
struct MapPin: View {
    var color: Color = Theme.Palette.accent

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let head = w
            ZStack(alignment: .top) {
                DownTriangle()
                    .fill(color)
                    .frame(width: w * 0.60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, head * 0.46)
                Circle()
                    .fill(color)
                    .frame(width: head, height: head)
                Circle()
                    .fill(Theme.Palette.surface)
                    .frame(width: head * 0.38, height: head * 0.38)
                    .padding(.top, head * 0.31)
            }
        }
    }
}

/// Downward-pointing triangle (pin tip).
private struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// The wordmark used in the home header: the logo + "Hanahuac" + tagline.
struct HanahuacWordmark: View {
    var body: some View {
        HStack(spacing: 14) {
            HanahuacLogo()
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("Hanahuac")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(L10n["home.tagline"])
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 40) {
        HanahuacLogo().frame(width: 160, height: 160)
        HanahuacWordmark()
    }
    .padding()
    .background(Theme.Palette.canvas)
}
