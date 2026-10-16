//
//  DrawingStore.swift
//  bDrow
//
//  绘画数据模型：管理画笔、笔迹与画布状态
//

import SwiftUI
import Combine

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

/// 全局绘图数据仓库
final class DrawingStore: ObservableObject {

    /// 已完成的所有笔迹
    @Published var strokes: [Stroke] = []

    /// 当前正在绘制中的笔迹
    @Published var currentStroke: Stroke?

    /// 当前画笔颜色
    @Published var color: Color = .black

    /// 当前画笔粗细
    @Published var lineWidth: CGFloat = 4.0

    /// 当前选中的工具
    @Published var tool: DrawingTool = .pen

    /// 可选颜色面板
    let palette: [Color] = [
        .black, .white, .red, .orange, .yellow,
        .green, .blue, .purple, .pink, .gray
    ]

    // MARK: - 绘制操作

    /// 开始一笔
    func beginStroke(at point: CGPoint) {
        let strokeColor: Color = (tool == .eraser) ? .white : color
        let width: CGFloat = (tool == .eraser) ? lineWidth * 3 : lineWidth
        currentStroke = Stroke(points: [point], color: strokeColor, lineWidth: width)
    }

    /// 延续当前笔迹
    func continueStroke(to point: CGPoint) {
        currentStroke?.points.append(point)
    }

    /// 结束当前笔迹
    func endStroke() {
        if let stroke = currentStroke, stroke.points.count > 0 {
            strokes.append(stroke)
        }
        currentStroke = nil
    }

    /// 撤销上一笔
    func undo() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
    }

    /// 清空画布
    func clear() {
        strokes.removeAll()
        currentStroke = nil
    }
}
