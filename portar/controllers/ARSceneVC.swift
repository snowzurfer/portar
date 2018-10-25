//
//  ViewController.swift
//  portar
//
//  Created by Alberto Taiuti on 07/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import UIKit;
import SceneKit;
import ARKit;
import CocoaLumberjack;

class ARSceneVC: UIViewController, ARSCNViewDelegate {
    
  @IBOutlet weak var arScnView: ARSCNView!;
  
  @IBOutlet weak var blurView: UIVisualEffectView!;
  
  @IBOutlet weak var previewAnchorImgView: UIImageView!;
  
  /// Prevents restarting the session while a restart is in progress.
  var isRestartAvailable = true;
  
  /// A serial queue for thread safety when modifying the SceneKit node graph.
  let arUpdateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
    ".arSerialSceneKitQueue");
  
  /// Global config for the AR tracking
  let arWorldTrackingConfig = ARWorldTrackingConfiguration();
  
  /// The view controller that displays the status and "restart experience" UI.
  lazy var statusViewController: StatusViewController = {
    return children.lazy.compactMap({
      $0 as? StatusViewController }).first!;
  }();
  
  /// Convenience accessor for the session owned by ARSCNView.
  var arSession: ARSession {
    return arScnView.session;
  }

  /// The set of images to recognise
  var imgsToRecognise = Set<ARReferenceImage>();
  
  /// Name of the loaded scene
  var loadedScnName: String = "No scene loaded.";
  
  /// Cache the loaded anchored scene so that it can be set once and if the
  /// anchor is found
  var anchoredScn: SCNScene? = nil;
  
  /// The states in which this viewcontroller can be
  enum State {
    case badTracking;
    case searchingAnchor;
    case normal;
  };
  
  var anchorFound = false;
  
  /// The current state of this part of the application
  var currentState = State.badTracking;
  
  /// Used to cache the transform of an anchor between when the anchor is
  /// detected and reported and when a node for it is added. This happens
  /// because we show a modal input view to get text for the new node to show.
  var cachedTransform: matrix_float4x4? = nil;
  
  @objc(ABCAnchorNode) class AnchorNode: SCNNode {};
  var anchNode: AnchorNode? = nil;
  
  /// We cache the anchor node once it's added so that it can be removed
  /// before saving the scene. We do that because otherwise everytime the
  /// app is run and the anchor detected, you'd get a new anchor node.
  struct AnchorNodeAndParent {
    let anchorNode: SCNNode;
    let parent: SCNNode;
  }
  var anchorNode: AnchorNodeAndParent? = nil;
  
  override func viewDidLoad() {
    super.viewDidLoad();
    
    // Load scene and anchor image from disk
    guard let (scene, imgData) = AnchoredScenesManager.inst.loadCurrentSceneAndAnchorImage()
    else {
      fatalError("Could not load scene and image from disk!");
    }
    
    if let scn = AnchoredScenesManager.inst.currentAnchoredSceneData {
      loadedScnName = scn.sceneUrl.path;
    }
    
    // Save the scene but don't set it yet; only set it once the anchor has
    // been found
    self.anchoredScn = scene;
    
    // Try to find the anchor node in the scene; if there isn't one,
    // the system will add one when the anchor is found, otherwise the position
    // of the anchor node is set only
    for child in self.anchoredScn!.rootNode.childNodes {
      if child is AnchorNode {
        anchNode = child as? AnchorNode;
        DDLogInfo("Anchor node found in hierarchy");
      }
    }
    
    imgsToRecognise.insert(ARReferenceImage.init(imgData, orientation: .up,
                                                 physicalWidth: 0.33251));
    
    // Set the view's delegate
    arScnView.delegate = self;
    arScnView.session.delegate = self;
    
    // Show statistics such as fps and timing information
    arScnView.showsStatistics = true;
    // Enable Default Lighting - makes the 3D text a bit poppier.
    arScnView.autoenablesDefaultLighting = true
    // Show the world origin
    // arScnView.debugOptions = [ARSCNDebugOptions.showWorldOrigin];
    
    // Set the scene to the view
    arScnView.scene = scene;
    
    /*
     Prevent the screen from being dimmed after a while as users will likely
     have long periods of interaction without touching the screen or buttons.
     */
    UIApplication.shared.isIdleTimerDisabled = true;
    
    // Setup the configuration
    arWorldTrackingConfig.worldAlignment = .gravity;
    arWorldTrackingConfig.planeDetection = [.horizontal, .vertical]
    
    // Setup the preview image view
    previewAnchorImgView.isHidden = true;
    previewAnchorImgView.image = UIImage(cgImage: imgData);
    
    DDLogInfo("ARSceneVC loaded");
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated);
    
    // Run the view's session
    resetTracking();
    
    DDLogInfo("ARSceneVC will appear");
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    arScnView.session.pause();
    
    DDLogInfo("ARSceneVC will disappear");
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning();
    // Dispose of any resources that can be recreated.
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    // Get the new anchor
    if (anchor is ARImageAnchor) {
      
      if let anchNode = self.anchNode {
        anchNode.simdWorldTransform = node.simdWorldTransform;
      }
    }
  }
  
  /// - Tag: ARImageAnchor-Visualizing
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode,
                for anchor: ARAnchor) {
    // Get the new anchor
    if let imageAnchor = anchor as? ARImageAnchor {
      let referenceImage = imageAnchor.referenceImage;
      
      arUpdateQueue.async {
        //         Create a plane to visualize the initial position of the detected image.
        let plane = SCNPlane(width: referenceImage.physicalSize.width,
                             height: referenceImage.physicalSize.height);
        let planeNode = SCNNode(geometry: plane);
        planeNode.opacity = 0.25;
        
        /*
         `SCNPlane` is vertically oriented in its local coordinate space, but
         `ARImageAnchor` assumes the image is horizontal in its local space, so
         rotate the plane to match.
         */
        planeNode.simdEulerAngles.x = -.pi / 2;
        node.addChildNode(planeNode);
        

        if let anchNode = self.anchNode {
          anchNode.simdWorldTransform = node.simdWorldTransform;
        }
        else {
          self.anchNode = AnchorNode();
          self.anchNode!.simdWorldTransform = node.simdWorldTransform;
          self.arScnView.scene.rootNode.addChildNode(self.anchNode!);
          
          let textView = ARNote2DView(name: "Your anchor ⚓️",
                                      description: "The anchor you chose for your scene");
          
          self.anchNode!.addChildNode(textView);
        }

        
        self.currentState = .normal;
        
        DispatchQueue.main.async {
          self.previewAnchorImgView.isHidden = true;
        }
        
        self.anchorFound = true;
        DDLogInfo("Found and added anchor");

//        self.arScnView.scene = self.anchoredScn!;
//        node.removeFromParentNode();
//        self.arScnView.scene.rootNode.addChildNode(node);
        self.anchorNode = AnchorNodeAndParent(anchorNode: node,
                                              parent: node.parent!);

        
        // Create a transform which is located at the anchor but has the
        // rotation of the original ARKit world transform
//
//        let colsIdentity = matrix_identity_float4x4.columns;
//        let newWorldMat = simd_matrix(colsIdentity.0, colsIdentity.1,
//                                      colsIdentity.2,
//                                      simd_make_float4(node.simdWorldPosition,
//                                                       1));
//        self.prevMat = newWorldMat;

        //self.arSession.setWorldOrigin(relativeTransform: newWorldMat);
      }
      
      DispatchQueue.main.async {
        let imageName = referenceImage.name ?? "";
        self.statusViewController.cancelAllScheduledMessages();
        self.statusViewController.showMessage("Detected image “\(imageName)”");
      }
    }
    else if let noteAnchor = anchor as? NoteAnchor {
      let note = noteAnchor.note;
      
      arUpdateQueue.async {
        let textView = ARNote2DView(name: note.title,
                                    description: note.description);
        DDLogInfo("Added note anchor");
        
        // Add the plane visualization to the scene.
        node.addChildNode(textView);
        
        // Save the scene
        AnchoredScenesManager.inst.updateCurrentScene(scene: self.arScnView.scene);
      }
    }
  }

  
  /// Creates a new AR configuration to run on the `session`.
  /// - Tag: ARReferenceImage-Loading
  func resetTracking() {

    arScnView.session.run(arWorldTrackingConfig,
                          options: [.resetTracking, .removeExistingAnchors]);
    currentState = .badTracking;
    
    statusViewController.scheduleMessage("Look around to setup AR",
                                         inSeconds: 1.5,
                                         messageType: .contentPlacement);
    
    DDLogInfo("Reset tracking");
  }
  
  /// Begin looking for the scene anchor
  func startLookingForAnchor() {
    if (anchorFound) {
      currentState = .normal;
      return;
    }
    
    assert(imgsToRecognise.count > 0);
    
    arWorldTrackingConfig.detectionImages = imgsToRecognise;
   
    arScnView.session.run(arWorldTrackingConfig);
    currentState = .searchingAnchor;
    
    statusViewController.scheduleMessage("Look around to detect images",
                                         inSeconds: 0.0,
                                         messageType: .contentPlacement);
    
    previewAnchorImgView.isHidden = false;
    
    DDLogInfo("Started looking for anchor");
  }
  
  var imageHighlightAction: SCNAction {
    return .sequence([
      .wait(duration: 0.25),
      .fadeOpacity(to: 0.85, duration: 0.25),
      .fadeOpacity(to: 0.15, duration: 0.25),
      .fadeOpacity(to: 0.85, duration: 0.25),
      .fadeOut(duration: 0.5)
      ]);
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if (currentState != .normal) {
      return;
    }
    
    DDLogInfo("TouchesBegan");
    
    if let touchLocation = touches.first?.location(in: arScnView) {
      if let hit = arScnView.hitTest(touchLocation,
                                     types: .featurePoint).first {
        // Cache the anchor so that we can use it after the modal view has
        // finished
        cachedTransform = hit.worldTransform;
        
//        arScnView.session.add(anchor: NoteAnchor(transform: cachedTransform!,
//                                                 note: Note(title: "test",
//                                                            description: "test")));
        
        arUpdateQueue.async {
          let textView = ARNote2DView(name: "test",
                                      description: "test");
          DDLogInfo("Added note anchor");
          
          textView.simdWorldTransform = self.cachedTransform!;
          print(self.cachedTransform!);
          let newTransform = self.anchNode!.simdConvertTransform(self.cachedTransform!, from: nil);
          textView.simdTransform = newTransform;
          print(textView.simdTransform);
          print(textView.simdWorldTransform);
          
          // Add the plane visualization to the scene.
          self.anchNode!.addChildNode(textView);
          
          // Save the scene
          AnchoredScenesManager.inst.updateCurrentScene(scene: self.arScnView.scene);
        }
//        let newNoteVC = storyboard?.instantiateViewController(withIdentifier: "NewNoteVC") as! NewNoteVC;
//        newNoteVC.delegate = self;
//
//        DispatchQueue.main.async {
//          self.present(newNoteVC, animated: true, completion: nil);
//        }
        

        DDLogInfo("Added anchor because of tap");
      };
    };
  }
  
  
  @IBAction func onNewAnchorBtnTapped(_ sender: Any) {
    DDLogInfo("New anchor scene to be created, pass to takepic scene");
    
    // Switch view
    guard let newVC =
      self.storyboard?.instantiateViewController(withIdentifier: "TakePicVC")
        as? CreateNewMapVC
      else {
        DDLogError("Failed to cast the view");
        return;
    };
    
    DispatchQueue.main.async {
      self.show(newVC, sender: nil);
    }
  }
  
}

class NoteAnchor : ARAnchor {
  let note: Note;
  
  init(transform: matrix_float4x4, note n: Note) {
    note = n;
    super.init(transform: transform);
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension ARSceneVC : NewNoteVCDelegate {
  func addedNote(title t: String, description d: String) {
    if let ct = cachedTransform {
      arScnView.session.add(anchor: NoteAnchor(transform: ct,
                                             note: Note(title: t,
                                                        description: d)));
      cachedTransform = nil;

    }
  }
}

