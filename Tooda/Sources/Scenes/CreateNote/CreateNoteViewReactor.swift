//
//  CreateNoteViewReactor.swift
//  Tooda
//
//  Created by Lyine on 2021/05/19.
//  Copyright © 2021 DTS. All rights reserved.
//

import Foundation
import ReactorKit

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
  }

  enum Mutation {
    case initializeForm([NoteSection])
  }

  struct State {
    var sections: [NoteSection]
  }

  let initialState: State

  let dependency: Dependency

  init(dependency: Dependency) {
    self.dependency = dependency
    self.initialState = State(sections: [])
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .initializeForm:
      return .just(Mutation.initializeForm(makeSections()))
    default:
      return .empty()
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .initializeForm(let sections):
      newState.sections = sections
    }

    return newState
  }

  private func makeSections() -> [NoteSection] {
    let sections = self.dependency.createDiarySectionFactory(self.dependency.authorization, self.dependency.coordinator)
    return sections
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
  
  let imageReactor: NoteImageCellReactor = NoteImageCellReactor(dependency: .init(factory: noteImageSectionFactory,
                                                                                  authorizationService: authorization,
                                                                                  coordinator: coordinator))
  let imageSectionItem: NoteSectionItem = NoteSectionItem.image(imageReactor)

  sections[NoteSection.Identity.content.rawValue].items = [contentSectionItem]
  sections[NoteSection.Identity.addStock.rawValue].items = [addStockSectionItem]
  sections[NoteSection.Identity.image.rawValue].items = [imageSectionItem]

  return sections
}
