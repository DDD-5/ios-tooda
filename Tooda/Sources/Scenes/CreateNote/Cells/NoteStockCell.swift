//
//  NoteStockCell.swift
//  Tooda
//
//  Created by Lyine on 2021/05/19.
//  Copyright © 2021 DTS. All rights reserved.
//

import UIKit

import ReactorKit
import SnapKit

class NoteStockCell: BaseTableViewCell, View {
  typealias Reactor = NoteStockCellReactor

  var disposeBag: DisposeBag = DisposeBag()
  
  // MARK: Cell Life Cycle
  
  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }

  func bind(reactor: Reactor) {

  }
}
