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
    
    private var loopCount = 1
    private let imageWidth: CGFloat = 224
    private let imageHeight: CGFloat = 224
    private let imageChannel = 3
    private let modelMean: [Float] = [0.485, 0.456, 0.406]
    private let modelStd: [Float] = [0.229, 0.224, 0.225]
    
    private var xgenEngine: XGenEngine?
    private var labels: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "CoCoPIEApiExample"
        
        outputLabelBackground.layer.cornerRadius = 10
        choosePhotoButton.layer.cornerRadius = 10
        photoImageView.layer.cornerRadius = 5
        
        outputLabel.text = "Classification:"
        
        readLabels()
        initXGen()
    }
    
    @IBAction func choosePhotoButtonPressed() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    @IBAction func backButtonPressed() {
        getLoopCount()
        loopCountTextField.resignFirstResponder()
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
        guard let rgbaImage = RGBAImage(image: scaledImage) else {
            outputLabel.text = "Classification: get scaled image pixel image failed"
            choosePhotoButton.isEnabled = true
            return
        }
        
        var floatValues: [Float] = Array(repeating: 0, count: rgbaImage.width * rgbaImage.height * imageChannel)
        var index = 0
        
        for y in 0..<rgbaImage.height {
            for x in 0..<rgbaImage.width {
                let offset = y * rgbaImage.width + x
                let outPixel = rgbaImage.pixels[offset]
                
                floatValues[index] = (Float(outPixel.R) / 255.0 - modelMean[0]) / modelStd[0]
                index += 1
                floatValues[index] = (Float(outPixel.G) / 255.0 - modelMean[1]) / modelStd[1]
                index += 1
                floatValues[index] = (Float(outPixel.B) / 255.0 - modelMean[2]) / modelStd[2]
                index += 1
            }
        }
        
        for _ in 0..<loopCount {
            let date = Date()
            guard let result = xgenEngine.run(floatValues) else { continue }
            if let (index, name) = getClassication(result) {
                let now = Date()
                let time = now.timeIntervalSince(date)
                outputLabel.numberOfLines = 0
                outputLabel.text = "Classification: \(index) \(max(1, Int(time * 1000)))ms\n \(name)"
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
        DispatchQueue.main.async {
            self.classify(image: image)
        }
    }
}

// MARK: - util function
private extension HomeViewController {
    func readLabels() {
        guard let url = Bundle.main.url(forResource: "imagenet_labels_1000", withExtension: "json"),
            let data = try? Data(contentsOf: url) else {
            print("labels load failed")
            return
        }
        
        let jsonDecoder = JSONDecoder()
        guard let labelData = try? jsonDecoder.decode(LabelData.self, from: data) else {
            print("labels json decode failed")
            return
        }
        
        labels = labelData.list.sorted(by: { l1, l2 in
            l1.id < l2.id
        }).map { $0.name }
    }
    
    func initXGen() {
        guard let modelURL = Bundle.main.url(forResource: "efficientnet_b0_ra_3dd342df", withExtension: "fallback") else {
            print("model load failed")
            return
        }
        
        xgenEngine = XGenEngine(fallbackURL: modelURL)
    }
    
    func getClassication(_ result: [Float]) -> (Int, String)? {
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
        
        return index > 0 ? (index, labels[index]) : nil
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
