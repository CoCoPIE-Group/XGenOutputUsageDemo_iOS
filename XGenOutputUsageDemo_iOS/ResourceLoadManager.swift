//
//  ResourceLoadManager.swift
//  XGenOutputUsageDemo_iOS
//
//  Created by steven on 2023/1/22.
//

import Foundation
import Alamofire
import SwiftyJSON

class ResourceLoadManager {
    static let `default` = ResourceLoadManager()
    
    private(set) var localModel: AIModel!
    
    init() {
        localModel = readLocalModel()
    }
    
    private let session: Session = {
        let manager = ServerTrustManager(evaluators: ["xgen-install.cocopie.ai": DisabledTrustEvaluator()])
        let configuration = URLSessionConfiguration.af.default
        return Session(configuration: configuration, serverTrustManager: manager)
    }()
    
    private static let source = URL(string: "https://xgen-install.cocopie.ai/app/models.json")!
}

extension ResourceLoadManager {
    func readLocalModel() -> AIModel? {
        guard let labelURL = Bundle.main.url(forResource: "imagenet_labels_1000", withExtension: "json") else {
            print("local label load failed")
            return nil
        }
        
        guard let modelURL = Bundle.main.url(forResource: "efficientnet_b0_ra_3dd342df", withExtension: "fallback") else {
            print("local model load failed")
            return nil
        }
        
        let localAIModel = AIModel(name: "Local efficient", labelURL: labelURL, fallbackURL: modelURL, isLocal: true)
        return localAIModel
    }
    
    func requestList(completion: @escaping ([AIModel]?) -> Void) {
        session.request(Self.source, method: .get)
            .responseString(completionHandler: { string in
            print("load model list result: \n:\(string)")
        }).response(queue: .main) { response in
            guard let data = response.data else {
                completion(nil)
                return
            }
            
            guard let list = self.decodeList(from: data) else {
                completion(nil)
                return
            }
            
            completion(list)
            
            DispatchQueue.global().async {
                let url = self.listCacheURL
                try? FileManager.default.removeItem(at: url)
                try? data.write(to: url)
            }
        }
    }
    
    func getCachedList() -> [AIModel]? {
        let url = self.listCacheURL
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decodeList(from: data)
    }
    
    private func decodeList(from data: Data) -> [AIModel]? {
        guard let json = try? JSON(data: data), let list = json["samples"].array else { return nil }
        return list.compactMap { json in
            let model: AIModel? = json.mapObject()
            return model
        }
    }
}

extension ResourceLoadManager {
    func download(model: AIModel, completion: @escaping (Bool) -> Void) {
        guard !isAllFileDownloaded(for: model) else {
            DispatchQueue.main.async {
                completion(true)
            }
            return
        }
        
        clearDownloadedFile(for: model)
        
        let labelsDestination: DownloadRequest.Destination = { _, _ in
            let url = self.labelsCacheURl(for: model)
            return (url, [.removePreviousFile, .createIntermediateDirectories])
        }
        let fallbackDestination: DownloadRequest.Destination = { _, _ in
            let url = self.fallbackCacheURL(for: model)
            return (url, [.removePreviousFile, .createIntermediateDirectories])
        }

        session.download(model.labelURL, to: labelsDestination).response { response in
            debugPrint(response)
            
            guard response.error == nil, let url = response.fileURL, FileManager.default.fileExists(atPath: url.path) else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            self.session.download(model.fallbackURL, to: fallbackDestination).response { response in
                debugPrint(response)
                
                guard response.error == nil, let url = response.fileURL, FileManager.default.fileExists(atPath: url.path) else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }
    }
    
    func isAllFileDownloaded(for model: AIModel) -> Bool {
        let fileManager = FileManager.default
        
        guard !model.isLocal else {
            return fileManager.fileExists(atPath: model.labelURL.path)
            && fileManager.fileExists(atPath: model.fallbackURL.path)
        }
        
        let labelsPath = labelsCacheURl(for: model)
        let fallbackPath = fallbackCacheURL(for: model)
        return fileManager.fileExists(atPath: labelsPath.path) && fileManager.fileExists(atPath: fallbackPath.path)
    }
    
    func labelFileURL(for model: AIModel) -> URL {
        if model.isLocal {
            return model.labelURL
        } else {
            return labelsCacheURl(for: model)
        }
    }
    
    func fallbackFileURL(for model: AIModel) -> URL {
        if model.isLocal {
            return model.fallbackURL
        } else {
            return fallbackCacheURL(for: model)
        }
    }
    
    func clearDownloadedFile(for model: AIModel) {
        let paths = [
            labelsCacheURl(for: model),
            fallbackCacheURL(for: model)
        ]
        paths.forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
    }
}

private extension ResourceLoadManager {
    var documentDir: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var listCacheURL: URL {
        return documentDir.appendingPathComponent("list_cache")
    }
    
    func labelsCacheURl(for model: AIModel) -> URL {
        return documentDir.appendingPathComponent("\(model.name)_labelsCache")
    }
    
    func fallbackCacheURL(for model: AIModel) -> URL {
        return documentDir.appendingPathComponent("\(model.name)_fallbackCache")
    }
}

fileprivate extension JSON {
    func mapObject<T: Decodable>(keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> T? {
        let nodeJSON = self
        let raw: (data: Data?, value: T?) = nodeJSON.rawDataOrRawValue()
        guard let data = raw.data else { return raw.value }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error {
            print("data parse error:\(error)")
            return nil
        }
    }
    
    private func rawDataOrRawValue<T: Decodable>() -> (data: Data?, value: T?) {
        var data: Data?
        var value: T?
        do {
            data = try rawData()
        } catch let error {
            if case SwiftyJSONError.invalidJSON = error,
                let rawValue = rawValue as? T {
                value = rawValue
            } else {
                print("data parse error: get json.rawData error")
            }
        }
        return (data, value)
    }
}
