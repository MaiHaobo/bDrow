//
//  ToolbarView.swift
//  bDrow
//
//  底部工具栏：工具切换、调色板、粗细、撤销、清空
//

import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject var store: DrawingStore

    var body: some View {
        VStack(spacing: 12) {
            // 颜色调色板
            HStack(spacing: 12) {
                ForEach(store.palette.indices, id: \.self) { index in
                    let color = store.palette[index]
                    Circle()
                        .fill(color)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle().stroke(
                                store.color == color ? Color.accentColor : Color.gray.opacity(0.35),
                                lineWidth: store.color == color ? 3 : 1
                            )
                        )
                        .onTapGesture {
                            store.color = color
                            store.tool = .pen
                        }
                }
            }
            .padding(.top, 10)

            HStack(spacing: 20) {
                // 工具切换
                ForEach(DrawingTool.allCases) { tool in
                    Button {
                        store.tool = tool
                    } label: {
                        Image(systemName: tool.systemImage)
                            .font(.system(size: 20))
                            .foregroundStyle(store.tool == tool ? Color.accentColor : .primary)
                    }
                }

                Divider().frame(height: 24)

                // 粗细滑块
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                Slider(value: $store.lineWidth, in: 1...30)
                    .frame(maxWidth: 140)
                Image(systemName: "circle.fill")
                    .font(.system(size: 16))

                Divider().frame(height: 24)

                // 撤销
                Button {
                    store.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 20))
                }
                .disabled(store.strokes.isEmpty)

                // 清空
                Button(role: .destructive) {
                    store.clear()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                }
                .disabled(store.strokes.isEmpty)
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal)
        .background(.bar)
    }
}

#Preview {
    ToolbarView()
        .environmentObject(DrawingStore())
}
