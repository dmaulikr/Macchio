//
//  GameScene.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/10/16.
//  Copyright (c) 2016 Ryan Anderson. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var prefs = (
        showJoyStick: true,
        showArrow: true
    )
    var previousTime: CFTimeInterval? = nil
    
    var player: PlayerCreature!
    let spawnPosition = CGPoint(x: 200, y: 200)

    var directionArrow: SKSpriteNode!
    var directionArrowAnchor: SKNode! //An invisible node that sticks to the player, constantly faces the player's target angle, and works as an anchor for the direction arrow. It's important that this node ALWAYS be facing the target angle, for the arrow needs to feel responsive and the player can have intermediate turning states.
    let minDirectionArrowDistanceFromPlayer: CGFloat = 0, maxDirectionArrowDistanceFromPlayer: CGFloat = 200
    
    var playerMovingTouch: UITouch? = nil
    var originalPlayerMovingTouchPositionInCamera: CGPoint? = nil
    
    var joyStickBox: SKNode!, controlStick: SKNode!
    let maxControlStickDistance: CGFloat = 20
    
    override func didMoveToView(view: SKView) {
        player = PlayerCreature(name: "Yoloz Boy 123")
        player.position = spawnPosition
        self.addChild(player)
        
        directionArrow = SKSpriteNode(imageNamed: "arrow.png")
        directionArrow.zPosition = 100
        directionArrow.size = CGSize(width: player.size.width/5, height: player.size.height/5)
        directionArrow.zRotation = player.velocity.angle.degreesToRadians()
        directionArrow.hidden = true
        camera!.addChild(directionArrow)
        directionArrowAnchor = SKNode()
        directionArrowAnchor.position = player.position
        directionArrowAnchor.zRotation = player.playerTargetAngle.degreesToRadians()
        self.addChild(directionArrowAnchor)
        
        joyStickBox = childNodeWithName("//joyStickBox")
        controlStick = childNodeWithName("//controlStick")
        joyStickBox.hidden = true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if playerMovingTouch == nil {
                playerMovingTouch = touch
                let location = touch.locationInNode(camera!)
                originalPlayerMovingTouchPositionInCamera = location
                
                if prefs.showArrow {
                    directionArrow.hidden = false
                    directionArrow.removeAllActions()
                    directionArrow.runAction(SKAction.fadeInWithDuration(0.4))
                    directionArrow.position = convertPoint(convertPoint(CGPoint(x: player.size.width + minDirectionArrowDistanceFromPlayer + 30, y: 0), fromNode: directionArrowAnchor), toNode: camera!)
                    directionArrow.zRotation = player.playerTargetAngle.degreesToRadians() - CGFloat(90).degreesToRadians()
                    
                    directionArrowAnchor.position = player.position
                    directionArrowAnchor.zRotation = player.playerTargetAngle.degreesToRadians()
                }
                
                if prefs.showJoyStick {
                    joyStickBox.hidden = false
                    joyStickBox.position = originalPlayerMovingTouchPositionInCamera!
                }
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if touch == playerMovingTouch {
                
                let location = touch.locationInNode(camera!)
                player.playerTargetAngle = mapRadiansToDegrees0to360((location - originalPlayerMovingTouchPositionInCamera!).angle)
                //player.velocity.angle = playerTargetAngle
                
                if prefs.showArrow {
                    // My means of determining the position of the arrow:
                    // the arrow will be straight ahead of the player's eyeball. How far it is is the distance the current touch location is from its orignal position. I have a value clamp too.
                    var pointInRelationToPlayer = CGPoint(x: player.size.width + location.distanceTo(originalPlayerMovingTouchPositionInCamera!), y: 0)
                    pointInRelationToPlayer.x.clamp(player.size.width + minDirectionArrowDistanceFromPlayer, player.size.width + maxDirectionArrowDistanceFromPlayer)
                    directionArrow.position = convertPoint(convertPoint(pointInRelationToPlayer, fromNode: directionArrowAnchor), toNode: camera!)
                    directionArrow.zRotation = player.playerTargetAngle.degreesToRadians() - CGFloat(90).degreesToRadians()
                    
                    directionArrow.position.x.clamp(-frame.width/2, frame.width/2)
                    directionArrow.position.y.clamp(-frame.height/2, frame.height/2)
                    
                    directionArrowAnchor.position = player.position
                    directionArrowAnchor.zRotation = player.playerTargetAngle.degreesToRadians()
                }
                
                if prefs.showJoyStick {
                    //Move controlStick based on finger movement. Also add a distance cap
                    controlStick.position = location - originalPlayerMovingTouchPositionInCamera!
                    if location.distanceTo(originalPlayerMovingTouchPositionInCamera!) > maxControlStickDistance {
                        let angle = atan2(controlStick.position.y, controlStick.position.x)
                        controlStick.position.x = cos(angle) * maxControlStickDistance
                        controlStick.position.y = sin(angle) * maxControlStickDistance
                    }
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if touch == playerMovingTouch {
                playerMovingTouch = nil
                originalPlayerMovingTouchPositionInCamera = nil
                if prefs.showArrow {
                    directionArrow.removeAllActions()
                    directionArrow.runAction(SKAction.sequence([SKAction.fadeOutWithDuration(0.7), SKAction.runBlock {
                            self.directionArrow.hidden = true
                        }]))
                    
                }
                if prefs.showJoyStick {
                    joyStickBox.hidden = true
                    controlStick.position = CGPoint(x: 0, y: 0)
                }
            }
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        let deltaTime = currentTime - (previousTime ?? currentTime)
        previousTime = currentTime
        
        player.update(deltaTime)
        

        camera!.position = player.position
    }
    
    func mapRadiansToDegrees0to360(rad: CGFloat) -> CGFloat{
        var deg = rad.radiansToDegrees()
        if deg < 0 {
            deg += 360
        }
        return deg
    }

}
