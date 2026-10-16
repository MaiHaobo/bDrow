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
        VStack(spacing: 0) {
            // 画布区域
            CanvasView()
                .background(Color.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // 工具栏
            ToolbarView()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    DrawingScreen()
        .environmentObject(DrawingStore())
}
