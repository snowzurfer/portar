//
//  Scene.swift
//  portar
//
//  Created by Alberto Taiuti on 11/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import Foundation;

class AnchoredSceneDiskData: NSObject, Codable {
  let anchorUrl: URL;
  let sceneUrl: URL;
  
  enum CodingKeys: String, CodingKey {
    case anchorUrl = "anchor_url";
    case sceneUrl = "scene_url";
  };
  
  init(anchorUrl au: URL, sceneUrl su: URL) {
    anchorUrl = au;
    sceneUrl = su;
  } 
}
