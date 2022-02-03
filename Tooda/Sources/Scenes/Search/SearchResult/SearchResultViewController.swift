//
//  SearchResultViewController.swift
//  Tooda
//
//  Created by Jinsu Park on 2021/12/12.
//  Copyright © 2021 DTS. All rights reserved.
//

import UIKit

import ReactorKit
import RxSwift
import RxCocoa
import RxDataSources
import Then
import SnapKit

final class SearchResultViewController: BaseViewController<SearchResultReactor> {

  // MARK: Custom Action

  let rxSearch = PublishRelay<String>()


  // MARK: Initializing

  init(reactor: SearchResultReactor) {
    super.init()
    self.reactor = reactor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  // MARK: UI

  private let tableView = UITableView().then {
    $0.backgroundColor = .gray5
    $0.separatorStyle = .none
    $0.register(NoteListCell.self)
    $0.estimatedRowHeight = 40.0
    $0.rowHeight = UITableView.automaticDimension
    $0.contentInset = .init(vertical: 16.0)
    $0.keyboardDismissMode = .onDrag
  }

  private let emptyView = SearchResultEmptyView().then {
    $0.isHidden = true
  }


  // MARK: Configuring

  override func configureUI() {
    self.view.do {
      $0.addSubview(self.tableView)
      $0.addSubview(self.emptyView)
    }
  }

  override func configureConstraints() {
    self.tableView.snp.makeConstraints {
      $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
      $0.bottom.equalTo(self.view.keyboardLayoutGuide.snp.top)
      $0.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
      $0.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
    }

    self.emptyView.snp.makeConstraints {
      $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
      $0.bottom.equalToSuperview()
      $0.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
      $0.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
    }
  }


  // MARK: Bind

  override func bind(reactor: SearchResultReactor) {
    // Action

    self.rxSearch
      .asObservable()
      .map { SearchResultReactor.Action.search(text: $0) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.tableView.rx.itemSelected
      .map { SearchResultReactor.Action.didTapNote(index: $0.item) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    // State

    reactor.state
      .map { $0.notes }
      .do(onNext: { [weak self] items in
        let isItemsEmpty = items.isEmpty
        self?.tableView.isHidden = isItemsEmpty
        self?.emptyView.isHidden = !isItemsEmpty
      })
      .bind(to: self.tableView.rx.items(
        cellIdentifier: NoteListCell.reuseIdentifier,
        cellType: NoteListCell.self
      )) { _, note, cell in
        cell.configure(with: note)
      }.disposed(by: self.disposeBag)
  }
}
