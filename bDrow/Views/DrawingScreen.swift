//
//  DrawingScreen.swift
//  bDrow
//
//  主绘制界面：系统导航容器 + 底部浮动工具栏
//

import SwiftUI

struct DrawingScreen: View {
    @EnvironmentObject var store: DrawingStore
    @State private var showPalette = false

    var body: some View {
        GeometryReader { geo in
            CanvasView()
                .background(Color.white)
                .onAppear {
                    // 记录画布实际像素尺寸（按 2x 渲染，便于导出清晰图片）
                    store.canvasSize = CGSize(
                        width: max(1, geo.size.width * 2),
                        height: max(1, geo.size.height * 2)
                    )
                }
        }
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
                HStack(spacing: 14) {
                    Button {
                        store.saveToPhotoLibrary()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .disabled(store.strokes.isEmpty)

                    Button {
                        showPalette.toggle()
                    } label: {
                        Image(systemName: "paintpalette")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            ToolbarView()
        }
        .sheet(isPresented: $showPalette) {
            PaletteSheet()
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) {
            if let toast = store.toast {
                Text(toast)
                    .font(.footnote)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(nanoseconds: 1_800_000_000)
                        withAnimation { store.toast = nil }
                    }
            }
        }
    }
}

/// 调色面板
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
    NavigationStack {
        DrawingScreen()
            .environmentObject(DrawingStore())
    }
}
