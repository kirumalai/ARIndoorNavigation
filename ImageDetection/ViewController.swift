//
//  ViewController.swift
//  ImageDetection
//
//  Created by Ramesh on 27/07/19.
//  Copyright © 2019 Ramesh. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    //MARK:- Properties
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var placesView: UIView!
    var characterNode: SCNNode?
    var animations = [String: CAAnimation]()
    private var walkAnimation: CAAnimation!
    var characterAnchor: ARAnchor!
    var shouldMove = false
    var cameraAngle: Float = 0
    var initalAngle: Float = 0
    var scanCount = 0

    @IBOutlet weak var zLabel: UILabel!

    //MARK:- Default Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.autoenablesDefaultLighting = true
        loadAnimation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let worldTrackingConfiguration = ARWorldTrackingConfiguration()
        
        if let trackingImage = ARReferenceImage.referenceImages(inGroupNamed: "ARImages", bundle: nil){
            worldTrackingConfiguration.detectionImages = trackingImage
            worldTrackingConfiguration.maximumNumberOfTrackedImages = 1
        }
        sceneView.session.run(worldTrackingConfiguration)
        initalAngle = sceneView.pointOfView!.eulerAngles.y
       
    }
    
    func loadModel() {
        
        characterNode = SCNNode()
        let characterScene = SCNScene(named: "kididle.scnassets/panda.scn")!
        let characterTopLevelNode = characterScene.rootNode.childNodes[0]
        characterNode!.addChildNode(characterTopLevelNode)
       
    }
    
    func loadAnimation() {
        walkAnimation = CAAnimation.animationWithSceneNamed("kididle.scnassets/walk.scn")
        walkAnimation.usesSceneTimeBase = false
        walkAnimation.fadeInDuration = 0.3
        walkAnimation.fadeOutDuration = 0.3
        walkAnimation.repeatCount = Float.infinity
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        print(" after rotating .. \(sceneView.pointOfView!.eulerAngles.y)")

        if let imageAnchor = anchor as? ARImageAnchor{
            characterAnchor = ARAnchor(transform: imageAnchor.transform)
            //self.sceneView.session.setWorldOrigin(relativeTransform: imageAnchor.transform)

            self.sceneView.session.add(anchor: characterAnchor)

        }
        else {
            if characterNode == nil {
        
                if scanCount == 0 {
                    reset()
                    scanCount = scanCount + 1
                }
                else {
                    
                    let characterScene = SCNScene(named: "kididle.scnassets/panda.scn")!
                    characterNode = characterScene.rootNode.childNodes[0]
                    let cameraNode = sceneView.pointOfView!
                   
                    let angleY = sceneView.session.currentFrame!.camera.eulerAngles.y

                    cameraAngle = angleY
                    
                    OperationQueue.main.addOperation {
                        self.zLabel.text = "\((cameraNode.eulerAngles.y))"
                    }
                    characterNode!.eulerAngles = SCNVector3(0,deg2rad(200), 0)
                    let column3 = anchor.transform.columns.3
                
                    characterNode!.position = SCNVector3(column3.x, column3.y, column3.z)
                    self.sceneView.scene.rootNode.addChildNode(characterNode!)
                    
                    //Show place options here...
                    OperationQueue.main.addOperation {
                        self.togglePlaceOptions(show: true)
                    }
                }

                
            }
        }
        
        return nil
    }
    
    @IBAction func restRoomButtonAction() {
        shouldMove = true
        characterNode!.addAnimation(walkAnimation, forKey: "walk")
    }
    
    @IBAction func pantryButtonAction() {
       // togglePlaceOptions(show: false)
    }
    
    func togglePlaceOptions(show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.placesView.isHidden = !show
        }
    }
    
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
}


extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        if let character = characterNode, shouldMove {
            let cameraNode = sceneView.pointOfView!
            cameraAngle = cameraNode.eulerAngles.y
            OperationQueue.main.addOperation {
               self.zLabel.text = "\(Int(character.position.x)) , \((character.position.z))"
            }
            
            if character.position.z < -15.5{
                if character.position.x < 6.3 {
                   
                    characterNode!.eulerAngles = SCNVector3(0, deg2rad(90), 0)
                    character.position.x = character.position.x + (0.6 / 60)
                }
                else {
                    characterNode!.removeAllAnimations()
                }
            }
            else{
            
                let cameraNode = sceneView.pointOfView!
                if cameraNode.position.z - character.position.z  < 3.0 {
                  character.isPaused = false
                  character.position.z = character.position.z - (0.6 / 60)
                }
                else {
                    character.isPaused = true
                }
            }
        }
       
    }
    
    func reset() {
        sceneView.session.pause()
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        let worldTrackingConfiguration = ARWorldTrackingConfiguration()
        if let trackingImage = ARReferenceImage.referenceImages(inGroupNamed: "ARImages", bundle: nil){
            worldTrackingConfiguration.detectionImages = trackingImage
            worldTrackingConfiguration.maximumNumberOfTrackedImages = 1
        }
        sceneView.session.run(worldTrackingConfiguration, options: [.resetTracking, .removeExistingAnchors])
    }
}

// MARK: CoreAnimation

extension CAAnimation {
    class func animationWithSceneNamed(_ name: String) -> CAAnimation? {
        var animation: CAAnimation?
        if let scene = SCNScene(named: name) {
            scene.rootNode.enumerateChildNodes({ (child, stop) in
                if child.animationKeys.count > 0 {
                    animation = child.animation(forKey: child.animationKeys.first!)
                    stop.initialize(to: true)
                }
            })
        }
        return animation
    }
}

