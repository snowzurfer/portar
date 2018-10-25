//
//  AnchorPicsManager.swift
//  portar
//
//  Created by Alberto Taiuti on 11/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import Foundation;
import CocoaLumberjack;
import SceneKit;

/// Manages anchor pictures and their relative scenes
class AnchoredScenesManager {
  /// Singleton pattern
  static let inst = AnchoredScenesManager();
  
  let fileMan: FileManager;
  var anchoredScenes: [AnchoredSceneDiskData] = [AnchoredSceneDiskData]();
  var currentAnchoredSceneData: AnchoredSceneDiskData? = nil;
  
  private let docsDir: URL;
  private let anchorPicsDir: URL;
  private let scenesDir: URL;
  private let managerFile: URL;
  private let defaultAnchorPicsDirName = "pics/anchors";
  private let defaultScenesDirName = "scenes";
  private let defaultAnchorImgName = "anchorImg.jpg";
  private let managerDirName = "manager";
  private let managerFileName = "managerFile";
  
  /// Initilizes internal vars and attempts to see if the current anchor image
  /// is available
  private init() {
    fileMan = FileManager.default;
    
    docsDir = fileMan.urls(for: .documentDirectory, in: .userDomainMask)[0];
    anchorPicsDir = docsDir.appendingPathComponent(defaultAnchorPicsDirName, isDirectory: true);
    scenesDir = docsDir.appendingPathComponent(defaultScenesDirName, isDirectory: true);
    let managerDir = docsDir.appendingPathComponent(managerDirName, isDirectory: true);
    managerFile = managerDir.appendingPathComponent(managerFileName, isDirectory: false);

    do {
      try fileMan.createDirectory(atPath: anchorPicsDir.path,
                                  withIntermediateDirectories: true,
                                  attributes: nil);
      try fileMan.createDirectory(atPath: scenesDir.path,
                                  withIntermediateDirectories: true,
                                  attributes: nil);
      try fileMan.createDirectory(atPath: managerDir.path,
                                  withIntermediateDirectories: true,
                                  attributes: nil);
    } catch let error as NSError {
      DDLogError("\(error.localizedDescription)");
    }
    
    // Load scenes
    guard let rawData = fileMan.contents(atPath: managerFile.path)
    else {
      DDLogError("Couldn't get raw data");
      return;
    }
    
    let decoder = PropertyListDecoder();
    
    do {
      anchoredScenes = try decoder.decode([AnchoredSceneDiskData].self, from: rawData);
    }
    catch {
      DDLogError("Couldn't decode anchored scenes data");
      return;
    }
  }
  
  /// Save an image at the default location
  /// Return the url of the saved img on success, nil on failure
  func writeImg(worldMapData map: Data, name n: String) -> URL? {
    let imgFullUrl = anchorPicsDir.appendingPathComponent(n, isDirectory: false);
    
    if(fileMan.fileExists(atPath: imgFullUrl.path)) {
      DDLogError("Image \(imgFullUrl) is already present on disk.");
      return nil;
    }
    
    if (!fileMan.createFile(atPath: imgFullUrl.path, contents: map,
                            attributes: nil)) {
      DDLogError("FileManager failed to write image \(imgFullUrl) to disk.");
    }
    
    // We save only the URL from the docs dir down because the docs dir is
    // mounted at different points every run
    let imgUrl = URL(fileURLWithPath: n);
    DDLogInfo("New img url: \(imgUrl)");
    
    return imgUrl;
  }
  
  func writeSCNScene(scene scn: SCNScene, name n: String,
                     progressHandler: SCNSceneExportProgressHandler? = nil) -> URL? {
    let scnFullUrl = scenesDir.appendingPathComponent(n, isDirectory: false);
    
    if(fileMan.fileExists(atPath: scnFullUrl.path)) {
      DDLogWarn("Scne \(scnFullUrl) is already present on disk.");
    }
    
    DDLogInfo("About to start writing scene");
    if(!scn.write(to: scnFullUrl, options: nil, delegate: nil,
                  progressHandler: progressHandler)) {
      DDLogError("Failed to write scene \(scnFullUrl) to disk.");
      return nil;
    }
    DDLogInfo("Finished writing scene");
    
    let scnUrl = URL(fileURLWithPath: n);
    DDLogInfo("Written scn url: \(scnUrl)");
    
    return scnUrl;
  }
  
  /// Override the current scene on disk with an updated one
  func updateCurrentScene(scene scn: SCNScene,
                          progressHandler: SCNSceneExportProgressHandler? = nil) {
    guard let (scnUrl, _) = getCurrentSceneAndAnchorImageURLs() else {
      return;
    };
    
    DDLogInfo("LastpathComponent: \(scnUrl.lastPathComponent)");
    let _ = writeSCNScene(scene: scn, name: scnUrl.lastPathComponent,
                          progressHandler: progressHandler);
  }
  
  func addAnchoredScene(anchoredScene scn: AnchoredSceneDiskData) -> Bool {
    let scnUrl = scenesDir.appendingPathComponent(
      scn.sceneUrl.path, isDirectory: false);
    let imgUrl = anchorPicsDir.appendingPathComponent(
      scn.anchorUrl.path, isDirectory: false);
    
    if (!fileMan.fileExists(atPath: imgUrl.path) ||
      !fileMan.fileExists(atPath: scnUrl.path)) {
      DDLogError("Files do not exists on disk.");
      return false;
    }
    
    anchoredScenes.append(scn);
    
    // Set the idx of the current scene to use
    UserDefaults.standard.set(anchoredScenes.count - 1,
                              forKey: Consts.AppInternalKeys.currentScene)
    
    saveManagerToDisk();
    return true;
  }
  
  func getCurrentSceneAndAnchorImageURLs() -> (URL, URL)? {
    if (anchoredScenes.count == 0) {
      DDLogError("No scenes in the manager!");
      return nil;
    }
    
    let idxCurrentScene = UserDefaults.standard.integer(forKey: Consts.AppInternalKeys.currentScene);
    
    if (idxCurrentScene < 0 || anchoredScenes.count - 1 < idxCurrentScene) {
      DDLogError("Invalid idxCurrentScene idx: \(idxCurrentScene)");
      return nil;
    }
    DDLogInfo("IdxCurrentScene idx: \(idxCurrentScene)");
    
    currentAnchoredSceneData = anchoredScenes[idxCurrentScene];
    let scnUrl = scenesDir.appendingPathComponent(
      currentAnchoredSceneData!.sceneUrl.path, isDirectory: false);
    let imgUrl = anchorPicsDir.appendingPathComponent(
      currentAnchoredSceneData!.anchorUrl.path, isDirectory: false);
    
    return (scnUrl, imgUrl);
  }
  
  func loadCurrentSceneAndAnchorImage() -> (SCNScene, CGImage)? {
    guard let (scnUrl, imgUrl) = getCurrentSceneAndAnchorImageURLs() else {
      return nil;
    };
    
    // Load anchor image
    guard let img = UIImage(contentsOfFile: imgUrl.path)?.cgImage
    else {
      DDLogError("Failed to load image");
      return nil;
    };
    
    // Load scene
    let scene: SCNScene?;
    do {
      scene = try SCNScene(url: scnUrl,
                               options: nil);
    }
    catch let err as NSError {
      DDLogError("Failed to load scene: \(err.localizedDescription)");
      return nil;
    }

    DDLogInfo("Loaded scene \(scnUrl.path) with anchor image \(imgUrl.path )");
    DDLogInfo("Scenes count: \(anchoredScenes.count)");

    return (scene!, img);
  }
  
  /// Write the list of anchored scenes data to disk; we don't write the whole
  /// manager because the rest of the data can be recalculated at runtime
  private func saveManagerToDisk() {
    let encoder = PropertyListEncoder();
    
    let encodedAnchoredScenes: Data?;
    do {
      try encodedAnchoredScenes = encoder.encode(anchoredScenes);
    }
    catch {
      DDLogError("Couldn't encode anchored scenes array.");
      return;
    }
    
    do {
      try encodedAnchoredScenes!.write(to: managerFile);
    } catch {
      DDLogError("Couldn't write anchored scenes array to disk.");
    }
  }
  
  /// Delete all the existing image, scene and metadata information
  func wipeAllExistingData() {
    do {
      DDLogInfo("Wiping anchor images");
      let imgUrls = try fileMan.contentsOfDirectory(atPath: anchorPicsDir.path);
      for iu in imgUrls {
        DDLogInfo("Wiping img: \(iu)");
        let iuUrl = anchorPicsDir.appendingPathComponent(iu);
        try fileMan.removeItem(at: iuUrl);
      }
      
      DDLogInfo("Wiping anchor images");
      let scnUrls = try fileMan.contentsOfDirectory(atPath: scenesDir.path);
      for su in scnUrls {
        DDLogInfo("Scn url: \(su)");
        let suUrl = scenesDir.appendingPathComponent(su);
        try fileMan.removeItem(at: suUrl);
      }
      
      DDLogInfo("Removing manager's list of anchored scenes metadata");
      try fileMan.removeItem(at: managerFile);
    }
    catch {}
  }
}
