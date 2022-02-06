//
//  AppAppearance.swift
//  Tooda
//
//  Created by jinsu on 2021/05/23.
//  Copyright © 2021 DTS. All rights reserved.
//

import UIKit

final class AppApppearance {
  
  enum NavigationBarStyle {
    case normal
    case clear
    case white
    
    var tintColor: UIColor {
      return .black
    }
    
    var barTintColor: UIColor? {
      switch self {
      case .white:
        return .white
      case .clear:
        return .clear
      case .normal:
        return nil
      }
    }
    
    var isTranslucent: Bool {
      switch self {
      case .white:
        return false
      case .normal, .clear:
        return true
      }
    }
    
    var backButtonImage: UIImage? {
      return UIImage(type: .backBarButton)
    }
    
    var shadowImage: UIImage? {
      switch self {
      case .clear, .white:
        return UIImage()
      case .normal:
        return nil
      }
    }
    
    var backgroundImage: UIImage? {
      switch self {
      case .clear, .white:
        return UIImage()
      case .normal:
        return nil
      }
    }
  }
  
  static func configureAppearance() {
    let navigationbar = UINavigationBar.appearance()
    let style: NavigationBarStyle = .clear

    let appearance = UINavigationBarAppearance().then {
      $0.configureWithTransparentBackground()
      $0.backgroundColor = style.barTintColor
      $0.backgroundImage = style.backgroundImage
      $0.shadowImage = style.shadowImage
      $0.setBackIndicatorImage(style.backButtonImage, transitionMaskImage: style.backButtonImage)
    }

    navigationbar.standardAppearance = appearance
    navigationbar.scrollEdgeAppearance = appearance
    navigationbar.tintColor = style.tintColor

//    navigationbar.tintColor = style.tintColor
//    navigationbar.setBackgroundImage(style.backgroundImage, for: .default)
//    navigationbar.shadowImage = style.shadowImage
//    navigationbar.backItem?.title = ""
//    navigationbar.backIndicatorImage = style.backButtonImage
//    navigationbar.backIndicatorTransitionMaskImage = style.backButtonImage
//    navigationbar.isTranslucent = style.isTranslucent
//    navigationbar.barTintColor = style.barTintColor
  }
  
  static func updateNavigaionBarAppearance(_ navigationbar: UINavigationBar?, with style: NavigationBarStyle) {

    let appearance = UINavigationBarAppearance().then {
      $0.configureWithTransparentBackground()
      $0.backgroundColor = style.barTintColor
      $0.backgroundImage = style.backgroundImage
      $0.shadowImage = style.shadowImage
      $0.setBackIndicatorImage(style.backButtonImage, transitionMaskImage: style.backButtonImage)
    }

    navigationbar?.standardAppearance = appearance
    navigationbar?.scrollEdgeAppearance = appearance
    navigationbar?.tintColor = style.tintColor

//    navigationbar?.tintColor = style.tintColor
//    navigationbar?.setBackgroundImage(style.backgroundImage, for: .default)
//    navigationbar?.shadowImage = style.shadowImage
//    navigationbar?.backIndicatorImage = style.backButtonImage
//    navigationbar?.backIndicatorTransitionMaskImage = style.backButtonImage
//    navigationbar?.isTranslucent = style.isTranslucent
//    navigationbar?.barTintColor = style.barTintColor
  }
}
