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
            ZStack {
                Color.white
                // 从相册导入的底图
                if let bg = store.importedBackground {
                    Image(uiImage: bg)
                        .resizable()
                        .scaledToFill()
                        .opacity(0.9)
                        .allowsHitTesting(false)
                }
                CanvasView()
            }
            .onAppear {
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
                    // 保存到画廊
                    Button {
                        store.saveArtwork(imported: store.importedBackground != nil)
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .disabled(store.strokes.isEmpty && store.importedBackground == nil)

                    // 调色
                    Button {
                        showPalette.toggle()
                    } label: {
                        Image(systemName: "paintpalette")
                    }

                    // 更多
                    Menu {
                        Button {
                            store.saveToPhotoLibrary()
                        } label: {
                            Label("另存到系统相册", systemImage: "photo")
                        }
                        Button(role: .destructive) {
                            store.clear()
                        } label: {
                            Label("清空画布", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            ToolbarView()
        }
        .sheet(isPresented: $showPalette) {
            PaletteSheet()
                .presentationDetents([.height(240)])
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
