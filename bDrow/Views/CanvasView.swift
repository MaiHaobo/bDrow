//
//  CanvasView.swift
//  bDrow
//
//  可绘制画布：基于 SwiftUI Canvas + 拖拽手势
//

import SwiftUI

struct CanvasView: View {
    @EnvironmentObject var store: DrawingStore

    var body: some View {
        Canvas { context, size in
            // 绘制已完成的笔迹
            for stroke in store.strokes {
                draw(stroke, in: &context)
            }
            // 绘制当前正在画的笔迹
            if let current = store.currentStroke {
                draw(current, in: &context)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if store.currentStroke == nil {
                        store.beginStroke(at: value.location)
                    } else {
                        store.continueStroke(to: value.location)
                    }
                }
                .onEnded { _ in
                    store.endStroke()
                }
        )
    }

    /// 把一条笔迹渲染成平滑曲线
    private func draw(_ stroke: Stroke, in context: inout GraphicsContext) {
        guard let first = stroke.points.first else { return }

        var path = Path()
        path.move(to: first)

        if stroke.points.count == 1 {
            // 单点：画一个圆点
            let dot = Path(ellipseIn: CGRect(
                x: first.x - stroke.lineWidth / 2,
                y: first.y - stroke.lineWidth / 2,
                width: stroke.lineWidth,
                height: stroke.lineWidth
            ))
            context.fill(dot, with: .color(stroke.color))
            return
        }

        // 多点：用二次贝塞尔平滑连接
        for i in 1..<stroke.points.count {
            let prev = stroke.points[i - 1]
            let curr = stroke.points[i]
            let mid = CGPoint(x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2)
            path.addQuadCurve(to: mid, control: prev)
        }
        if let last = stroke.points.last {
            path.addLine(to: last)
        }

        context.stroke(
            path,
            with: .color(stroke.color),
            style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
        )
    }
}
