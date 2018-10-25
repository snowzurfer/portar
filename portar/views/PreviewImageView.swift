//
//  PreviewImageView.swift
//  portar
//
//  Created by Alberto Taiuti on 19/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import UIKit;

class PreviewImageView: UIImageView {

  override func draw(_ rect: CGRect) {
    // Draw borders around

    
//    let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners,
//                            cornerRadii: CGSize(width: 2.0, height: 2.0));
    let path = UIBezierPath(ovalIn: rect);
    
    UIColor.lightGray.setStroke();
    UIColor.red.setFill();
    path.lineWidth = 10;
    path.stroke();
    path.fill();
  }

}
