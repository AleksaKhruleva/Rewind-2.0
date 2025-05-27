import SwiftUI

protocol LocalFileManagerProtocol {
    func saveImage(image: UIImage, url: String)
    func getImage(url: String) -> UIImage?
    func deleteImage(url: String)
    func clear()
}

public final class FileManagerImageStorage: LocalFileManagerProtocol {
    public static let shared = FileManagerImageStorage()

    private let folderName = "rewind-images"

    private init() { }

    public func saveImage(image: UIImage, url: String) {
        print(#function)
        let imageName = url.replacingOccurrences(of: "/", with: "_")
        createFolderIfNeeded(folderName: folderName)

        guard
            let data = image.pngData(),
            let url = getURLForImage(urlToArticle: imageName, folderName: folderName)
            else { return }

        do {
            print("SAVING IMAGE")
            try data.write(to: url)
            print("SAVED IMAGE")
        } catch let error {
            print("Error saving image: \(imageName). \(error)")
        }
    }

    public func getImage(url: String) -> UIImage? {
        print(#function)
        let imageName = url.replacingOccurrences(of: "/", with: "_")
        guard let url = getURLForImage(urlToArticle: imageName, folderName: folderName),
            FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        print("RETURNING IMAGE")
        return UIImage(contentsOfFile: url.path)
    }

    public func deleteImage(url: String) {
        let imageName = url.replacingOccurrences(of: "/", with: "_")
        guard let url = getURLForImage(urlToArticle: imageName, folderName: folderName),
            FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: url)
        } catch let error {
            print("Error deleting image: \(folderName). \(error)")
        }
    }

    public func clear() {
        guard let folderURL = getURLForFolder(folderName: folderName),
              FileManager.default.fileExists(atPath: folderURL.path) else {
            return
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            for url in fileURLs {
                try FileManager.default.removeItem(at: url)
            }
            print("Storage cleared.")
        } catch {
            print("Error clearing storage: \(error)")
        }
    }
}

extension FileManagerImageStorage {
    private func createFolderIfNeeded(folderName: String) {
        guard let url = getURLForFolder(folderName: folderName) else { return }

        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print("Error creating directory: \(folderName). \(error)")
            }
        }
    }

    private func getURLForFolder(folderName: String) -> URL? {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return url.appendingPathComponent(folderName)
    }

    private func getURLForImage(urlToArticle: String, folderName: String) -> URL? {
        let imageName = urlToArticle.replacingOccurrences(of: "/", with: "_")
        guard let folderURL = getURLForFolder(folderName: folderName) else {
            return nil
        }
        return folderURL.appendingPathComponent(imageName + ".png")
    }
}
