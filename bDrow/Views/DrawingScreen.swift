//
//  DrawingScreen.swift
//  bDrow
//
//  主绘制界面：系统导航容器 + 底部浮动工具栏
//  低系统走传统外观，iOS 26+ 由系统自动渲染为 Liquid Glass
//

import SwiftUI

struct DrawingScreen: View {
    @EnvironmentObject var store: DrawingStore
    @State private var showPalette = false

    var body: some View {
        NavigationStack {
            CanvasView()
                .background(Color.white)
                .navigationTitle("bDrow")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            store.undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .disabled(store.strokes.isEmpty)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showPalette.toggle()
                        } label: {
                            Image(systemName: "paintpalette")
                        }
                    }
                }
                // 底部工具栏浮于画布之上，系统自动提供玻璃底座
                .safeAreaInset(edge: .bottom) {
                    ToolbarView()
                }
                // 调色面板以 sheet 形式出现，同样由系统接管外观
                .sheet(isPresented: $showPalette) {
                    PaletteSheet()
                        .presentationDetents([.height(220)])
                        .presentationDragIndicator(.visible)
                }
        }
    }
}

/// 调色面板：系统 sheet，iOS 26+ 自动为液态玻璃
struct PaletteSheet: View {
    @EnvironmentObject var store: DrawingStore
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 14)]

    var body: some View {
        VStack(spacing: 16) {
            Text("选择颜色")
                .font(.headline)
                .padding(.top, 8)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(store.palette.indices, id: \.self) { index in
                    let color = store.palette[index]
                    Circle()
                        .fill(color)
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle().stroke(
                                store.color == color ? Color.accentColor : Color.gray.opacity(0.35),
                                lineWidth: store.color == color ? 3 : 1
                            )
                        )
                        .contentShape(Circle())
                        .onTapGesture {
                            store.color = color
                            store.tool = .pen
                            dismiss()
                        }
                }
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    DrawingScreen()
        .environmentObject(DrawingStore())
}
