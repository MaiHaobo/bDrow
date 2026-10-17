//
//  DrawingStore.swift
//  bDrow
//
//  绘画数据模型 + 相册保存/读取
//

import SwiftUI
import Combine
import Photos

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

/// 画廊作品（来自系统相册）
struct Artwork: Identifiable {
    let id: String              // localIdentifier
    let image: UIImage
    let createdAt: Date
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

    /// 画廊数据
    @Published var artworks: [Artwork] = []
    @Published var isLoadingGallery = false

    /// 提示信息
    @Published var toast: String?

    let palette: [Color] = [
        .black, .white, .red, .orange, .yellow,
        .green, .blue, .purple, .pink, .gray
    ]

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

    /// 新建一张空白画布
    func newCanvas() {
        strokes.removeAll()
        currentStroke = nil
    }

    // MARK: - 渲染为图片

    /// 把当前笔迹渲染成 UIImage
    func renderImage(scale: CGFloat = 2.0) -> UIImage? {
        let size = canvasSize
        guard size.width > 0, size.height > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)

        // 先把 SwiftUI Color 转成 UIColor（需要在主线程访问）
        let converted: [(points: [CGPoint], color: UIColor, width: CGFloat)] = strokes.map {
            (points: $0.points, color: UIColor($0.color), width: $0.lineWidth)
        }

        return renderer.image { ctx in
            // 白色背景
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            for stroke in converted {
                guard let first = stroke.points.first else { continue }

                let path = UIBezierPath()
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.lineWidth = stroke.width
                stroke.color.setStroke()
                path.move(to: first)

                if stroke.points.count == 1 {
                    // 单点画圆
                    let r = stroke.width / 2
                    let dot = UIBezierPath(ovalIn: CGRect(
                        x: first.x - r, y: first.y - r,
                        width: stroke.width, height: stroke.width
                    ))
                    stroke.color.setFill()
                    dot.fill()
                    continue
                }

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

    // MARK: - 保存到相册

    /// 保存当前画布到系统相册
    func saveToPhotoLibrary() {
        guard !strokes.isEmpty else {
            toast = "画布还是空的"
            return
        }
        guard let image = renderImage() else {
            toast = "渲染失败"
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.toast = "没有相册写入权限"
                }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.toast = "已保存到相册"
                        self.loadGallery()
                    } else {
                        self.toast = "保存失败：\(error?.localizedDescription ?? "未知错误")"
                    }
                }
            }
        }
    }

    // MARK: - 读取画廊

    /// 从系统相册读取图片作为作品
    func loadGallery() {
        isLoadingGallery = true

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.isLoadingGallery = false
                    self.toast = "需要相册权限才能显示作品"
                }
                return
            }

            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = 200

            let result = PHAsset.fetchAssets(with: .image, options: options)
            let manager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .fast

            var items: [Artwork] = []
            result.enumerateObjects { asset, _, _ in
                let target = CGSize(width: 400, height: 400)
                manager.requestImage(
                    for: asset,
                    targetSize: target,
                    contentMode: .aspectFill,
                    options: requestOptions
                ) { image, _ in
                    if let image {
                        items.append(Artwork(
                            id: asset.localIdentifier,
                            image: image,
                            createdAt: asset.creationDate ?? Date()
                        ))
                    }
                }
            }

            DispatchQueue.main.async {
                self.artworks = items
                self.isLoadingGallery = false
            }
        }
    }
}
