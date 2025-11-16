//
//  DeviceUtils.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import SwiftUI
import UIKit

struct DeviceUtils {
    /// Returns true if the device is an iPad
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Returns true if the device is an iPhone
    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Returns the horizontal size class
    static var horizontalSizeClass: UserInterfaceSizeClass? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return windowScene.windows.first?.rootViewController?.traitCollection.horizontalSizeClass == .regular ? .regular : .compact
    }
    
    /// Returns the vertical size class
    static var verticalSizeClass: UserInterfaceSizeClass? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return windowScene.windows.first?.rootViewController?.traitCollection.verticalSizeClass == .regular ? .regular : .compact
    }
    
    /// Returns true if the device is in landscape orientation
    static var isLandscape: Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return false
        }
        return windowScene.interfaceOrientation.isLandscape
    }
    
    /// Returns true if the device is in portrait orientation
    static var isPortrait: Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return true
        }
        return windowScene.interfaceOrientation.isPortrait
    }
    
    /// Returns optimal column count for grid layouts based on device
    static var optimalGridColumns: Int {
        if isPad {
            return 3
        } else {
            return 2
        }
    }
    
    /// Returns optimal spacing for layouts based on device
    static var optimalSpacing: CGFloat {
        if isPad {
            return 24
        } else {
            return 16
        }
    }
    
    /// Returns optimal padding for layouts based on device
    static var optimalPadding: CGFloat {
        if isPad {
            return 32
        } else {
            return 20
        }
    }
}

