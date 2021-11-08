//
//  AppFactory.swift
//  Tooda
//
//  Created by jinsu on 2021/05/23.
//  Copyright © 2021 DTS. All rights reserved.
//

import Foundation

import Swinject
import UIKit

protocol AppFactoryType {
  func makeViewController(from scene: Scene) -> UIViewController
}

final class AppFactory: AppFactoryType {
  
  struct Dependency {
    let appInject: AppInjectRegister & AppInjectResolve
  }
  
  private let dependency: Dependency
  
  init(dependency: Dependency) {
    self.dependency = dependency
  }
  
  func makeViewController(from scene: Scene) -> UIViewController {
    switch scene {
    case .home:
      let reactor = HomeReactor(
        dependency: .init(
          service: self.dependency.appInject.resolve(NetworkingProtocol.self),
          coordinator: self.dependency.appInject.resolve(AppCoordinatorType.self)
        )
      )
      return HomeViewController(reactor: reactor)

    case .createNote:
      let reactor = CreateNoteViewReactor(
        dependency: .init(
          service: self.dependency.appInject.resolve(NetworkingProtocol.self),
          coordinator: self.dependency.appInject.resolve(AppCoordinatorType.self),
          authorization: self.dependency.appInject.resolve(AppAuthorizationType.self),
          createDiarySectionFactory: createDiarySectionFactory)
      )
      return CreateNoteViewController(reactor: reactor)

    case .login:
      let reactor = LoginReactor(
        dependency: .init(
          service: self.dependency.appInject.resolve(NetworkingProtocol.self),
          coordinator: self.dependency.appInject.resolve(AppCoordinatorType.self),
          localPersistanceManager: self.dependency.appInject.resolve(LocalPersistanceManagerType.self)
        )
      )
      return LoginViewController(reactor: reactor)

    case .settings:
      let reactor = SettingsReactor(dependency: .init())
      return SettingsViewController(reactor: reactor)
      
    case .addStock(let completionRelay):
      let reator = AddStockReactor(
        dependency: .init(
          completionRelay: completionRelay,
          coordinator: self.dependency.appInject.resolve(AppCoordinatorType.self),
          service: self.dependency.appInject.resolve(NetworkingProtocol.self)
        )
      )
      let viewController = AddStockViewController(reactor: reator)
      let navigationController = UINavigationController(rootViewController: viewController)
      navigationController.modalPresentationStyle = .overFullScreen
      return navigationController

    case .search:
      let reactor = SearchReactor(
        dependency: .init(
          service: self.dependency.appInject.resolve(NetworkingProtocol.self),
          coordinator: self.dependency.appInject.resolve(AppCoordinatorType.self)
        )
      )
      return SearchViewController(reactor: reactor)
    case .noteList:
      let reactor = NoteListReactor(
        dependency: .init(
          service: self.dependency.appInject.resolve(NetworkingProtocol.self),
          coordinator: self.dependency.appInject.resolve(AppCoordinatorType.self)
        )
      )
      return NoteListViewController(reactor: reactor)
    }
  }
}
