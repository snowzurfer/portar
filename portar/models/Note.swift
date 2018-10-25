//
//  Note.swift
//  portar
//
//  Created by Alberto Taiuti on 17/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import Foundation;

struct Note : Codable {
  let title: String;
  let description: String;
  
  init(title t: String, description d: String = "") {
    title = t;
    description = d;
  }
}
