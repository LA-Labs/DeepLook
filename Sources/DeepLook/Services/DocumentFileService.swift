//  Copyright © 2019 la-labs. All rights reserved.

import Foundation

class DocumentFileService {
    
    static let fileManager = FileManager.default
    
    static func createNew(folder: String) throws -> URL {

        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let folderURL = documentDirectory.appendingPathComponent(folder)
            if !isFileExist(atPath: folderURL.path) {
                do {
                    try fileManager.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil)
                    return folderURL
                }catch {
                    throw error
                }
            }
            return folderURL
        }
        throw DocumentFileServiceError.documentDirectoryNotFound
    }
    
    static func isFileExist(atPath: String) -> Bool {
        return fileManager.fileExists(atPath: atPath)
    }
    
    static func save(image:Data, toURL:URL) throws {
        do {
            try image.write(to: toURL)
        }catch {
            throw error
        }
        
    }    
    
    static func store<T: Codable>(_ object: T, atPath: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            FileManager.default.createFile(atPath: atPath, contents: data, attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    static func load<T: Codable>(atPath: String) -> T {
        if let data = FileManager.default.contents(atPath: atPath) {
            let decoder = JSONDecoder()
            do {
                let model = try decoder.decode(T.self, from: data)
                return model
            } catch {
                fatalError(error.localizedDescription)
            }
        } else {
            fatalError("No data at \(atPath)!")
        }
    }
}
