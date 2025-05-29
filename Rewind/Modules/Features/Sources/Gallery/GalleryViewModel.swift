import SwiftUI
import PhotosUI
import Base
import Domain
import UIComponents
import Networking

@MainActor @Observable
final class GalleryViewModel {
    enum Intent {
        case viewGallery
        case showMediasDialog
        case selectOneMedia(PhotosPickerItem)
        case viewBlurredMedia(GalleryItem)
        case openFilters

        case fetchGallery
        case addMedia(LoadedMedia)
        case deleteMedia(GalleryItem)

        case likeMedia(GalleryItem)
        case unlikeMedia(GalleryItem)

        case loadGroupImage
    }

    private(set) var progressMessage = ""

    var currentGroup: CurrentGroupInfo {
        GroupStorage.currentGroup ?? CurrentGroupInfo(id: -1, name: "Anonymous", imageURL: "")
    }
    var isLoading = false

    var mediaPickerPresented: Bool = false
    var mediaSelection: PhotosPickerItem?

    var mediaUploadingDialogShown: Bool = false
    var uploadingMedia: LoadedMedia?

    var filterSettingsShown = false
    var blurredMediaShown = false
    var blurredMediaSelection: GalleryItem?

    var currentFilters = FilterSettings()

    var showToast: (String) -> Void

    private(set) var groupImage: UIImage = DomainAsset.groupPlaceholder.image
    private(set) var galleryItems = [GalleryItem]() {
        didSet {
            filteredGalleryItems = galleryItems
        }
    }
    private(set) var filteredGalleryItems = [GalleryItem]()
    var gallery: [GalleryItem] {
        currentFilters.areDefault ? galleryItems : filteredGalleryItems
    }

    private let transformer: PhotosPickerItemTransformer

    var viewingBlurredMedia: GalleryItem? {
        guard let blurredMediaSelection, blurredMediaShown else {
            return nil
        }
        return blurredMediaSelection
    }

    let backend: NetworkService
    let soundCloudBackend: SoundCloudServiceProtocol
    let videoExporter: VideoExporter

    init() {
        transformer = .init()
        showToast = { _ in }

        galleryItems = []
        backend = NetworkService()
        soundCloudBackend = SoundCloudNetworkService()
        videoExporter = VideoExporter()
    }

    func dispatch(_ intent: Intent, onSuccess: @escaping () -> Void = {}) async {
        switch intent {
        case .viewGallery:
            if mediaSelection != nil { mediaSelection = nil }
            mediaPickerPresented = true
        case .showMediasDialog:
            mediaUploadingDialogShown = true
        case let .selectOneMedia(item):
            isLoading = true
            progressMessage = "Preparing media..."
            defer {
                isLoading = false
            }
            do {
                let media = try await self.transformer.transform(source: item)
                uploadingMedia = media
            } catch {
                showToast(UIComponentsStrings.MediaUpload.error)
            }
        case var .viewBlurredMedia(galleryItem):
            if let trackInfo = galleryItem.memory.trackInfo {
                do {
                    let response = try await soundCloudBackend.fetchTrack(by: trackInfo.id)
                    var lightTrack = response.toLightTrack(with: trackInfo)

                    if let streamURL = try await soundCloudBackend.fetchStreamURL(for: lightTrack) {
                        lightTrack.streamURL = streamURL
                    } else {
                        showToast("Couldn't get track stream URL.")
                    }

                    galleryItem.memory.lightTrack = lightTrack
                } catch {
                    showToast("Couldn't download music :( Try again later!")
                }
            }
            withAnimation {
                blurredMediaSelection = galleryItem
                blurredMediaShown = true
            }
        case .openFilters:
            filterSettingsShown = true
        case let .addMedia(loadedMedia):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    switch loadedMedia.content {
                    case let .image(image):
                        let response = try await backend.addMedia(
                            tokens: tokens,
                            groupId: groupId,
                            mediaType: "image",
                            mediaFile: .image(image),
                            latitude: loadedMedia.coordinates?.latitude,
                            longitude: loadedMedia.coordinates?.longitude,
                            musicId: loadedMedia.trackInfo?.id,
                            offset: loadedMedia.trackInfo?.startTime,
                            duration: loadedMedia.trackInfo?.duration,
                            tags: loadedMedia.tags ?? []
                        )
                        withAnimation {
                            onSuccess()
                            galleryItems = [
                                GalleryItem(
                                    isFavourite: false,
                                    tags: loadedMedia.tags?.map { $0.tag } ?? [],
                                    memory: response.toMediaItem()
                                )
                            ] + galleryItems
                        }
                    case .video:
                        progressMessage = "Uploading video..."
                        isLoading = true
                        defer {
                            isLoading = false
                        }
                        guard let settings = loadedMedia.videoEditingSettings else {
                            showToast(UIComponentsStrings.Toast.error)
                            return
                        }
                        let exported = try await videoExporter.export(
                            from: loadedMedia,
                            options: settings
                        )
                        guard case let .video(videoURL, _) = exported.content else { return }
                        let response = try await backend.addMedia(
                            tokens: tokens,
                            groupId: groupId,
                            mediaType: "video",
                            mediaFile: .video(videoURL),
                            latitude: loadedMedia.coordinates?.latitude,
                            longitude: loadedMedia.coordinates?.longitude,
                            musicId: loadedMedia.trackInfo?.id,
                            offset: loadedMedia.trackInfo?.startTime,
                            duration: loadedMedia.trackInfo?.duration,
                            tags: loadedMedia.tags ?? []
                        )
                        withAnimation {
                            onSuccess()
                            galleryItems = [
                                GalleryItem(
                                    isFavourite: false,
                                    tags: loadedMedia.tags?.map { $0.tag } ?? [],
                                    memory: response.toMediaItem()
                                )
                            ] + galleryItems
                        }
                    }
                }
            } catch let error as HTTPError where error == .payloadTooLarge {
                showToast("Media was too big and we couldn't upload it :(")
            } catch {
                print("VIDEO ERROR: \(error)")
                showToast(UIComponentsStrings.Toast.error)
            }
        case .fetchGallery:
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    let response = try await backend.getMedias(tokens: tokens, groupId: groupId)
                    withAnimation {
                        galleryItems = response.memories?.map {
                            return $0.toGalleryItem()
                        } ?? []
                    }
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .deleteMedia(galleryItem):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    let response = try await backend.deleteMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id
                    )
                    if response.success {
                        withAnimation {
                            onSuccess()
                            galleryItems.removeAll { $0.id == galleryItem.id }
                        }
                    }
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .likeMedia(galleryItem):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    _ = try await backend.likeMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id
                    )
                    if let index = galleryItems.firstIndex(where: { $0.id == galleryItem.id }) {
                        galleryItems[index].isFavourite = true
                    }
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .unlikeMedia(galleryItem):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    _ = try await backend.unlikeMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id
                    )
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case .loadGroupImage:
            await loadGroupImage()
        }
    }

    private func loadGroupImage() async {
        guard let currentGroup = GroupStorage.currentGroup else {
            // TODO: handle nil group
            return
        }
        let image = await ImageProvider.loadOrGetImage(
            for: currentGroup.imageURL, .group
        )
        await MainActor.run { [weak self] in
            self?.groupImage = image
        }
    }

    public func filterGallery() {
        filteredGalleryItems = galleryItems
            .filter {
                $0.memory.mediaType == .image && currentFilters.photos ||
                $0.memory.mediaType == .video && currentFilters.videos ||
                $0.memory.mediaType == .quote && currentFilters.quotes
            }
            .filter {
                if let onlyFavourites = currentFilters.favourites {
                    return $0.isFavourite == onlyFavourites
                }
                return true
            }
            .filter {
                var greaterStartDate = true
                var lessEndDate = true
                if let date = $0.memory.createdAt.toDate() {
                    if let startDate = currentFilters.startDate?.toDate() {
                        greaterStartDate = date >= startDate
                    }
                    if let endDate = currentFilters.endDate?.toDate() {
                        lessEndDate = date <= endDate
                    }
                }
                return greaterStartDate && lessEndDate
            }
            .filter {
                guard let tags = currentFilters.tags, !tags.isEmpty else {
                    return true
                }
                return !Set($0.tags).isDisjoint(with: tags)
            }
    }

    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }
}
