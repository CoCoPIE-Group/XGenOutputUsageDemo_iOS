//
//  HomeViewController.swift
//  XGenOutputUsageDemo_iOS
//
//  Created by steven on 2023/1/2.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet var outputLabel: UILabel!
    @IBOutlet var outputLabelBackground: UIView!
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var loopCountTextField: UITextField!
    @IBOutlet var choosePhotoButton: UIButton!
    
    @IBOutlet var modelNameLabel: UILabel!
    @IBOutlet var modelListContainer: UIView!
    
    @IBOutlet var downloadingView: UIView!
    
    private var loopCount = 1
    private let imageWidth: CGFloat = 224
    private let imageHeight: CGFloat = 224
    private let imageChannel = 3
    private let modelMean: [Float] = [0.485, 0.456, 0.406]
    private let modelStd: [Float] = [0.229, 0.224, 0.225]
    
    private var modelList: [AIModel] = []
    private var currentModel: AIModel? {
        didSet {
            modelNameLabel.text = currentModel?.name
        }
    }
    
    private var resourceManager: ResourceLoadManager {
        ResourceLoadManager.default
    }
    
    private var xgenEngine: XGenEngine?
    private var labels: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "CoCoPIEApiExample"
        
        outputLabelBackground.layer.cornerRadius = 10
        choosePhotoButton.layer.cornerRadius = 10
        photoImageView.layer.cornerRadius = 5
        
        modelListContainer.layer.borderColor = UIColor.lightGray.cgColor
        modelListContainer.layer.borderWidth = 0.5
        
        outputLabel.text = "Classification:"
        
        readCacheModelList()
        readPreUsedModel()
        
        if let model = currentModel,
            load(model: model) {
            print("load preused model succ")
        } else {
            _ = load(model: resourceManager.localModel)
        }
    }
    
    @IBAction func choosePhotoButtonPressed() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    @IBAction func backButtonPressed() {
        getLoopCount()
        loopCountTextField.resignFirstResponder()
    }
    
    @IBAction func changeModelButtonPressed() {
        let vc = ModelListViewController()
        vc.modalPresentationStyle = .overCurrentContext
        vc.selectModel = { [weak self] model in
            guard let self = self, model.name != self.currentModel?.name else { return }
            
            if model.isLocal {
                _ = self.load(model: model)
                return
            }
            
            self.downloadingView.isHidden = false
            ResourceLoadManager.default.download(model: model) { [weak self] succ in
                guard let self = self else { return }
                self.downloadingView.isHidden = true
                guard succ else {
                    self.view.makeToast("download failed, please retry later", position: .center)
                    return
                }
                
                let preModel = self.currentModel
                if self.load(model: model) == false {
                    self.view.makeToast("use model failed, please retry", position: .center)
                    _ = self.load(model: preModel ?? ResourceLoadManager.default.localModel)
                }
            }
        }
        self.present(vc, animated: false)
    }
    
    private func getLoopCount() {
        if let text = loopCountTextField.text, let count = Int(text) {
            loopCount = count
        } else {
            loopCount = 1
        }
        loopCount = max(1, loopCount)
        loopCountTextField.text = "\(loopCount)"
    }
    
    private func classify(image: UIImage) { // model data source preprocess
        photoImageView.image = image
        
        guard labels.isEmpty == false else {
            outputLabel.text = "Classification: labels is empty"
            choosePhotoButton.isEnabled = true
            return
        }
        
        guard let xgenEngine = xgenEngine else {
            outputLabel.text = "Classification: Xgen init failed"
            choosePhotoButton.isEnabled = true
            return
        }
        
        outputLabel.text = "Classifying..."
        choosePhotoButton.isEnabled = false
        
        /* scale image to model expected size*/
        guard let scaledImage = image.scaled(toWidth: imageWidth, toHeight: imageHeight) else {
            outputLabel.text = "Classification: image scaled failed"
            choosePhotoButton.isEnabled = true
            return
        }
        
        /* get image pixel rgb */
        guard let cgImage = scaledImage.cgImage else {
            outputLabel.text = "Classification: get scaled image pixel image failed"
            choosePhotoButton.isEnabled = true
            return
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * imageWidth
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
        guard let context = CGContext(data: nil, width: imageWidth, height: imageHeight, bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            outputLabel.text = "Classification: get scaled image pixel image failed"
            choosePhotoButton.isEnabled = true
            return
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))

        guard let buffer = context.data else {
            outputLabel.text = "Classification: get scaled image pixel image failed"
            choosePhotoButton.isEnabled = true
            return
        }

        let pixelBuffer = buffer.bindMemory(to: UInt32.self, capacity: imageWidth * imageHeight)
        
        var floatValues: [Float] = Array(repeating: 0, count: imageWidth * imageHeight * imageChannel)
        var index = 0
        
        for i in 0 ..< Int(imageHeight) {
            for j in 0 ..< Int(imageWidth) {
                let offset = i * imageWidth + j
                let color = pixelBuffer[offset]
                
                let r = (Float(UInt8((color >> 24) & 255)) / 255.0 - modelMean[0]) / modelStd[0]
                let g = (Float(UInt8((color >> 16) & 255)) / 255.0 - modelMean[1]) / modelStd[1]
                let b = (Float(UInt8((color >> 8) & 255)) / 255.0 - modelMean[2]) / modelStd[2]
                
                floatValues[index] = r
                index += 1
                floatValues[index] = g
                index += 1
                floatValues[index] = b
                index += 1
            }
        }
        
        for _ in 0..<loopCount {
            let date = Date()
            guard let result = xgenEngine.run(floatValues) else { continue }
            if let name = getClassication(result) {
                let now = Date()
                let time = now.timeIntervalSince(date)
                outputLabel.text = "Classification: \(name) \(max(1, Int(time * 1000)))ms"
            } else {
                outputLabel.text = "Classification: Detect error"
            }
        }
        choosePhotoButton.isEnabled = true
    }
}

extension HomeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        getLoopCount()
        return true
    }
}

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }
        
        picker.dismiss(animated: true)
        classify(image: image)
    }
}

// MARK: - util function
private extension HomeViewController {
    func readCacheModelList() {
        guard let list = resourceManager.getCachedList(), !list.isEmpty else { return }
        modelList = [resourceManager.localModel] + list
    }
    
    static let preUsedModelNameKey = "preUsedModelNameKey"
    func readPreUsedModel() {
        guard let name = UserDefaults.standard.string(forKey: Self.preUsedModelNameKey) else { return }
        for model in modelList {
            if model.name == name {
                currentModel = model
                break
            }
        }
    }
    
    func load(model: AIModel) -> Bool {
        guard resourceManager.isAllFileDownloaded(for: model) else {
            resourceManager.clearDownloadedFile(for: model)
            return false
        }
        
        let labelFileURL = resourceManager.labelFileURL(for: model)
        guard let data = try? Data(contentsOf: labelFileURL) else {
            print("labels data load failed")
            resourceManager.clearDownloadedFile(for: model)
            return false
        }
        
        let jsonDecoder = JSONDecoder()
        guard let labelData = try? jsonDecoder.decode(LabelData.self, from: data) else {
            print("labels json decode failed")
            return false
        }
        
        let labels = labelData.list.sorted(by: { l1, l2 in
            l1.id < l2.id
        }).map { $0.name }
        
        let fallbackFileURL = resourceManager.fallbackFileURL(for: model)
        let xgenEngine = XGenEngine(fallbackURL: fallbackFileURL)
        
        guard xgenEngine != nil, !labels.isEmpty else {
            print("AI model load failed")
            return false
        }
        
        UserDefaults.standard.set(model.name, forKey: Self.preUsedModelNameKey)
        currentModel = model
        self.labels = labels
        self.xgenEngine = xgenEngine
        
        if let image = photoImageView.image {
            DispatchQueue.main.async { [weak self] in self?.classify(image: image) }
        }
        
        return true
    }
    
    func getClassication(_ result: [Float]) -> String? {
        guard result.isEmpty == false else { return nil }
        
        var index = -1
        var maxAccu = -Float.infinity
        
        let max = min(result.count, labels.count)
        for i in 0..<max {
            let value = result[i]
            if value > maxAccu {
                index = i
                maxAccu = value
            }
        }
        
        if index > 0 {
            print("classication index: \(index)")
        }
        
        return index > 0 ? labels[index] : nil
    }
}

fileprivate class LabelData: Decodable {
    let list: [LabelModel]
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        list = try container.decode([LabelModel].self, forKey: .list)
    }
    
    enum CodingKeys: String, CodingKey {
        case list = "data"
    }
    
    fileprivate class LabelModel: Decodable {
        let id: Int
        let name: String
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
        }
        
        enum CodingKeys: String, CodingKey {
            case id = "Class ID"
            case name = "Class Name"
        }
    }
}

private extension UIImage {
    func scaled(toWidth: CGFloat, toHeight: CGFloat, opaque: Bool = false) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: toWidth, height: toHeight), opaque, 0)
        draw(in: CGRect(x: 0, y: 0, width: toWidth, height: toHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
