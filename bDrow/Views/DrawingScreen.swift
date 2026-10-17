//
//  DrawingScreen.swift
//  bDrow
//
//  主绘制界面：画布 + 工具栏
//

import SwiftUI

struct DrawingScreen: View {
    @EnvironmentObject var store: DrawingStore

    var body: some View {
        NavigationStack {
            CanvasView()
                .background(Color.white)
                .navigationTitle("bDrow")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { store.undo() } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .disabled(store.strokes.isEmpty)
                        .adaptiveGlassButton()          // 见 ④
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { store.clear() } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(store.strokes.isEmpty)
                        .adaptiveGlassButton()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    ToolbarView()
                }
        }
    }
}
