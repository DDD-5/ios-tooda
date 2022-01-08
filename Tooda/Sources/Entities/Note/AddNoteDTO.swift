//
//  AddNoteDTO.swift
//  Tooda
//
//  Created by Lyine on 2022/01/08.
//

import Foundation

struct AddNoteDTO {
  var title: String
  var content: String
  var stocks: [NoteStock]
  var links: [String]
  var images: [String]
  var sticker: Sticker
}

extension AddNoteDTO {
  
  init() {
    title = ""
    content = ""
    stocks = []
    links = []
    images = []
    sticker = .wow
  }
  
  func asBodyParameters() -> [String: Any] {
    var parameters: [String: Any] = [:]
    
    parameters.concat(dict: [
      "title": title,
      "content": content,
      "sticker": sticker
    ])
    
    if stocks.isNotEmpty {
      parameters.concat(dict: [
        "stocks": stocks
      ])
    }
    
    if links.isNotEmpty {
      parameters.concat(dict: [
        "links": links
      ])
    }
    
    if images.isNotEmpty {
      parameters.concat(dict: [
        "images": images
      ])
    }
    
    return parameters
  }
}
