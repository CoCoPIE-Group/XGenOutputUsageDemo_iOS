//
//  XGenEngine.swift
//  XGenOutputUsageDemo_iOS
//
//  Created by steven on 2023/1/11.
//

import Foundation
import xgen

class XGenEngine {
    init?(fallbackURL: URL) {
        guard FileManager.default.fileExists(atPath: fallbackURL.path) else { return nil }
        
        guard let data = try? Data(contentsOf: fallbackURL) else {
            print("load model error")
            return nil
        }
        
        data.withUnsafeBytes { rawBufferPointer in
            let rawPtr = rawBufferPointer.baseAddress!
            xgen = XGenInit(rawPtr, rawBufferPointer.count)
        }
        
        guard xgen != nil else {
            print("init xgen failed")
            return nil
        }
    }
    
    deinit {
        XGenShutdown(xgen)
        xgen = nil
    }
    
    func run(_ inputData: [Float]) -> [Float]? {
        guard let xgen = xgen else {
            print("valid xgen is not inited")
            return nil
        }
        
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
        
        guard let outputTensor = XGenGetInputTensor(xgen, 0) else {
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
        
        return output
    }
    
    private var xgen: OpaquePointer?
}
