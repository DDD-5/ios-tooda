//
//  CreateNoteViewReactor.swift
//  Tooda
//
//  Created by Lyine on 2021/05/19.
//  Copyright © 2021 DTS. All rights reserved.
//

import Foundation
import ReactorKit
import Then

final class CreateNoteViewReactor: Reactor {
  
  let scheduler: Scheduler = MainScheduler.asyncInstance

  struct Dependency {
    let service: NetworkingProtocol
    let coordinator: AppCoordinatorType
    let authorization: AppAuthorizationType
    let createDiarySectionFactory: CreateNoteSectionType
  }

  enum Action {
    case initializeForm
    case dismissView
    case regist
    case didSelectedImageItem(IndexPath)
    case uploadImage(Data)
  }

  enum Mutation {
    case initializeForm([NoteSection])
    case requestPermissionMessage(String)
    case showAlertMessage(String?)
    case showPhotoPicker
    case fetchImageSection(NoteSectionItem)
  }

  // TODO: sections외 다른 변수들을 하나의 enum으로 관리할 수 있는 방법으로 리팩토링 예정
  struct State: Then {
    var sections: [NoteSection] = []
    var requestPermissionMessage: String?
    var showAlertMessage: String?
    var showPhotoPicker: Void?
  }

  let initialState: State

  let dependency: Dependency

  init(dependency: Dependency) {
    self.dependency = dependency
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .initializeForm:
      return .just(Mutation.initializeForm(makeSections()))
    case .didSelectedImageItem(let index):
      return checkAuthorizationAndSelectedItem(indexPath: index)
    case .uploadImage(let data):
      return self.uploadImage(data)
        .flatMap { [weak self] response -> Observable<Mutation> in
        return self?.fetchImageSection(with: response) ?? .empty()
      }
    default:
      return .empty()
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    
    // do, then 을해서 초기값을 막아줄 수 있음
    var newState = State().with {
      $0.sections = state.sections
      $0.requestPermissionMessage = nil
      $0.showAlertMessage = nil
      $0.showPhotoPicker = nil
    }
    
    switch mutation {
    case .initializeForm(let sections):
      newState.sections = sections
    case .requestPermissionMessage(let message):
      newState.requestPermissionMessage = message
    case .showAlertMessage(let message):
      newState.showAlertMessage = message
    case .showPhotoPicker:
      newState.showPhotoPicker = ()
    case .fetchImageSection(let sectionItem):
      newState.sections[NoteSection.Identity.image.rawValue].items = [sectionItem]
    }

    return newState
  }

  private func makeSections() -> [NoteSection] {
    let sections = self.dependency.createDiarySectionFactory(self.dependency.authorization, self.dependency.coordinator)
    return sections
  }
  
  private func didSelectedImageItem(_ indexPath: IndexPath) -> Observable<Mutation> {
    
    let section = self.currentState.sections[NoteSection.Identity.image.rawValue]
    
    guard let imageCellReactor = section.items.compactMap { items -> NoteImageCellReactor? in
      if case let NoteSectionItem.image(value) = items {
        return value
      } else {
        return nil
      }
    }.first else { return .empty() }
    
    let imageItemSection = imageCellReactor.currentState.sections[indexPath.section]
    
    let imageSectionItem = imageItemSection.items[indexPath.row]
    
    switch imageSectionItem {
      case .empty:
        guard imageCellReactor.currentState.sections[NoteImageSection.Identity.item.rawValue].items.count < 3 else {
          return .just(.showAlertMessage("이미지는 최대 3개까지 등록 가능합니다."))
        }
        
        return .just(.showPhotoPicker)
      case .item(let reactor):
        print("이미지 삭제: \(reactor.currentState.item.imageURL)")
    }
    
    return .empty()
  }
  
  private func checkAuthorizationAndSelectedItem(indexPath: IndexPath) -> Observable<Mutation> {
    let service = self.dependency.authorization
    
    return service.photoLibrary.flatMap { [weak self] status -> Observable<Mutation> in
      switch status {
        case .authorized:
          guard let mutation = self?.didSelectedImageItem(indexPath) else { return .empty() }
          return mutation
        default:
          return .just(Mutation.requestPermissionMessage("테스트"))
      }
    }
  }
}

// MARK: Upload Images

extension CreateNoteViewReactor {
  private func uploadImage(_ data: Data) -> Observable<String> {
    return Observable.just("aaaaa")
  }
}

// MARK: - Fetch ImageSections

extension CreateNoteViewReactor {
  private func fetchImageSection(with imageURL: String) -> Observable<Mutation> {
    let section = self.currentState.sections[NoteSection.Identity.image.rawValue]

    guard let imageCellReactor = section.items.compactMap({ items -> NoteImageCellReactor? in
      if case let NoteSectionItem.image(value) = items {
        return value
      } else {
        return nil
      }
    }).first else { return .empty() }


    imageCellReactor.action.onNext(.addImage(imageURL))

    return .empty()
  }
}

typealias CreateNoteSectionType = (AppAuthorizationType, AppCoordinatorType) -> [NoteSection]

let createDiarySectionFactory: CreateNoteSectionType = { authorization, coordinator -> [NoteSection] in
  var sections: [NoteSection] = [
    NoteSection(identity: .content, items: []),
    NoteSection(identity: .stock, items: []),
    NoteSection(identity: .addStock, items: []),
    NoteSection(identity: .image, items: []),
    NoteSection(identity: .link, items: [])
  ]

  let contentReactor: NoteContentCellReactor = NoteContentCellReactor()
  let contentSectionItem: NoteSectionItem = NoteSectionItem.content(contentReactor)
  
  let addStockReactor: EmptyNoteStockCellReactor = EmptyNoteStockCellReactor()
  let addStockSectionItem: NoteSectionItem = NoteSectionItem.addStock(addStockReactor)
  
  let imageReactor: NoteImageCellReactor = NoteImageCellReactor(dependency: .init(factory: noteImageSectionFactory))
  let imageSectionItem: NoteSectionItem = NoteSectionItem.image(imageReactor)

  sections[NoteSection.Identity.content.rawValue].items = [contentSectionItem]
  sections[NoteSection.Identity.addStock.rawValue].items = [addStockSectionItem]
  sections[NoteSection.Identity.image.rawValue].items = [imageSectionItem]

  return sections
}
