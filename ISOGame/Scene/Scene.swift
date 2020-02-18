//
//  Scene.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

enum RenderPass {
    case gbuffer
    case shadow
}

protocol Renderable {
    var name: String { get }
    
    func render(renderEncoder: MTLRenderCommandEncoder, pass: RenderPass, vertexUniforms: Uniforms, fragmentUniforms: FragmentUniforms)
}

class Scene {
//    var inputController = InputController()
    
    var rootNode = Node()
    var renderables = [Renderable]()
    var nodes = [Node]()
    
    var screenSize: CGSize
    var cameras = [Camera()]
    var currentCameraIndex = 0
    var camera: Camera {
        cameras[currentCameraIndex]
    }
    
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()
    
    init(screenSize: CGSize) {
        self.screenSize = screenSize
        // setup scene
//        screenSizeWillChange(to: screenSize)
    }
    
    func update(deltaTime: Float) {
        
    }
    
    func updateUniforms() {
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
        fragmentUniforms.cameraPosition = camera.position
    }
    
    /**
     Add a note to the scene hierarchy. Will be added below given parent if any,
     - Renderables will be added to the renderables list
     - Cameras will be added to the camera list
     //- Lights will be added to the lights list
     */
    func add(node: Node, parent: Node? = nil) {
        nodes.append(node)
        
        if let parent = parent {
            parent.add(childNode: node)
        } else {
            rootNode.add(childNode: node)
        }
        
        if let renderable = node as? Renderable {
            renderables.append(renderable)
        }
        
        if let camera = node as? Camera {
            cameras.append(camera)
        }
    }
    
    /**
     Remove a node from the scene hierarchy
     */
    func remove(node: Node) {
        if let index = (nodes.firstIndex { $0 === node}) {
            nodes.remove(at: index)
        }

        if let parent = node.parent {
            parent.remove(childNode: node)
        } else {
            for child in node.children {
                child.parent = nil
            }
            node.children = []
        }
        
        if node is Renderable,
            let index = (renderables.firstIndex {
                $0 as? Node === node
            }) {
            renderables.remove(at: index)
        }
        
        if node is Camera,
            let index = (cameras.firstIndex { $0 === node }) {
            if index == currentCameraIndex {
                currentCameraIndex = 0
            } else if index > currentCameraIndex {
                currentCameraIndex -= 1
            }
            cameras.remove(at: index)
        }
    }
    
    /**
     Scene projection size changed. Update all dependent objects (mostly cameras)
     */
    func screenSizeWillChange(to size: CGSize) {
        for camera in cameras {
            camera.screenSizeWillChange(to: size)
        }
        screenSize = size
    }
}
