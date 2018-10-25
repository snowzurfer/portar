//
//  NewNoteVC.swift
//  portar
//
//  Created by Alberto Taiuti on 17/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import UIKit;
import CocoaLumberjack;

protocol NewNoteVCDelegate {
  func addedNote(title t: String, description d: String);
}

class NewNoteVC: UIViewController {
  
  @IBOutlet weak var vfxView: UIVisualEffectView!;
  
  @IBOutlet weak var titleTextView: UITextField!;
  @IBOutlet weak var descTextView: UITextField!;

  var delegate: NewNoteVCDelegate? = nil;
  
  override func viewDidLoad() {
    super.viewDidLoad()

    vfxView.layer.cornerRadius = 5;
    vfxView.layer.masksToBounds = true;
  }
  
  @IBAction func onAddTapped(_ sender: Any) {
    // Pass data to delegate
    if let d = delegate {
      let title = titleTextView.text ?? "";
      let desc = descTextView.text ?? "";
      
      d.addedNote(title: title, description: desc);
      
      dismiss(animated: true, completion: nil);
    }
    else {
      DDLogWarn("No delegate was set for the New Note modal view");
    }
  }
  
  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      // Get the new view controller using segue.destinationViewController.
      // Pass the selected object to the new view controller.
  }
  */

}
