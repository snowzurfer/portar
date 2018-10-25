//
//  AppDelegate.swift
//  portar
//
//  Created by Alberto Taiuti on 07/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import UIKit;
import ARKit;
import CocoaLumberjack;

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?;

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    guard ARWorldTrackingConfiguration.isSupported else {
      fatalError("""
        ARKit is not available on this device. For apps that require ARKit
        for core functionality, use the `arkit` key in the key in the
        `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
        the app from installing. (If the app can't be installed, this error
        can't be triggered in a production scenario.)
        In apps where AR is an additive feature, use `isSupported` to
        determine whether to show UI for launching AR experiences.
        """); // For details, see https://developer.apple.com/documentation/arkit
    };
    
    // Setup CocoaLumberjack
    DDLog.add(DDTTYLogger.sharedInstance); // TTY = Xcode console
    
    let fileLogger: DDFileLogger = DDFileLogger(); // File Logger
    fileLogger.rollingFrequency = TimeInterval(60*60*24);  // 24 hours
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    DDLog.add(fileLogger);
    
    // Programmatically launch one or another viewcontroller as the first one
    // depending on whether the user has mapped a scene yet or not
    self.window = UIWindow(frame: UIScreen.main.bounds);
    let mainStoryBoard = UIStoryboard(name: Consts.StoryboardsIDs.main,
                                      bundle: nil);
    
    /// For debug purposes, force always the mapping view
    var initialVC: UIViewController? = nil;
//    if (!AnchoredScenesManager.inst.anchoredScenes.isEmpty) {
//      initialVC =
//        mainStoryBoard.instantiateViewController(
//          withIdentifier: Consts.VCsIDs.browseAndAdd) as! ARSceneVC;
//      self.window!.rootViewController = initialVC;
//    }
//    else  {
      initialVC =
        mainStoryBoard.instantiateViewController(
          withIdentifier: Consts.VCsIDs.createNewMap) as! CreateNewMapVC;

//    }
    self.window!.rootViewController = initialVC!;
    
    self.window!.makeKeyAndVisible();
    
    return true
  }
}
