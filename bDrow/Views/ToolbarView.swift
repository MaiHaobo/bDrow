//
//  ToolbarView.swift
//  bDrow
//
//  底部浮动工具栏：工具切换、粗细、撤销、清空
//  低系统用毛玻璃，iOS 26+ 用液态玻璃
//

import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject var store: DrawingStore

    var body: some View {
        HStack(spacing: 6) {
            // 工具切换
            ForEach(DrawingTool.allCases) { tool in
                Button {
                    store.tool = tool
                } label: {
                    Image(systemName: tool.systemImage)
                        .font(.system(size: 19, weight: .medium))
                        .frame(width: 42, height: 42)
                        .foregroundStyle(store.tool == tool ? Color.accentColor : Color.primary)
                }
            }

            Divider().frame(height: 22)

            // 粗细图标（小）
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .foregroundStyle(.secondary)

            Slider(value: $store.lineWidth, in: 1...30)
                .frame(maxWidth: 110)
                .tint(store.color)

            // 粗细图标（大）
            Image(systemName: "circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            // 清除
            Button(role: .destructive) {
                store.clear()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 19, weight: .medium))
                    .frame(width: 42, height: 42)
            }
            .disabled(store.strokes.isEmpty)
        }
        .padding(.horizontal, 10)
        .frame(height: 58)
        .adaptiveGlassPill()          // ← 关键：自适应玻璃
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
}

// MARK: - 自适应玻璃外观

extension View {
    /// iOS 26+ 使用 Liquid Glass；低版本回退为系统毛玻璃材质
    @ViewBuilder
    func adaptiveGlassPill() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .capsule)
        } else {
            self
                .background(.ultraThinMaterial, in: .capsule)
                .overlay(
                    Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.white
        VStack {
            Spacer()
            ToolbarView()
                .environmentObject(DrawingStore())
        }
    }
}
