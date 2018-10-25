//
//  TakePicVC.swift
//  portar
//
//  Created by Alberto Taiuti on 08/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import UIKit;
import AVFoundation;
import CocoaLumberjack;
import SceneKit;
import ARKit;

class CreateNewMapVC: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
  @IBOutlet weak var startMappingBtn: UIButton!;
  @IBOutlet weak var arScnView: ARSCNView!;
  @IBOutlet weak var infoLabel: UILabel!;
  @IBOutlet weak var movePhoneLabel: UILabel!;
  @IBOutlet weak var sceneInfoFX: UIVisualEffectView!;
  @IBOutlet weak var progBar: UIProgressView!

  
  /// Convenience accessor for the session owned by ARSCNView.
  var arSession: ARSession {
    return arScnView.session;
  }
  
  let arWorldTrackingConfig = ARWorldTrackingConfiguration();
  
  /// The states in which this viewcontroller can be
  enum MappingState {
    case mapping;
    case mapped;
  };
  
  /// The current state of this part of the application
  var currentState = MappingState.mapping;

  /// Lazily return a camera session
  // TODO Rm, kept here as a reference as to how to lazy initialisation
//  lazy var cameraSession: AVCaptureSession = {
//    let s = AVCaptureSession();
//    s.sessionPreset = AVCaptureSession.Preset.photo;
//    return s;
//  }();

  override func viewDidLoad() {
    super.viewDidLoad();
    
    // Set the view's delegate
    arScnView.delegate = self;
    arScnView.session.delegate = self;
    
    // Show statistics such as fps and timing information
    arScnView.showsStatistics = true;
    // Enable Default Lighting - makes the 3D text a bit poppier.
    arScnView.autoenablesDefaultLighting = true;
    arScnView.automaticallyUpdatesLighting = true;
    
    // Show the world origin
    arScnView.debugOptions = [ARSCNDebugOptions.showWorldOrigin];
    
    // Set the scene to the view
    arScnView.scene = SCNScene();
    
    /*
     Prevent the screen from being dimmed after a while as users will likely
     have long periods of interaction without touching the screen or buttons.
     */
    UIApplication.shared.isIdleTimerDisabled = true;
    
    // Setup the configuration
    arWorldTrackingConfig.worldAlignment = .gravity;
    arWorldTrackingConfig.planeDetection = [.horizontal, .vertical];
    // Automatically create environment texturing for PBR
    arWorldTrackingConfig.environmentTexturing = .automatic;
    
    progBar.progress = 0;
  
    DDLogInfo("CreateNewMapVC loaded");
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated);
    
    resetTracking();
    
    DDLogInfo("CreateNewMapVC will appear");
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillAppear(animated);
    
    arSession.pause();
  }

  var msgVC: SavingSceneVC?;
  
  @IBAction func onStartMappingTapped(_ sender: Any) {
    
    // Switch view
    msgVC =
      self.storyboard?.instantiateViewController(withIdentifier: "SavingSceneVC")
      as? SavingSceneVC;
    if (msgVC == nil) {
      DDLogError("Failed to cast the view");
      return;
    }
    
    DDLogInfo("Displaying info message about data being saved");
    DispatchQueue.main.async {
      self.startMappingBtn.isHidden = true;
      self.present(self.msgVC!, animated: true, completion: nil);
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning();
      // Dispose of any resources that can be recreated.
  }
  
  func resetTracking() {
    portar.resetTracking(for: arScnView, withConf: arWorldTrackingConfig);
    currentState = .mapping;
    
    DDLogInfo("Reset tracking");
  }
  
  // MARK: - ARSessionDelegate
  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    guard let frame = session.currentFrame else { return };
    updateSessionTrackingInfo(for: frame,
                              camTrackingState: frame.camera.trackingState,
                              mappingState: frame.worldMappingStatus);
  }
  
  func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    guard let frame = session.currentFrame else { return };
    updateSessionTrackingInfo(for: frame,
                              camTrackingState: frame.camera.trackingState,
                              mappingState: frame.worldMappingStatus);
  }
  
  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    guard let frame = session.currentFrame else { return };
    updateSessionTrackingInfo(for: frame,
                              camTrackingState: camera.trackingState,
                              mappingState: frame.worldMappingStatus);
    
  }
  
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    updateSessionTrackingInfo(for: frame,
                              camTrackingState: frame.camera.trackingState,
                              mappingState: frame.worldMappingStatus);
  }
  
  // Updates the session info label depending on the state of the AR session
  private func updateSessionTrackingInfo(for frame: ARFrame,
                                      camTrackingState: ARCamera.TrackingState,
                                      mappingState: ARFrame.WorldMappingStatus) {
    // Update the UI to provide feedback on the state of the AR experience.
    let message: String;
    
    
    if (currentState != .mapping) {
      return;
    }
    
    DDLogDebug("Cam tracking, \(camTrackingState)")

    switch camTrackingState {
      //            case .normal where frame.anchors.isEmpty:
      //                // No planes detected; provide instructions for this app's AR interactions.
      //                message = "Move the device around to detect horizontal surfaces.";
      
      case .normal:
        // No feedback needed when tracking is normal and planes are visible.
        message = ""
      
      case .notAvailable:
        message = "Tracking unavailable.";
      
      case .limited(.excessiveMotion):
        message = "Tracking limited - Move the device more slowly.";
      
      case .limited(.insufficientFeatures):
        message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions.";
      
      case .limited(.initializing):
        message = "Initializing AR session - Move the device slowly.";
      
      case .limited(.relocalizing):
        message = "Relocalizing AR session - Move the device slowly.";
    }
    
    // Wait until the tracking state for world mapping is of the best
    // quality, i.e. "mapped"
    switch mappingState {
    case .notAvailable:
      DDLogDebug("Bad world tracking, not available"); progBar.progress = 0;
      
      case .limited:
        DDLogDebug("Bad world tracking, limited"); progBar.progress = 0.5;
      
      case .extending:
        DDLogDebug("Bad world tracking, extending"); progBar.progress = 0.8;
      
      case .mapped:
        DDLogDebug("Best mapping available"); progBar.progress = 1;
      
    }
    if (mappingState != .mapped) {
      print(mappingState);
    }
 
    DispatchQueue.main.async {
      self.infoLabel.text = message;
      self.sceneInfoFX.isHidden = message.isEmpty;
    }
    
    if (mappingState == .mapped) {
      DDLogDebug("Finished mapping, starting to save scene.");
      sceneInfoFX.isHidden = true;
      infoLabel.isHidden = true;
      progBar.isHidden = true;
      
      currentState = .mapped;
      
      // Place an anchor for the root node
      let anchor = ARAnchor(name: Consts.AnchorNames.root,
                            transform: arScnView.scene.rootNode.simdTransform);
      arSession.add(anchor: anchor);
      
      // Switch view
      msgVC =
        self.storyboard?.instantiateViewController(withIdentifier: Consts.VCsIDs.savingScene)
        as? SavingSceneVC;
      if (msgVC == nil) {
        DDLogError("Failed to cast the view");
        return;
      }
      
      DDLogInfo("Displaying info message about data being saved");
      DispatchQueue.main.async {
        self.startMappingBtn.isHidden = true;
        self.present(self.msgVC!, animated: false, completion: {
          DDLogDebug("Finished launching loading view")
        });
      }
      
      // Dispatch starting to save the world map
      arScnView.session.getCurrentWorldMap(completionHandler: { worldMap, error in
        guard let map = worldMap else {
          DDLogError("Error: \(error!.localizedDescription)");
          return;
        };
        
        do {
          let data = try NSKeyedArchiver.archivedData(withRootObject: map,
                                                      requiringSecureCoding: true)
          
          // Now save the map to disk
          
          //Get Short Time String
          let imgNameUUID = UUID().uuidString + ".arworldmap";
          
          // Save image to disk
          guard let imgUrl = AnchoredScenesManager.inst.writeImg(worldMapData: data,
                                                                 name: imgNameUUID)
            else {
              DDLogError("Failed to write image.");
              return;
          };
          
          // Create a new scene and save it to disk
          let scnName = UUID().uuidString + ".scn";
          DDLogInfo("Scene name: \(scnName)");
          guard let scnUrl = (AnchoredScenesManager.inst.writeSCNScene(scene: SCNScene(),
                                                                       name: scnName) {
            (prog, err, stop) in
            guard err == nil else {
              DDLogError("Error saving scene: \(String(describing: error))");
              return;
            }
          })
            else {
              DDLogError("Failed to write scene.");
              return;
          };
          
          DDLogInfo("Outside of writeSNScene from Anchor Manager in TakePicVC");
          
          // Create record for this combo scene + anchorImg
          let sceneWithAnchor = AnchoredSceneDiskData(anchorUrl: imgUrl,
                                                      sceneUrl: scnUrl);
          if (!AnchoredScenesManager.inst.addAnchoredScene(anchoredScene: sceneWithAnchor)) {
            return;
          }
          

          // Switch view
          guard let newVC =
            self.storyboard?.instantiateViewController(withIdentifier: Consts.VCsIDs.browseAndAdd)
              as? ARSceneVC
            else {
              DDLogError("Failed to cast the view");
              return;
          };
          
          DDLogInfo("Switching to main view controller");
          DispatchQueue.main.async {
            // Launch the other view once the modal view with the info message has
            // been dismissed
            self.msgVC!.dismiss(animated: false, completion: {
              DDLogInfo("Switching to AR view controller");
              DispatchQueue.main.async {
                // Launch the other view once the modal view with the info message has
                // been dismissed
                self.show(newVC, sender: nil);
              }
            });
          }
        }
        catch {
          fatalError("can't encode map");
        }
      })
    }
  }
}
