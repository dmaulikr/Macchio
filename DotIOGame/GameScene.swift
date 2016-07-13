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
    var cameraWidthToPlayerRadiusRatio: CGFloat!, cameraHeightToPlayerRadiusRatio: CGFloat!
    
    var player: PlayerCreature!
    let spawnPosition = CGPoint(x: 200, y: 200)
    
    var score = 0

    var directionArrow: SKSpriteNode!
    var directionArrowTargetPosition: CGPoint!
    var directionArrowAnchor: SKNode! //An invisible node that sticks to the player, constantly faces the player's target angle, and works as an anchor for the direction arrow. It's important that this node ALWAYS be facing the target angle, for the arrow needs to feel responsive and the player can have intermediate turning states.
    let minDirectionArrowDistanceFromPlayer: CGFloat = 60, maxDirectionArrowDistanceFromPlayer: CGFloat = 200
    var directionArrowWidthToPlayerRadiusRatio: CGFloat!
    var directionArrowHeightToPlayerRadiusRatio: CGFloat!
    
    var playerMovingTouch: UITouch? = nil
    var originalPlayerMovingTouchPositionInCamera: CGPoint? = nil
    
    var joyStickBox: SKNode!, controlStick: SKNode!
    let maxControlStickDistance: CGFloat = 20
    var joyStickBoxXScaleToPlayerRadiusRatio: CGFloat!
    var joyStickBoxYScaleToPlayerRadiusRatio: CGFloat!
    
    var orbs: [EnergyOrb] = []
    let orbSpawnRadius: CGFloat = 600
    let orbConcentrationWithinSpawnRadius: Int = 50
    
    override func didMoveToView(view: SKView) {
        player = PlayerCreature(name: "Yoloz Boy 123")
        player.position = spawnPosition
        self.addChild(player)
        cameraWidthToPlayerRadiusRatio = self.size.width / player.radius
        cameraHeightToPlayerRadiusRatio = self.size.height / player.radius

        
        directionArrow = SKSpriteNode(imageNamed: "arrow.png")
        directionArrow.zPosition = 100
        directionArrow.size = CGSize(width: player.size.width/5, height: player.size.height/5)
        directionArrow.zRotation = player.velocity.angle.degreesToRadians()
        directionArrow.hidden = true
        directionArrowTargetPosition = directionArrow.position
        camera!.addChild(directionArrow)
        directionArrowAnchor = SKNode()
        directionArrowAnchor.position = player.position
        directionArrowAnchor.zRotation = player.playerTargetAngle.degreesToRadians()
        self.addChild(directionArrowAnchor)
        directionArrowWidthToPlayerRadiusRatio = directionArrow.size.width / player.radius
        directionArrowHeightToPlayerRadiusRatio = directionArrow.size.height / player.radius
        
        joyStickBox = childNodeWithName("//joyStickBox")
        controlStick = childNodeWithName("//controlStick")
        joyStickBox.hidden = true
        joyStickBoxXScaleToPlayerRadiusRatio = joyStickBox.xScale / player.radius
        joyStickBoxYScaleToPlayerRadiusRatio = joyStickBox.yScale / player.radius

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
                    directionArrowTargetPosition = convertPoint(convertPoint(CGPoint(x: player.size.width/2 + minDirectionArrowDistanceFromPlayer + 30, y: 0), fromNode: directionArrowAnchor), toNode: camera!)
                    directionArrow.zRotation = player.playerTargetAngle.degreesToRadians() - CGFloat(90).degreesToRadians()
                    
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
                    var pointInRelationToPlayer = CGPoint(x: player.size.width/2 + location.distanceTo(originalPlayerMovingTouchPositionInCamera!), y: 0)
                    pointInRelationToPlayer.x.clamp(player.size.width/2 + minDirectionArrowDistanceFromPlayer, player.size.width + maxDirectionArrowDistanceFromPlayer)
                    directionArrowTargetPosition = convertPoint(convertPoint(pointInRelationToPlayer, fromNode: directionArrowAnchor), toNode: camera!)
                    directionArrow.zRotation = player.playerTargetAngle.degreesToRadians() - CGFloat(90).degreesToRadians()
                    
                    directionArrowTargetPosition.x.clamp(-frame.width/2, frame.width/2)
                    directionArrowTargetPosition.y.clamp(-frame.height/2, frame.height/2)
                    
                    
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
        
        
        //      ----Call update methods----
        player.update(deltaTime)
        for orb in orbs {
            orb.update(deltaTime)
        }
        
        //      ----Handle collisions----
        let orbKillList = orbs.filter { $0.overlappingCircle(player) }
        orbs = orbs.filter { !orbKillList.contains($0) }
        for orb in orbKillList {
            // Basically, the orbs can do something fancy here and then be removed by parent.
            // In addition to being removed, the player's size and other relevant properties must be updated here
            orb.removeFromParent()
            score += orb.pointValue
            player.targetRadius += orb.growAmount
        }
        
        //      ----Orb Spawning----
        let orbsInRadius = orbs.filter { $0.position.distanceTo(player.position) <= orbSpawnRadius }
        let numOfNeededOrbs = orbConcentrationWithinSpawnRadius - orbsInRadius.count
        if numOfNeededOrbs > 0 {
            for _ in 0..<numOfNeededOrbs {
                // Spawn an orb x times depending on how many are needed to achieve the ideal concentration
                let randAngle = CGFloat.random(min: 0, max: 360)
                let randDist = CGFloat.random(min: 0, max: orbSpawnRadius)
                let newOrb = EnergyOrb()
                newOrb.position.x = player.position.x + cos(randAngle) * randDist
                newOrb.position.y = player.position.y + sin(randAngle) * randDist
                orbs.append(newOrb)
                addChild(newOrb)
            }
        }
        
        // Destroy the orbs that aren't in the radius to preserve memory space
        let orbsNotInRadius = orbs.filter { $0.position.distanceTo(player.position) > orbSpawnRadius }
        orbs = orbs.filter { !orbsNotInRadius.contains($0) }
        for orb in orbsNotInRadius {
            orb.removeFromParent()
        }
        
        //      ---- UI-ey things ----
        //The following code consists of ton of scaling. ----
        //maintain direction arrow scale
        if prefs.showArrow {
            directionArrow.size.width = directionArrowWidthToPlayerRadiusRatio * player.radius
            directionArrow.size.height = directionArrowHeightToPlayerRadiusRatio * player.radius
            
            directionArrowAnchor.position = player.position
            directionArrowAnchor.zRotation = player.playerTargetAngle.degreesToRadians()
        }
        
        //maintain joyStickBox scale
        if prefs.showJoyStick {
            joyStickBox.xScale = joyStickBoxXScaleToPlayerRadiusRatio * player.radius
            joyStickBox.yScale = joyStickBoxYScaleToPlayerRadiusRatio * player.radius
        }
        
        //maintain the camera scale
        size.width = cameraWidthToPlayerRadiusRatio * player.radius
        size.height = cameraHeightToPlayerRadiusRatio * player.radius
        
        camera!.position = player.position //Follow player
        //Update the directionArrow's position with directionArrowTargetPosition. The SMOOTH way
        if prefs.showArrow {
            let deltaX = directionArrowTargetPosition.x - directionArrow.position.x
            let deltaY = directionArrowTargetPosition.y - directionArrow.position.y
            directionArrow.position += CGVector(dx: deltaX / 3, dy: deltaY / 3)
        }


    }
    
    func mapRadiansToDegrees0to360(rad: CGFloat) -> CGFloat{
        var deg = rad.radiansToDegrees()
        if deg < 0 {
            deg += 360
        } else if deg > 360 {
            deg = deg % 360
        }
        return deg
    }

}
