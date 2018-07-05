//
//  ViewController.swift
//  AR_ML_label
//
//  Created by Julian Lechuga Lopez on 5/7/18.
//  Copyright © 2018 Julian Lechuga Lopez. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision
import CoreML

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var resnetModel = Resnet50()
    var hitTestResult: ARHitTestResult!
    var visionRequests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        registerGestureRecognizers()
    }
    
    func registerGestureRecognizers(){
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tapped(recognizer: UIGestureRecognizer){
        let sceneView = recognizer.view as! ARSCNView
        let touchLocation = self.sceneView.center
        
        guard let currentFrame = sceneView.session.currentFrame else {return}
        
        let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
        
        if hitTestResults.isEmpty {return}
        
        guard let hitTestResult = hitTestResults.first else {return}
        
        self.hitTestResult = hitTestResult
        let pixelBuffer = currentFrame.capturedImage
        
        performVisionRequest(pixelBuffer: pixelBuffer)
    }
    
    func performVisionRequest(pixelBuffer: CVPixelBuffer){
        let visionModel = try! VNCoreMLModel(for: self.resnetModel.model)
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            
            if error != nil {return}
            
            guard let observations = request.results else {return}
            
            let observation = observations.first as! VNClassificationObservation
            
            print("Name \(observation.identifier) and confidences is \(observation.confidence)")
        }
        
        request.imageCropAndScaleOption = .centerCrop
        
        self.visionRequests = [request]
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: [:])
        
        DispatchQueue.global().async{
            try! imageRequestHandler.perform(self.visionRequests)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
