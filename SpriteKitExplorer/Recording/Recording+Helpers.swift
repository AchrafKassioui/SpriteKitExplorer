//
//  SaveToDisk.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 27/11/2024.
//

import SpriteKit

func saveTextureToDisk(_ texture: SKTexture) {
    DispatchQueue.global(qos: .background).async {
        let image = UIImage(cgImage: texture.cgImage())
        guard let data = image.pngData() else {
            print("Failed to generate PNG data.")
            return
        }
        
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        /// Ensure directory exists
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create directory: \(error.localizedDescription)")
                return
            }
        }
        
        /// Generate file URL
        let fileURL = directory.appendingPathComponent("snapshotView_\(UUID().uuidString).png")
        
        do {
            try data.write(to: fileURL, options: .atomic)
            print("Snapshot saved to \(fileURL)")
        } catch {
            print("Failed to save snapshot: \(error.localizedDescription)")
        }
    }
}

func saveImageToDisk(_ image: UIImage) {
    DispatchQueue.global(qos: .background).async {
        guard let data = image.pngData() else {
            print("Failed to generate PNG data.")
            return
        }
        
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("No directory")
            return
        }
        let fileURL = directory.appendingPathComponent("snapshotView_\(UUID().uuidString).png")
        
        do {
            try data.write(to: fileURL)
            print("Snapshot saved to \(fileURL)")
        } catch {
            print("Failed to save snapshot: \(error)")
        }
    }
}
