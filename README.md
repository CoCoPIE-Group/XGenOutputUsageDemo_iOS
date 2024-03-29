## 1 Introduction

This is a demo app that demonstrates how to integrate XGen output files. For the details on XGen's outputs for iOS, please refer to [Doc](https://xgen.cocopie.ai/v1.3.0/5_Results/). 


## 2 SDK Usage

Among the XGen's output for iOS, the most useful components are `*.fallback` and `xgen.framework`. The former is the AI model, and the latter is the XGen's runtime that executes the AI model. The use of the AI model through XGen can be seen in file `XGenOutputUsageDemo_iOS/XGenEngine.swift`, explained as follows.

#### 2.1 Import xgen.framework

Find the `*.fallback` file from the `*compiled_file/ios/benchmark_data` directory under XGen workplace, and put it into `XGenOutputUsageDemo_iOS/Resource` directory of this project. Change the file name to your own in `XGenOutputUsageDemo_iOS/XHomeViewController.swift`

Find `xgen.framework` from `*compiled_file/ios/` under XGen workplace, and put it into `xgen/` directory of this project.

`xgen.framework` is a normal iOS framework, you can use whatever methods for framework to integrate it in your iOS project. We use local private pod to integrate it in our demo. Please refer to `Podfile` and local `xgen` folder for details.

#### 2.2 Initialize XGen

Call the `XGenInit` method with `xxx.fallback` file's content to initialize XGen

#### 2.3 Input data preprocessing

The input data is preprocessed according to the model parameters. Here is an example of preprocessing the input image for EfficientNet to work on the image.

``` Swift
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
```

#### 2.4 Call the AI model generated by XGen

Call the `XGenCopyBufferToTensor` method to pass the preprocessed data into the XGen runtime, and then call the `XGenRun` method to run the AI model

``` Swift
guard let inputTensor = XGenGetInputTensor(xgen, 0) else {
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

guard XGenRun(xgen) == XGenOk else {
    print("xgen run error")
    return nil
}
```

#### 2.5 Get XGen output

Call the `XGenCopyTensorToBuffer` method to get the output of XGen, which is a float array in the example

``` swift
guard let outputTensor = XGenGetOutputTensor(xgen, 0) else {
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
