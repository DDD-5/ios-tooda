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
import RxRelay

// TODO: 노트 등록이 아닌 입력과 관련된 이름으로 변경해요.
final class CreateNoteViewReactor: Reactor {
  
  enum ViewPresentType {
    case showAlert(String)
    case showPermission(String)
    case showPhotoPicker
  }
  
  let scheduler: Scheduler = MainScheduler.asyncInstance

  struct Dependency {
    let service: NetworkingProtocol
    let coordinator: AppCoordinatorType
    let authorization: AppAuthorizationType
    let linkPreviewService: LinkPreViewServiceType
    let createDiarySectionFactory: CreateNoteSectionType?
    let modifiableNoteSectionFactory: ModifiableNoteSectionType?
    
    init(
      service: NetworkingProtocol,
      coordinator: AppCoordinatorType,
      authorization: AppAuthorizationType,
      linkPreviewService: LinkPreViewServiceType,
      createDiarySectionFactory: CreateNoteSectionType?,
      modifiableNoteSectionFactory: ModifiableNoteSectionType?
    ) {
      self.service = service
      self.coordinator = coordinator
      self.authorization = authorization
      self.linkPreviewService = linkPreviewService
      self.createDiarySectionFactory = createDiarySectionFactory
      self.modifiableNoteSectionFactory = modifiableNoteSectionFactory
    }
  }

  enum Action {
    case initializeForm
    case dismissView
    case regist
    case didSelectedImageItem(IndexPath)
    case uploadImage(Data)
    case showAddStockView
    case stockItemDidAdded(NoteStock)
    case linkURLDidAdded(String)
    case makeTitleAndContent(title: String, content: String)
    case linkButtonDidTapped
    case registerButtonDidTapped
    case updateButtonDidTapped
    case stckerDidPicked(Sticker)
    case updateStikcerDidPicked(Sticker)
    case noteItemDidDeleted(IndexPath)
    case showStockItemEditView(IndexPath)
    case stockItemDidUpdated(NoteStock)
  }

  enum Mutation {
    case initializeForm([NoteSection])
    case present(ViewPresentType)
    case fetchImageSection(NoteSectionItem)
    case fetchStockSection(NoteSectionItem)
    case fetchLinkSection(NoteSectionItem)
    case shouldRegisterButtonEnabeld(Bool)
    case stockItemDidDeleted(Int)
    case linkItemDidDeleted(Int)
    case requestNoteDataDidChanged(NoteRequestDTO)
    case fetchEmptyStockItem(NoteSectionItem)
  }

  struct State: Then {
    var sections: [NoteSection] = []
    var presentType: ViewPresentType?
    var shouldReigsterButtonEnabled: Bool = false
    var requestNote: NoteRequestDTO = NoteRequestDTO()
  }
  
  struct Payload {
    var updateCompletionRelay: PublishRelay<Note>?
  }

  let initialState: State
  
  private let linkItemMaxCount: Int = 2
  
  static let stockItemMaxCount: Int = 5
  
  private var lastEditableStockCellIndexPath: IndexPath?

  let dependency: Dependency
  
  private let payload: Payload
  
  // MARK: Global Events
  
  private let addStockCompletionRelay: PublishRelay<NoteStock> = PublishRelay()
  private let addLinkURLCompletionRelay: PublishRelay<String> = PublishRelay()
  private let addStickerCompletionRelay: PublishRelay<Sticker> = PublishRelay()
  private let updateStickerCompletionRelay: PublishRelay<Sticker> = PublishRelay()
  
  private let stockItemEditCompletionRelay: PublishRelay<NoteStock> = PublishRelay()
  
  init(dependency: Dependency, modifiableNote: NoteRequestDTO?, payload: Payload) {
    self.dependency = dependency
    
    if let requestNote = modifiableNote {
      self.initialState = State(requestNote: requestNote)
    } else {
      self.initialState = State()
    }
    
    self.payload = payload
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .initializeForm:
      return .just(Mutation.initializeForm(makeSections()))
    case .didSelectedImageItem(let index):
      return checkAuthorizationAndSelectedItem(indexPath: index)
    case .uploadImage(let data):
      return self.uploadImage(data)
        .flatMap { [weak self] imageURL -> Observable<Mutation> in
          return self?.fetchImageSection(with: imageURL) ?? .empty()
      }
    case .showAddStockView:
      return presentAddStockView()
    case .stockItemDidAdded(let stock):
      return self.makeStockSectionItem(stock)
    case .linkURLDidAdded(let url):
      return self.makeLinkSectionItem(url)
    case .makeTitleAndContent(let title, let content):
      return self.makeTitleAndContent(title, content)
    case .linkButtonDidTapped:
        return self.linkButtonDidTapped()
    case .registerButtonDidTapped:
        return self.registerButtonDidTapped()
    case .updateButtonDidTapped:
        return self.updateButtonDidTapped()
    case .stckerDidPicked(let sticker):
        return self.addStickerAndAddNote(sticker)
    case .updateStikcerDidPicked(let sticker):
        return self.addStickerAndUpdateNote(sticker)
    case .noteItemDidDeleted(let indexPath):
        return self.noteItemDidDeleted(indexPath)
    case .showStockItemEditView(let index):
        return self.showStockItemEditView(index)
    case .stockItemDidUpdated(let stock):
        return self.stockItemDidUpdated(stock)
    case .dismissView:
        return dismissView()
    default:
      return .empty()
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    
    var newState = State().with {
      $0.sections = state.sections
      $0.shouldReigsterButtonEnabled = state.shouldReigsterButtonEnabled
      $0.presentType = nil
      $0.requestNote = state.requestNote
    }
    
    switch mutation {
    case .initializeForm(let sections):
      newState.sections = sections
    case .present(let type):
      newState.presentType = type
    case .fetchImageSection(let sectionItem):
      newState.sections[NoteSection.Identity.image.rawValue].items = [sectionItem]
    case .fetchStockSection(let sectionItem):
      newState.sections[NoteSection.Identity.stock.rawValue].items.append(sectionItem)
    case .fetchLinkSection(let sectionItem):
      newState.sections[NoteSection.Identity.link.rawValue].items.append(sectionItem)
    case .shouldRegisterButtonEnabeld(let enabled):
      newState.shouldReigsterButtonEnabled = enabled
    case .stockItemDidDeleted(let row):
      newState.sections[NoteSection.Identity.stock.rawValue].items.remove(at: row)
    case .linkItemDidDeleted(let row):
      newState.sections[NoteSection.Identity.link.rawValue].items.remove(at: row)
    case .requestNoteDataDidChanged(let data):
      newState.requestNote = data
    case .fetchEmptyStockItem(let sectionItem):
      newState.sections[NoteSection.Identity.addStock.rawValue].items = [sectionItem]
    }

    return newState
  }
  
  func transform(action: Observable<Action>) -> Observable<Action> {
    return Observable.merge(
      action,
      self.addStockCompletionRelay
        .map { Action.stockItemDidAdded($0) },
      self.addLinkURLCompletionRelay
        .take(self.linkItemMaxCount)
        .map { Action.linkURLDidAdded($0) },
      self.addStickerCompletionRelay
        .map { Action.stckerDidPicked($0) },
      self.stockItemEditCompletionRelay
        .map { Action.stockItemDidUpdated($0) },
      self.updateStickerCompletionRelay
        .map { Action.updateStikcerDidPicked($0) }
    )
  }

  private func makeSections() -> [NoteSection] {
    
    if let createSectionFactory = self.dependency.createDiarySectionFactory {
      let sections = createSectionFactory(self.dependency.authorization, self.dependency.coordinator)
      return sections
    }
    
    if let modifySectionFactory = self.dependency.modifiableNoteSectionFactory {
      let sections = modifySectionFactory(self.currentState.requestNote, self.dependency.linkPreviewService)
      return sections
    }
    
    return []
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
          return .just(.present(.showAlert("이미지는 최대 3개까지 등록 가능합니다.")))
        }
        
        return .just(.present(.showPhotoPicker))
      case .item:
        imageCellReactor.action.onNext(.removeImage(indexPath))
        
        var requestNote = self.currentState.requestNote
        requestNote.images.remove(at: indexPath.row)
        
        return .just(.requestNoteDataDidChanged(requestNote))
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
          return .just(.present(.showPermission("테스트")))
      }
    }
  }
}

// MARK: Upload Images

extension CreateNoteViewReactor {
  private func uploadImage(_ data: Data) -> Observable<String> {
    return self.dependency.service.request(NoteAPI.addImage(data: data))
      .map([String].self)
      .asObservable()
      .flatMap { dataList -> Observable<String> in
        guard let response = dataList.first else { return .empty() }
        return .just(response)
      }
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
    
    var requestNote = self.currentState.requestNote
    requestNote.images.append(imageURL)
    return .just(.requestNoteDataDidChanged(requestNote))
  }
}

// MARK: Add Stock Items

extension CreateNoteViewReactor {
  private func makeStockSectionItem(_ stock: NoteStock) -> Observable<Mutation> {
    let reator = NoteStockCellReactor(
      payload: .init(name: stock.name,
                     rate: stock.changeRate ?? 0.0)
    )
    
    let sectionItem = NoteSectionItem.stock(reator)
    
    var requestNote = self.currentState.requestNote
    requestNote.stocks.append(stock)
    
    return .concat([
      .just(.requestNoteDataDidChanged(requestNote)),
      .just(.fetchStockSection(sectionItem))
    ])
  }
  
  private func makeLinkSectionItem(_ url: String) -> Observable<Mutation> {
    let linkReactor = NoteLinkCellReactor(dependency: .init(
      service: self.dependency.linkPreviewService),
                                          payload: url
    )
    
    let linkSectionItem: NoteSectionItem = NoteSectionItem.link(linkReactor)
    
    var requestNote = self.currentState.requestNote
    requestNote.links.append(url)
    
    return .concat([
      .just(.requestNoteDataDidChanged(requestNote)),
      .just(.fetchLinkSection(linkSectionItem))
    ])
  }
}

// MARK: TextInput DidChanged
extension CreateNoteViewReactor {
  private func makeTitleAndContent(_ title: String, _ content: String) -> Observable<Mutation> {
    
    let shouldButtonEnabled = !(title.isEmpty || content.isEmpty)
    
    var requestNote = self.currentState.requestNote
    requestNote.title = title
    requestNote.content = content
    
    return Observable.concat([
      .just(.requestNoteDataDidChanged(requestNote)),
      .just(.shouldRegisterButtonEnabeld(shouldButtonEnabled))
    ])
  }
}

// MARK: LinkButton DidTapped

extension CreateNoteViewReactor {
  private func linkButtonDidTapped() -> Observable<Mutation> {
    
    self.dependency.coordinator.transition(to: .popUp(type: .textInput(self.addLinkURLCompletionRelay)), using: .modal, animated: false)
    
    return .empty()
  }
}

// MARK: RegisterButton DidTapped

extension CreateNoteViewReactor {
  private func registerButtonDidTapped() -> Observable<Mutation> {
    
self.dependency.coordinator.transition(
     to: .popUp(type: .list(self.addStickerCompletionRelay)),
     using: .modal,
     animated: false,
     completion: nil
)
    
    return .empty()
  }
  
  private func addStickerAndAddNote(_ sticker: Sticker) -> Observable<Mutation> {
    var requestNote = self.currentState.requestNote
    requestNote.sticker = sticker
    
    return Observable.concat([
      .just(.requestNoteDataDidChanged(requestNote)),
      self.registNoteAndDismissView()
    ])
  }
  
  private func registNoteAndDismissView() -> Observable<Mutation> {
    return self.dependency.service.request(NoteAPI.create(dto: self.currentState.requestNote))
      .map(Note.self)
      .asObservable()
      .map { String($0.id) }
      .flatMap { [weak self] noteID -> Observable<Mutation> in
        if noteID.isNotEmpty {
          return self?.dismissView() ?? .empty()
        } else {
          return .empty()
        }
      }
  }
}

// MARK: - Update Button Did Tap

extension CreateNoteViewReactor {
  
  private func updateButtonDidTapped() -> Observable<Mutation> {
    
    self.dependency.coordinator.transition(to: .popUp(type: .list(self.updateStickerCompletionRelay)),
                                           using: .modal,
                                           animated: false,
                                           completion: nil)
    
    return .empty()
  }
  
  private func addStickerAndUpdateNote(_ sticker: Sticker) -> Observable<Mutation> {
    var requestNote = self.currentState.requestNote
    requestNote.sticker = sticker
    
    return Observable.concat([
      .just(.requestNoteDataDidChanged(requestNote)),
      self.updateNoteAndDismissView()
    ])
  }
  
  private func updateNoteAndDismissView() -> Observable<Mutation> {
    return self.dependency.service.request(NoteAPI.update(dto: self.currentState.requestNote))
      .map(Note.self)
      .asObservable()
      .flatMap { [weak self] note -> Observable<Mutation> in
        return self?.dimissViewWithUpdateCompletion(note) ?? .empty()
      }
  }
  
  private func dimissViewWithUpdateCompletion(_ note: Note) -> Observable<Mutation> {
    
    guard "\(note.id)".isNotEmpty else { return .empty() }
    
    self.dependency.coordinator.close(
      style: .dismiss,
      animated: true,
      completion: { [weak self] in
        self?.payload.updateCompletionRelay?.accept(note)
      }
    )
    
    return .empty()
  }
}

// MARK: - StockItem Edit & Delete

extension CreateNoteViewReactor {
  private func noteItemDidDeleted(_ indexPath: IndexPath) -> Observable<Mutation> {
    
    guard let section = self.currentState.sections[safe: indexPath.section],
          let sectionItem = section.items[safe: indexPath.row] else { return .empty() }
    
    var requestNote = self.currentState.requestNote
    
    var changedMutation: Observable<Mutation>
    
    let row = indexPath.row
    
    switch sectionItem {
      case .stock:
        requestNote.stocks.remove(at: row)
        changedMutation = .just(.stockItemDidDeleted(row))
      case .link:
        requestNote.links.remove(at: row)
        changedMutation = .just(.linkItemDidDeleted(row))
      case .addStock, .content, .image:
        changedMutation = .empty()
    }
    
    return Observable.concat([
      .just(.requestNoteDataDidChanged(requestNote)),
      changedMutation
    ])
  }
  
  private func showStockItemEditView(_ index: IndexPath) -> Observable<Mutation> {
    
    guard let sectionItem = self.currentState.sections[NoteSection.Identity.stock.rawValue].items[safe: index.row] else {
      return .empty()
    }
    
    if case let NoteSectionItem.stock(reactor) = sectionItem {
      let stockItem = reactor.currentState.payload
      
      self.lastEditableStockCellIndexPath = index
      
      self.dependency.coordinator.transition(
        to: .stockRateInput(
          payload: .init(
            name: stockItem.name,
            completion: self.stockItemEditCompletionRelay
          ),
          editMode: .modify
        ),
        using: .modal,
        animated: true,
        completion: nil
      )
    }
    
    return .empty()
  }
  
  private func stockItemDidUpdated(_ stock: NoteStock) -> Observable<Mutation> {
    
    guard let indexPath = self.lastEditableStockCellIndexPath,
          let sectionItem = self.currentState.sections[NoteSection.Identity.stock.rawValue].items[safe: indexPath.row]
    else { return .empty() }
    
    if case let NoteSectionItem.stock(reactor) = sectionItem {
      reactor.action.onNext(.payloadDidChanged(stock))
      self.lastEditableStockCellIndexPath = nil
      
      var requestNote = self.currentState.requestNote
      requestNote.stocks.remove(at: indexPath.row)
      requestNote.stocks.insert(stock, at: indexPath.row)
      
      return .just(.requestNoteDataDidChanged(requestNote))
    }
    
    return .empty()
  }
}


// MARK: - Changed EmptyStockItem

extension CreateNoteViewReactor {
  private func emptyStockItemDidChanged(by count: Int) -> Observable<Mutation> {
    let isEnabeld = count < CreateNoteViewReactor.stockItemMaxCount
    let reactor = EmptyNoteStockCellReactor(isEnabled: isEnabeld)
    let sectionItem = NoteSectionItem.addStock(reactor)
    return .just(.fetchEmptyStockItem(sectionItem))
  }
}

typealias CreateNoteSectionType = (AppAuthorizationType, AppCoordinatorType) -> [NoteSection]

let createDiarySectionFactory: CreateNoteSectionType = { authorization, coordinator -> [NoteSection] in
  var sections: [NoteSection] = [
    NoteSection(identity: .content, items: []),
    NoteSection(identity: .stock, items: []),
    NoteSection(identity: .addStock, items: []),
    NoteSection(identity: .link, items: []),
    NoteSection(identity: .image, items: [])
  ]
  
  let contentReactor: NoteContentCellReactor = NoteContentCellReactor(payload: .init(title: "", content: ""))
  let contentSectionItem: NoteSectionItem = NoteSectionItem.content(contentReactor)
  
  let addStockReactor: EmptyNoteStockCellReactor = EmptyNoteStockCellReactor(isEnabled: true)
  let addStockSectionItem: NoteSectionItem = NoteSectionItem.addStock(addStockReactor)
  
  let imageReactor: NoteImageCellReactor = NoteImageCellReactor(dependency: .init(factory: noteImageSectionFactory))
  let imageSectionItem: NoteSectionItem = NoteSectionItem.image(imageReactor)

  sections[NoteSection.Identity.content.rawValue].items = [contentSectionItem]
  sections[NoteSection.Identity.addStock.rawValue].items = [addStockSectionItem]
  sections[NoteSection.Identity.image.rawValue].items = [imageSectionItem]

  return sections
}

// MARK: - Dependency Logic

extension CreateNoteViewReactor {
  private func dismissView() -> Observable<Mutation> {
    self.dependency.coordinator.close(style: .dismiss,
                                      animated: true,
                                      completion: nil)
    
    return .empty()
  }
  
  private func presentAddStockView() -> Observable<Mutation> {
    self.dependency.coordinator.transition(
      to: .addStock(completion: self.addStockCompletionRelay),
      using: .modal,
      animated: true,
      completion: nil
    )
    
    return .empty()
  }
}

typealias ModifiableNoteSectionType = (NoteRequestDTO, LinkPreViewServiceType) -> [NoteSection]

let modifiableNoteSectionFactory: (NoteRequestDTO, LinkPreViewServiceType) -> [NoteSection] = { note, previewService -> [NoteSection] in
  var sections: [NoteSection] = [
    NoteSection(identity: .content, items: []),
    NoteSection(identity: .stock, items: []),
    NoteSection(identity: .addStock, items: []),
    NoteSection(identity: .link, items: []),
    NoteSection(identity: .image, items: [])
  ]
  
  let contentReactor: NoteContentCellReactor = NoteContentCellReactor(payload: .init(title: note.title, content: note.content))
  let contentSectionItem: NoteSectionItem = NoteSectionItem.content(contentReactor)
  
  if note.stocks.isNotEmpty {
    let sectionItems = note.stocks
      .map { NoteStockCellReactor(payload: .init(name: $0.name, rate: $0.changeRate ?? 0)) }
      .map { NoteSectionItem.stock($0) }
    
    sections[NoteSection.Identity.stock.rawValue].items = sectionItems
  }
  
  let isEnabled = note.stocks.count < CreateNoteViewReactor.stockItemMaxCount
  
  let addStockReactor: EmptyNoteStockCellReactor = EmptyNoteStockCellReactor(isEnabled: isEnabled)
  let addStockSectionItem: NoteSectionItem = NoteSectionItem.addStock(addStockReactor)
  
  let imageReactor: NoteImageCellReactor = NoteImageCellReactor(
    dependency: .init(
      factory: noteImageSectionFactory
    ),
    images: note.images.map { NoteImage(id: 0, url: $0) }
  )
  
  let imageSectionItem: NoteSectionItem = NoteSectionItem.image(imageReactor)
  
  let linkSectionItems = note.links
    .map { NoteLinkCellReactor(dependency: .init(service: previewService), payload: $0) }
    .map { NoteSectionItem.link($0) }
  
  sections[NoteSection.Identity.link.rawValue].items = linkSectionItems
  
  sections[NoteSection.Identity.content.rawValue].items = [contentSectionItem]
  sections[NoteSection.Identity.addStock.rawValue].items = [addStockSectionItem]
  sections[NoteSection.Identity.image.rawValue].items = [imageSectionItem]
  
  return sections
}
