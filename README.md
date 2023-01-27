## 1 Introduction

Integration XGen output to iOS app demo. XGen's outputs for iOS, please ref [Doc](https://54.208.247.116/v1.1.0/5_Results/)


## 2 SDK Usage

Among the XGen's ourput for iOS, the most useful components are `xxx.fallback` and `XGen.framework`. The former is the AI model, and the latter is the XGen's custom API to run the model.

#### 2.1 Import XGen.framework

XGen.framework is a normal iOS framework, you can use whatever methods for framework to integrate it in your iOS project. We use local private pod to integrate it in our demo. ref `Podfile` and local `XGen` folder for details.

#### 2.2 Initialize XGen

Call the `XGenInit` method with `xxx.fallback` file's content to initialize XGen

#### 2.3 Input data preprocessing

The input data is preprocessed according to the model parameters. Here is an example of preprocessing the input image when using the efficient.

``` Swift
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
```

#### 2.4 Run XGen

Call the `XGenCopyBufferToTensor` method to pass the preprocessed data into XGen, and then call the `XGenRun` method to run XGen

``` Swift
guard let inputTensor = XGenGetInputTensor(XGen, 0) else {
    print("input tensor init failed")
    return nil
}

let floatMemorySize = MemoryLayout<Float>.size

let inputSizeBytes = XGenGetTensorSizeInBytes(inputTensor)
let inputSize = inputSizeBytes / floatMemorySize
print("input_size: \(inputSize)")

var input: [Float] = Array(repeating: 0, count: inputSize)
let inputChannelSize = inputSize / 3
for i in 0..<inputChannelSize {
    for j in 0..<3 {
        let srcIndex = i * 3 + j
        let dstIndex = i + inputChannelSize * j
        input[dstIndex] = inputData[srcIndex]
    }
}

input.withUnsafeBytes { rawBufferPointer in
    let rawPtr = rawBufferPointer.baseAddress!
    XGenCopyBufferToTensor(inputTensor, rawPtr, inputSizeBytes)
}
```

#### 2.5 Get XGen output

Call the `XGenCopyTensorToBuffer` method to get the output of XGen, which is a float array in the example

``` swift
guard let outputTensor = XGenGetInputTensor(XGen, 0) else {
    print("output tensor init failed ")
    return nil
}
let outputSizeBytes = XGenGetTensorSizeInBytes(outputTensor)
let outputSize = outputSizeBytes / floatMemorySize
print("output_size: \(outputSize)")
var output: [Float] = Array(repeating: 0, count: outputSize)
output.withUnsafeMutableBytes { mutableRawBufferPointer in
    let mutalbeRawPtr = mutableRawBufferPointer.baseAddress!
    XGenCopyTensorToBuffer(outputTensor, mutalbeRawPtr, outputSizeBytes)
}
```

## 3 Copyright

© 2023 CoCoPIE Inc. All Rights Reserved.

CoCoPIE Inc., its logo and certain names, product and service names reference herein may be registered trademarks, trademarks, trade names or service marks of CoCoPIE Inc. in certain jurisdictions.

The material contained herein is proprietary, privileged and confidential and owned by CoCoPIE Inc. or its third-party licensors. The information herein is provided only to be person or entity to which it is addressed, for its own use and evaluation; therefore, no disclosure of the content of this manual will be made to any third parities without specific written permission from CoCoPIE Inc.. The content herein is subject to change without further notice. Limitation of Liability – CoCoPIE Inc. shall not be liable.

All other trademarks are the property of their respective owners. Other company and brand products and service names are trademarks or registered trademarks of their respective holders.

Limitation of Liability

CoCoPIE Inc. shall not be liable.