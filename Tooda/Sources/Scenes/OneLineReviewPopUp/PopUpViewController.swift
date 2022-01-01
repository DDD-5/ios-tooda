//
//  PopUpViewController.swift
//  Tooda
//
//  Created by 황재욱 on 2021/12/05.
//  Copyright © 2021 DTS. All rights reserved.
//

import UIKit

import RxCocoa
import RxSwift

class PopUpViewController: BaseViewController<PopUpReactor> {
  
  // MARK: - Constants
  
  enum Font {
    static let popupTitle = TextStyle.subTitleBold(color: .gray1)
    static let bottomButtonTitle = TextStyle.subTitleBold(color: .white)
  }
  
  // MARK: - UI Components
  
  private let dimmedView = UIView().then {
    $0.backgroundColor = .black.withAlphaComponent(0.4)
  }
  
  private let optionsPopUpView = OptionsPopUpView().then {
    $0.setTitle(with: "오늘의 한줄평", style: Font.popupTitle)
    $0.setBottomButtonTitle(with: "작성 완료", style: Font.bottomButtonTitle)
    $0.isHidden = true
    $0.alpha = 0
  }
  
  private let textInputPopUpView = TextInputPopUpView().then {
    $0.setTitle(with: "URL 입력", style: Font.popupTitle)
    $0.setBottomButtonTitle(with: "추가", style: Font.bottomButtonTitle)
    $0.isHidden = true
    $0.alpha = 0
  }
  
  private let displayPopUpAnimator = UIViewPropertyAnimator(
    duration: 0.4,
    curve: .easeOut
  )
  
  // MARK: - Con(De)structor
  
  init(reactor: PopUpReactor) {
    super.init()
    self.reactor = reactor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Overridden: ParentClass
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    showPopUpView()
  }
  
  override func configureUI() {
    super.configureUI()
    
    view.do {
      $0.backgroundColor = .clear
      $0.addSubview(dimmedView)
    }
    
    dimmedView.addSubviews(
      optionsPopUpView,
      textInputPopUpView
    )
  }
  
  override func configureConstraints() {
    super.configureConstraints()
    
    dimmedView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    optionsPopUpView.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
    
    textInputPopUpView.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
  }
  
  // MARK: - Private methods
  
  private func showPopUpView() {
    guard let type = reactor?.dependency.type else { return }
    switch type {
    case .list:
      optionsPopUpView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
      displayPopUpAnimator.do {
        $0.addAnimations {
          self.optionsPopUpView.isHidden = false
          self.optionsPopUpView.transform = .identity
          self.optionsPopUpView.alpha = 1
        }
      }
    case .textInput:
      textInputPopUpView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
      displayPopUpAnimator.do {
        $0.addAnimations {
          self.textInputPopUpView.isHidden = false
          self.textInputPopUpView.transform = .identity
          self.textInputPopUpView.alpha = 1
        }
      }
    }
    displayPopUpAnimator.startAnimation()
  }
}
