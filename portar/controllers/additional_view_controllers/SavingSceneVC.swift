//
//  SavingSceneVC.swift
//  portar
//
//  Created by Alberto Taiuti on 12/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import UIKit;

class SavingSceneVC: UIViewController {

  @IBOutlet weak var acitivityIndicator: UIActivityIndicatorView!;
  
  @IBOutlet weak var popupView: UIView!
  
  override func viewDidLoad() {
    popupView.layer.cornerRadius = 5;
    popupView.layer.masksToBounds = true;
  }
  
  override func viewWillAppear(_ animated: Bool) {
    acitivityIndicator.startAnimating();
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    acitivityIndicator.stopAnimating();
    
//    if let vcToPresent = self.arScnVCName {
//      // Switch view
//      guard let newVC =
//        self.storyboard?.instantiateViewController(withIdentifier: vcToPresent)
//          as? ARSceneVC
//        else {
//          DDLogError("Failed to cast the view");
//          return;
//      };
//
//      DDLogInfo("Switching to AR view controller");
//      DispatchQueue.main.async {
//        // Launch the other view once the modal view with the info message has
//        // been dismissed
//        self.performSegue(withIdentifier: "toARScnVCFromMsgInfo", sender: nil);
//      }
//    }
  }
  
}
