//
//  ARUtils.swift
//  portar
//
//  Created by Alberto Taiuti on 04/06/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import ARKit;

/// Creates a new AR configuration to run on the `session`. Removes anchors.
/// - Tag: ARReferenceImage-Loading
func resetTracking(for arScnView: ARSCNView, withConf conf: ARConfiguration) {
  
  arScnView.session.run(conf,
                        options: [.resetTracking, .removeExistingAnchors]);
  
}
