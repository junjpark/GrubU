//
//  CachedRemoteImage.swift
//
//  In-memory + URLCache-backed remote images (SwiftUI AsyncImage does not reuse decoded bitmaps reliably).
//
//  Created by Julie Baguio on 4/20/26.
//

import SwiftUI
import UIKit

enum RestaurantImageCache {
    private static let memoryCache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 200
        c.totalCostLimit = 80 * 1024 * 1024
        return c
    }()

    /// Larger HTTP cache so Firebase Storage URLs hit disk when memory evicts.
    static func warmConfigureURLSessionDefaults() {
        let urlCache = URLCache.shared
        if urlCache.memoryCapacity < 40 * 1024 * 1024 {
            urlCache.memoryCapacity = 50 * 1024 * 1024
            urlCache.diskCapacity = 250 * 1024 * 1024
        }
    }

    static func cachedUIImage(for url: URL) -> UIImage? {
        memoryCache.object(forKey: url.absoluteString as NSString)
    }

    static func store(_ image: UIImage, for url: URL) {
        memoryCache.setObject(image, forKey: url.absoluteString as NSString)
    }
}

/// Loads restaurant (or any HTTPS) images once, then serves from memory + `URLCache`.
struct CachedRemoteImageView: View {
    let urlString: String?
    let height: CGFloat
    var cornerRadius: CGFloat = 14

    @State private var loadedImage: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let loadedImage {
                // UIImage-backed views keep the bitmap's intrinsic width unless compressed with minWidth: 0;
                // otherwise ScrollView content can become wider than the screen and clip sibling rows.
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
            } else if didFail || normalizedURL == nil {
                heroPlaceholder
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
            } else {
                ZStack {
                    Color(.systemGray5).opacity(0.4)
                    ProgressView()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: height)
                .clipped()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .modifier(ConditionalCornerClip(radius: cornerRadius))
        .task(id: urlString) {
            await loadRemoteImage()
        }
    }

    private var normalizedURL: URL? {
        guard let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw) else { return nil }
        return url
    }

    private var heroPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.surfaceBackground,
                    Color(.systemGray6).opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "fork.knife")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary.opacity(0.5))
        }
    }

    @MainActor
    private func loadRemoteImage() async {
        loadedImage = nil
        didFail = false

        guard let url = normalizedURL else {
            didFail = true
            return
        }

        if let mem = RestaurantImageCache.cachedUIImage(for: url) {
            loadedImage = mem
            return
        }

        do {
            var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            request.timeoutInterval = 45
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let ui = UIImage(data: data) else {
                didFail = true
                return
            }
            RestaurantImageCache.store(ui, for: url)
            loadedImage = ui
        } catch {
            didFail = true
        }
    }
}

private struct ConditionalCornerClip: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        Group {
            if radius > 0.5 {
                content.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            } else {
                content
            }
        }
    }
}
