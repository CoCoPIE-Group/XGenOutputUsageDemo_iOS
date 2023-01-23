//
//  ModelListViewController.swift
//  XGenOutputUsageDemo_iOS
//
//  Created by steven on 2023/1/22.
//

import Foundation
import UIKit

public enum ScreenType {
    case small          //iPhone 4, 4s
    case big            //iPhone 5, 5s
    case bigger         //iPhone 6, 7, 8
    case biggerThanEver //iPhone 6 Plus, 7 Plus, 8 Plus
    case x              //iPhone X, Xs
    case xMax           //iPhone Xr, Xs Max
    case tMini           //iPhone 12 mini
    case tMiddule        //iPhone 12,12 pro
    case tMax            //iPhone 12 pro max
}

public extension C {
    struct Screen {
        public static let isiPhoneX: Bool = {
            return (type == .x
                    || type == .xMax
                    || type == .tMini
                    || type == .tMiddule
                    || type == .tMax)
        }()
        // ref https://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
        // https://ios-resolution.com/
        public static let type: ScreenType = {
            let size: CGSize = UIScreen.main.bounds.size
            let width: CGFloat = min(size.width, size.height)
            switch width {
            case 320.0:
                if max(size.height, size.width) > 480.0 {
                    return .big
                } else {
                    return .small
                }
            case 375.0:
                if max(size.height, size.width) > 667.0 {
                    return .x
                } else {
                    return .bigger
                }
            case 414.0:
                if max(size.height, size.width) > 736.0 {
                    return .xMax
                } else {
                    return .biggerThanEver
                }
            case 360.0:
                return .tMini
            case 390:
                return .tMiddule
            case 428:
                return .tMax
            default:
                return .x
            }
        }()
    }
}
