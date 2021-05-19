//
//  DiaryStockCellReactor.swift
//  Tooda
//
//  Created by Lyine on 2021/05/19.
//  Copyright © 2021 DTS. All rights reserved.
//

import ReactorKit

final class DiaryStockCellReactor: Reactor {
	enum Action {
		
	}
	
	enum Mutation {
		
	}
	
	struct State {
		
	}
	
	let initialState: State
	
	init() {
		initialState = State()
	}
	
	func mutate(action: Action) -> Observable<Mutation> {
		return .empty()
	}
	
	func reduce(state: State, mutation: Action) -> State {
		var newState = state
		return newState
	}
}
