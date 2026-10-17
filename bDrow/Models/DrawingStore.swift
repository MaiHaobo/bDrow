//
//  DrawingStore.swift
//  bDrow
//
//  绘画数据模型 + 本地作品存储（App 沙盒）
//

import SwiftUI
import Combine
import Photos
import UIKit

/// 一笔（一条连续的笔迹）
struct Stroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
}

/// 绘画工具类型
enum DrawingTool: String, CaseIterable, Identifiable {
    case pen = "画笔"
    case eraser = "橡皮"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .pen: return "pencil.tip"
        case .eraser: return "eraser"
        }
    }
}

/// 画廊中的一件作品
struct Artwork: Identifiable, Codable {
    let id: UUID
    /// 文件名（存于 Documents/Artworks/）
    let fileName: String
    let createdAt: Date
    /// 由相册导入时为 true，用于角标区分
    let imported: Bool
}

/// 全局绘图数据仓库
final class DrawingStore: ObservableObject {

    // MARK: - 画布状态

    @Published var strokes: [Stroke] = []
    @Published var currentStroke: Stroke?
    @Published var color: Color = .black
    @Published var lineWidth: CGFloat = 4.0
    @Published var tool: DrawingTool = .pen

    /// 画布尺寸（用于导出渲染）
    @Published var canvasSize: CGSize = CGSize(width: 1024, height: 1024)

    /// 画廊作品（只含 App 内保存的）
    @Published var artworks: [Artwork] = []

    /// 从相册导入的底图
    @Published var importedBackground: UIImage?

    /// 提示信息
    @Published var toast: String?

    let palette: [Color] = [
        .black, .white, .red, .orange, .yellow,
        .green, .blue, .purple, .pink, .gray
    ]

    private let fileManager = FileManager.default
    private let artworksFolderName = "Artworks"
    private let indexFileName = "artworks.json"

    init() {
        loadArtworks()
    }

    // MARK: - 目录

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var artworksURL: URL {
        let url = documentsURL.appendingPathComponent(artworksFolderName, isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    private var indexURL: URL {
        artworksURL.appendingPathComponent(indexFileName)
    }

    // MARK: - 绘制操作

    func beginStroke(at point: CGPoint) {
        let strokeColor: Color = (tool == .eraser) ? .white : color
        let width: CGFloat = (tool == .eraser) ? lineWidth * 3 : lineWidth
        currentStroke = Stroke(points: [point], color: strokeColor, lineWidth: width)
    }

    func continueStroke(to point: CGPoint) {
        currentStroke?.points.append(point)
    }

    func endStroke() {
        if let stroke = currentStroke, stroke.points.count > 0 {
            strokes.append(stroke)
        }
        currentStroke = nil
    }

    func undo() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
    }

    func clear() {
        strokes.removeAll()
        currentStroke = nil
    }

    /// 新建空白画布
    func newCanvas() {
        strokes.removeAll()
        currentStroke = nil
        importedBackground = nil
    }

    // MARK: - 渲染

    /// 把当前画布渲染成 UIImage
    func renderImage() -> UIImage? {
        let size = canvasSize
        guard size.width > 0, size.height > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)
        let converted: [(points: [CGPoint], color: UIColor, width: CGFloat)] = strokes.map {
            (points: $0.points, color: UIColor($0.color), width: $0.lineWidth)
        }
        let background = importedBackground

        return renderer.image { ctx in
            if let bg = background {
                let scale = max(size.width / bg.size.width, size.height / bg.size.height)
                let w = bg.size.width * scale
                let h = bg.size.height * scale
                bg.draw(in: CGRect(x: (size.width - w) / 2,
                                   y: (size.height - h) / 2,
                                   width: w, height: h))
            } else {
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }

            for stroke in converted {
                guard let first = stroke.points.first else { continue }
                stroke.color.setStroke()

                if stroke.points.count == 1 {
                    let r = stroke.width / 2
                    let dot = UIBezierPath(ovalIn: CGRect(
                        x: first.x - r, y: first.y - r,
                        width: stroke.width, height: stroke.width
                    ))
                    stroke.color.setFill()
                    dot.fill()
                    continue
                }

                let path = UIBezierPath()
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.lineWidth = stroke.width
                path.move(to: first)

                for i in 1..<stroke.points.count {
                    let prev = stroke.points[i - 1]
                    let curr = stroke.points[i]
                    let mid = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
                    path.addQuadCurve(to: mid, controlPoint: prev)
                }
                if let last = stroke.points.last {
                    path.addLine(to: last)
                }
                path.stroke()
            }
        }
    }

    // MARK: - 保存到画廊

    /// 保存当前画布为画廊作品
    func saveArtwork(imported: Bool = false) {
        guard !strokes.isEmpty || importedBackground != nil else {
            toast = "画布还是空的"
            return
        }
        guard let image = renderImage(), let data = image.pngData() else {
            toast = "渲染失败"
            return
        }

        let id = UUID()
        let fileName = "\(id.uuidString).png"
        let fileURL = artworksURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            let item = Artwork(id: id,
                               fileName: fileName,
                               createdAt: Date(),
                               imported: imported)
            artworks.insert(item, at: 0)
            persistIndex()
            toast = "已保存到画廊"
        } catch {
            toast = "保存失败：\(error.localizedDescription)"
        }
    }

    /// 另存到系统相册
    func saveToPhotoLibrary() {
        guard let image = renderImage() else {
            toast = "渲染失败"
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { self.toast = "没有相册写入权限" }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    self.toast = success
                        ? "已保存到相册"
                        : "保存失败：\(error?.localizedDescription ?? "未知错误")"
                }
            }
        }
    }

    /// 读取作品图片
    func image(for artwork: Artwork) -> UIImage? {
        let url = artworksURL.appendingPathComponent(artwork.fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// 删除作品
    func delete(_ artwork: Artwork) {
        let url = artworksURL.appendingPathComponent(artwork.fileName)
        try? fileManager.removeItem(at: url)
        artworks.removeAll { $0.id == artwork.id }
        persistIndex()
        toast = "已删除"
    }

    // MARK: - 索引持久化

    private func persistIndex() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(artworks)
            try data.write(to: indexURL, options: .atomic)
        } catch {
            print("索引写入失败:", error)
        }
    }

    func loadArtworks() {
        guard fileManager.fileExists(atPath: indexURL.path) else {
            artworks = []
            return
        }
        do {
            let data = try Data(contentsOf: indexURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var list = try decoder.decode([Artwork].self, from: data)
            list = list.filter {
                fileManager.fileExists(atPath: artworksURL.appendingPathComponent($0.fileName).path)
            }
            artworks = list.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("索引读取失败:", error)
            artworks = []
        }
    }
}
