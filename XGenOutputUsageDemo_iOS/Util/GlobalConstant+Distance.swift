//
//  ModelListViewController.swift
//  XGenOutputUsageDemo_iOS
//
//  Created by steven on 2023/1/22.
//

import Foundation
import UIKit

public struct C {}

public extension C {
    struct App {}
}

public extension C {
    struct Distance {
        public static var safeAreaEdgeInsets: UIEdgeInsets {
            guard C.Screen.isiPhoneX else {
                return .zero
            }
            return portraitSafeAreaEdgeInsets
        }

        public static var portraitSafeAreaEdgeInsets: UIEdgeInsets {
            return UIEdgeInsets(top: 24, left: 0, bottom: 34, right: 0)
        }
    }
}
