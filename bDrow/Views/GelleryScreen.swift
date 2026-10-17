//
//  GalleryScreen.swift
//  bDrow
//
//  启动首页：相册作品画廊
//

import SwiftUI
import Photos

struct GalleryScreen: View {
    @EnvironmentObject var store: DrawingStore
    @State private var openCanvas = false

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoadingGallery {
                    ProgressView("正在读取相册…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.artworks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(store.artworks) { art in
                                Image(uiImage: art.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("画廊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.newCanvas()
                        openCanvas = true
                    } label: {
                        Label("新建", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.loadGallery()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .navigationDestination(isPresented: $openCanvas) {
                DrawingScreen()
            }
            .task {
                store.loadGallery()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("还没有作品")
                .font(.headline)
            Text("点击右上角「+」新建一张画，保存后会出现在这里")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    GalleryScreen()
        .environmentObject(DrawingStore())
}
