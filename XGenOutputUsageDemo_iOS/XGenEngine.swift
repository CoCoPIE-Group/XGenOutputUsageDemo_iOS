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
    
    func run(_ inputData: UnsafeRawPointer) -> [Float]? {
        guard let xgen = xgen else {
            print("valid xgen is not inited")
            return nil
        }
        
        guard let inputTensor = XGenGetInputTensor(xgen, 0) else {
            print("input tensor init failed")
            return nil
        }
        
        let inputSize = XGenGetTensorSizeInBytes(inputTensor)
        print("input_size: \(inputSize)")
        XGenCopyBufferToTensor(inputTensor, inputData, inputSize)
        
        XGenRun(xgen)
        
        guard let outputTensor = XGenGetInputTensor(xgen, 0) else {
            print("output tensor init failed ")
            return nil
        }
        let outputSize = XGenGetTensorSizeInBytes(outputTensor)
        print("output_size: \(outputSize)")
        var output: [Float] = Array(repeating: 0, count: (outputSize / MemoryLayout<Float>.size))
        output.withUnsafeMutableBytes { mutableRawBufferPointer in
            let mutalbeRawPtr = mutableRawBufferPointer.baseAddress!
            XGenCopyTensorToBuffer(outputTensor, mutalbeRawPtr, outputSize)
        }
        
        return output
    }
    
    private var xgen: OpaquePointer?
}
