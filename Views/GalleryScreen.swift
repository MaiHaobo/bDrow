//
//  GalleryScreen.swift
//  bDrow
//
//  启动首页：作品画廊 + 从相册导入
//

import SwiftUI
import PhotosUI

struct GalleryScreen: View {
    @EnvironmentObject var store: DrawingStore

    @State private var openCanvas = false
    @State private var showImporter = false
    @State private var pickedItem: PhotosPickerItem?

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 10)]

    var body: some View {
        NavigationStack {
            Group {
                if store.artworks.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .navigationTitle("画廊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showImporter = true
                    } label: {
                        Image(systemName: "photo.badge.plus")
                    }
                    .accessibilityLabel("从相册导入")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.newCanvas()
                        openCanvas = true
                    } label: {
                        Label("新建", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $openCanvas) {
                DrawingScreen()
            }
            .photosPicker(isPresented: $showImporter,
                          selection: $pickedItem,
                          matching: .images)
            .onChange(of: pickedItem) { _, newItem in
                guard let newItem else { return }
                loadImport(newItem)
            }
            .overlay(alignment: .top) { toastView }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.artworks) { art in
                    artworkCell(art)
                }
            }
            .padding()
        }
    }

    private func artworkCell(_ art: Artwork) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let img = store.image(for: art) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray.opacity(0.15)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
            }
            .frame(height: 108)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if art.imported {
                Text("导入")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(6)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                store.delete(art)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("还没有作品")
                .font(.headline)
            Text("点右上角「+」新建一张，或点左上角从相册导入一张图片开始描摹")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button {
                store.newCanvas()
                openCanvas = true
            } label: {
                Label("新建画布", systemImage: "plus")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var toastView: some View {
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

    private func loadImport(_ item: PhotosPickerItem) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                await MainActor.run {
                    store.toast = "图片读取失败"
                    pickedItem = nil
                }
                return
            }
            await MainActor.run {
                store.newCanvas()
                store.importedBackground = image
                pickedItem = nil
                openCanvas = true
            }
        }
    }
}

#Preview {
    GalleryScreen()
        .environmentObject(DrawingStore())
}
