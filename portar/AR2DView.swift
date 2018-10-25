//
//  ARView.swift
//  portar
//
//  Created by Alberto Taiuti on 09/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import Foundation;
import ARKit;
import UIKit;

class AR2DView : SCNNode {
  /// Resolution of the image which will be painted on the canvas; use defaults
  var canvasRes = CGSize(width: 512, height: 512);
  
  init(canvasSize cs: CGSize) {
    super.init();
    
    let canvas = SCNBox();
    canvas.width = cs.width;
    canvas.height = cs.height;
    canvas.length = 0.01;
    canvas.chamferRadius = 0.1;
    
    let colors = [UIColor.green, // front
      UIColor.red, // right
      UIColor.blue, // back
      UIColor.yellow, // left
      UIColor.purple, // top
      UIColor.gray] // bottom
    
    let sideMaterials = colors.map { color -> SCNMaterial in
      let material = SCNMaterial()
      material.diffuse.contents = UIColor(red: 158/255, green: 215/255, blue: 245/255,
                                          alpha: 1);
      material.locksAmbientWithDiffuse = true;
      material.lightingModel = .constant;
      
      return material;
    }
    
    canvas.materials = sideMaterials;
    
    // Scale the resolution of the image of the canvas depending on the
    // physical size of the canvas
    let ratio = cs.width / cs.height;
    if (cs.width > cs.height) {
      canvasRes.height = canvasRes.height / ratio;
    }
    else if (cs.width < cs.height) {
      canvasRes.width = canvasRes.width * ratio;
    }
    
    self.geometry = canvas;
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder);
  }
}

class ARNote2DView : AR2DView {
  let margin = CGFloat(32);
  
  init(name n: String, description desc: String) {
    super.init(canvasSize: CGSize(width: 0.12, height: 0.05));
    
    let renderer = UIGraphicsImageRenderer(size: canvasRes);
    let img = renderer.image { (cxt) in
      UIColor(red: 158/255, green: 215/255, blue: 245/255,
              alpha: 1).setFill();
      let rendererSize = CGSize(width: renderer.format.bounds.width,
                                height: renderer.format.bounds.height);
      
      cxt.fill(CGRect(x: 1, y: 1, width: rendererSize.width,
                      height: rendererSize.height));
      
      let paragraphStyle = NSMutableParagraphStyle();
      paragraphStyle.alignment = .center;
      
      let attrsName = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Thin", size: 50)!, NSAttributedString.Key.paragraphStyle: paragraphStyle];
      n.draw(with: CGRect(x: margin, y: margin,
                               width: rendererSize.width - margin,
                               height: 64),
                  options: .usesLineFragmentOrigin,
                  attributes: attrsName, context: nil);
      
      let linePath = UIBezierPath();
      
      linePath.move(to: CGPoint(x: margin, y: 85));
      linePath.addLine(to: CGPoint(x: renderer.format.bounds.width - margin, y: 85));
      UIColor.darkGray.setStroke();
      linePath.lineWidth = 1.0;
      linePath.stroke();
      
      let attrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Thin", size: 32)!, NSAttributedString.Key.paragraphStyle: paragraphStyle];
      
      desc.draw(with: CGRect(x: 32, y: rendererSize.height / 2,
                               width: rendererSize.width - 32,
                               height: rendererSize.height - 128),
                  options: .usesLineFragmentOrigin,
                  attributes: attrs, context: nil);
    }
    
    self.geometry!.materials[0].diffuse.contents = img;
    
    let constraint = SCNBillboardConstraint();
    constraint.freeAxes = .Y;
    self.constraints = [constraint];
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder);
  }
}

class ARProduct2DView : AR2DView {
  
  let margin = CGFloat(32);
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(product p: Product) {
    super.init(canvasSize: CGSize(width: 0.4, height: 0.3));
    
    let renderer = UIGraphicsImageRenderer(size: canvasRes);
    let img = renderer.image { (cxt) in
      UIColor(red: 158/255, green: 215/255, blue: 245/255,
              alpha: 1).setFill();
      cxt.fill(CGRect(x: 1, y: 1, width: renderer.format.bounds.width,
                      height: renderer.format.bounds.height));
      
      let paragraphStyle = NSMutableParagraphStyle();
      paragraphStyle.alignment = .center;
      
      let attrsName = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Thin", size: 36)!, NSAttributedString.Key.paragraphStyle: paragraphStyle];
      p.name.draw(with: CGRect(x: margin, y: margin,
                               width: renderer.format.bounds.width - margin,
                               height: 64),
                  options: .usesLineFragmentOrigin,
                  attributes: attrsName, context: nil);
      
      let linePath = UIBezierPath();
      
      linePath.move(to: CGPoint(x: margin, y: 85));
      linePath.addLine(to: CGPoint(x: renderer.format.bounds.width - margin, y: 85));
      UIColor.darkGray.setStroke();
      linePath.lineWidth = 1.0;
      linePath.stroke();
      
      let attrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Thin", size: 22)!, NSAttributedString.Key.paragraphStyle: paragraphStyle];
      
      let string = p.description;
      string.draw(with: CGRect(x: 32, y: renderer.format.bounds.height / 2,
                               width: renderer.format.bounds.width - 32,
                               height: renderer.format.bounds.height - 128),
                  options: .usesLineFragmentOrigin,
                  attributes: attrs, context: nil);
      
//      linePath.move(to: CGPoint(x: margin, y: height: renderer.format.bounds.height - 140));
//      linePath.addLine(to: CGPoint(x: renderer.format.bounds.width - margin, y: height: renderer.format.bounds.height - 140));
//      UIColor.darkGray.setStroke();
//      linePath.lineWidth = 1.0;
//      linePath.stroke();
//      
//      p.ratind.draw(with: CGRect(x: 32, y: renderer.format.bounds.height - 150,
//                               width: renderer.format.bounds.width - 32,
//                               height: renderer.format.bounds.height - 150),
//                  options: .usesLineFragmentOrigin,
//                  attributes: attrs, context: nil);
    }
    
    self.geometry!.materials[0].diffuse.contents = img;
    
  }
  
  init() {
    super.init(canvasSize: CGSize(width: 0.3, height: 0.2));
    
    let renderer = UIGraphicsImageRenderer(size: canvasRes);
    let img = renderer.image { (cxt) in
      UIColor.darkGray.setStroke();
      cxt.stroke(renderer.format.bounds);
      UIColor(red: 158/255, green: 215/255, blue: 245/255,
              alpha: 1).setFill();
      cxt.fill(CGRect(x: 1, y: 1, width: renderer.format.bounds.width,
                      height: renderer.format.bounds.height));
      
      let paragraphStyle = NSMutableParagraphStyle();
      paragraphStyle.alignment = .center;
      
      let attrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Thin", size: 36)!, NSAttributedString.Key.paragraphStyle: paragraphStyle];
      
      let string = "How much wood would a woodchuck\nchuck if a woodchuck would chuck wood? 😎";
      string.draw(with: CGRect(x: 32, y: 32,
                               width: renderer.format.bounds.width - 32,
                               height: renderer.format.bounds.height - 32),
                  options: .usesLineFragmentOrigin,
                  attributes: attrs, context: nil);
    }

    self.geometry!.materials[0].diffuse.contents = img;
  }
}
