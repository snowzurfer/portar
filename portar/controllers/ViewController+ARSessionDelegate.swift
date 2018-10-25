//
//  ViewController+ARSessionDelegate.swift
//  portar
//
//  Created by Alberto Taiuti on 07/04/2018.
//  Copyright © 2018 Shoebill. All rights reserved.
//

import ARKit;
import CocoaLumberjack;

extension ARSceneVC: ARSessionDelegate {
    
  // MARK: - ARSessionDelegate
  

  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    statusViewController.showTrackingQualityInfo(for: camera.trackingState,
                                                 autoHide: true);
  
    switch camera.trackingState {
      case .notAvailable, .limited:
        statusViewController.escalateFeedback(for: camera.trackingState,
                                              inSeconds: 0.0);
        currentState = .badTracking;
        DDLogInfo("Bad tracking reported");
      
      case .normal:
        statusViewController.cancelScheduledMessage(
          for: .trackingStateEscalation);
      
        startLookingForAnchor();
    }
  }
  
  func session(_ session: ARSession, didFailWithError error: Error) {
    guard error is ARError else { return };
  
    let errorWithInfo = error as NSError;
    let messages = [
        errorWithInfo.localizedDescription,
        errorWithInfo.localizedFailureReason,
        errorWithInfo.localizedRecoverySuggestion
    ];
  
    // Use `flatMap(_:)` to remove optional error messages.
    let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n");
  
    DispatchQueue.main.async {
      self.displayErrorMessage(title: "The AR session failed.",
                               message: errorMessage);
    }
  }
  
  func sessionWasInterrupted(_ session: ARSession) {
    blurView.isHidden = false;
    statusViewController.showMessage("""
      SESSION INTERRUPTED
      The session will be reset after the interruption has ended.
      """, autoHide: false);
    DDLogInfo("Session was interrupted");
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    blurView.isHidden = true;
    statusViewController.showMessage("RESETTING SESSION");
    
    restartExperience();
    DDLogInfo("Session interruption ended");
  }
  
  func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
    return true;
  }
  
  // MARK: - Error handling
  
  func displayErrorMessage(title: String, message: String) {
    // Blur the background.
    blurView.isHidden = false;
  
    // Present an alert informing about the error that has occurred.
    let alertController = UIAlertController(title: title,
                                            message: message,
                                            preferredStyle: .alert);
    let restartAction = UIAlertAction(title: "Restart Session",
                                      style: .default) { _ in
      alertController.dismiss(animated: true, completion: nil);
      self.blurView.isHidden = true;
      self.resetTracking();
    };
    
    alertController.addAction(restartAction);
    present(alertController, animated: true, completion: nil);
  }

  // MARK: - Interface Actions
  
  func restartExperience() {
    guard isRestartAvailable else { return };
    isRestartAvailable = false;
  
    statusViewController.cancelAllScheduledMessages();
  
    resetTracking();
  
    // Disable restart for a while in order to give the session time to restart.
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
      self.isRestartAvailable = true;
    }
  }
}
