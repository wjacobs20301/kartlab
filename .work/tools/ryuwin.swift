import CoreGraphics
// Prints the window id of the largest on-screen Ryujinx window (for screencapture -l).
let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as! [[String: Any]]
var best = 0, area = 0.0
for w in list where (w[kCGWindowOwnerName as String] as? String) == "Ryujinx" {
    if let b = w[kCGWindowBounds as String] as? [String: Double], let n = w[kCGWindowNumber as String] as? Int {
        let a = (b["Width"] ?? 0) * (b["Height"] ?? 0); if a > area { area = a; best = n }
    }
}
print(best)
