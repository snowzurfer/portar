//
//  AppConstants.swift
//  portar
//
//  Created by Alberto Taiuti on 11/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import Foundation;

/// App-wide constants
struct Consts {
  /// Keys relative to the local app and not to services
  struct AppInternalKeys {
    static let currentScene = "currentScene";
  }
  
  /// Identifiers for the VCs used to present/show them programatically
  struct VCsIDs {
    static let createNewMap = "CreateNewMapVC";
    static let browseAndAdd = "BrowseAndAddVC";
    static let savingScene = "SavingSceneVC";
  }
  
  /// Identifiers for the storyboards used to present/show them programatically
  struct StoryboardsIDs {
    static let main = "Main";
  }
  
  struct AnchorNames {
    static let root = "root";
  }
}
