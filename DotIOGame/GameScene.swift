//
//  GameScene.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/10/16.
//  Copyright (c) 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit
import Darwin

let pi = M_PI

enum Color {
    case Red, Green, Blue, Yellow
}

class GameScene: SKScene {
    
    var prefs = (
        showJoyStick: true,
        showArrow: true
    )
    
    var previousTime: CFTimeInterval? = nil
    //var cameraWidthToPlayerRadiusRatio: CGFloat!, cameraHeightToPlayerRadiusRatio: CGFloat!
    var cameraScaleToPlayerRadiusRatios: (x: CGFloat!, y: CGFloat!) = (x: nil, y: nil)
    
    var player: PlayerCreature!
    let spawnPosition = CGPoint(x: 200, y: 200)
    
    var score: Int = 0

    var directionArrow: SKSpriteNode!
    var directionArrowTargetPosition: CGPoint!
    var directionArrowAnchor: SKNode! //An invisible node that sticks to the player, constantly faces the player's target angle, and works as an anchor for the direction arrow. It's important that this node ALWAYS be facing the target angle, for the arrow needs to feel responsive and the player can have intermediate turning states.
    let minDirectionArrowDistanceFromPlayer: CGFloat = 60
    
    var playerMovingTouch: UITouch? = nil
    var originalPlayerMovingTouchPositionInCamera: CGPoint? = nil
    
    var joyStickBox: SKNode!, controlStick: SKNode!
    let maxControlStickDistance: CGFloat = 20
    
    var boostButton: BoostButton!
    var leaveMineButton: MineButton!
    
    var orbs: [EnergyOrb] = []
    var orbSpawnRadius: CGFloat = 888
    var numOfOrbsToSpawnInRadius: Int = 30
    var orbsToAreaRatio: CGFloat!
    
    var goopMines: [GoopMine] = []
    
    override func didMoveToView(view: SKView) {
        player = PlayerCreature(name: "Yoloz Boy 123", playerID: 1, color: .Red)
        player.position = spawnPosition
        self.addChild(player)
        cameraScaleToPlayerRadiusRatios.x = camera!.xScale / player.radius
        cameraScaleToPlayerRadiusRatios.y = camera!.yScale / player.radius

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
        
        joyStickBox = childNodeWithName("//joyStickBox")
        controlStick = childNodeWithName("//controlStick")
        joyStickBox.hidden = true
        
        boostButton = BoostButton()
        boostButton.position.x = size.width/2 - boostButton.size.width/2
        boostButton.position.y = -size.height/2 + boostButton.size.height/2
        camera!.addChild(boostButton)
        boostButton.addButtonIconToParent()
        boostButton.onPressed = player.startBoost
        boostButton.onReleased = player.stopBoost
        
        leaveMineButton = MineButton()
        leaveMineButton.position.x = size.width/2 - leaveMineButton.size.width / 2
        leaveMineButton.position.y = size.height/2 - leaveMineButton.size.height / 2
        camera!.addChild(leaveMineButton)
        leaveMineButton.addButtonIconToParent()
        leaveMineButton.onPressed = player.leaveMine
        leaveMineButton.onReleased = { return }
        
        orbsToAreaRatio = CGFloat(numOfOrbsToSpawnInRadius) / (CGFloat(pi) * (orbSpawnRadius * orbSpawnRadius - player.radius * player.radius))

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
                    pointInRelationToPlayer.x.clamp(player.size.width/2 + minDirectionArrowDistanceFromPlayer, size.width + size.height)
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
        for mine in goopMines {
            mine.update(deltaTime)
        }
        
        
        //      ----Handle collisions----
        
        // Orb collisions with players (for now just one player)
        let orbKillList = orbs.filter { $0.overlappingCircle(player) }
        orbs = orbs.filter { !orbKillList.contains($0) }
        for orb in orbKillList {
            // Basically, the orbs can do something fancy here and then be removed by parent.
            // In addition to being removed, the player's size and other relevant properties must be updated here
            let fadeAction = SKAction.fadeOutWithDuration(0.4)
            let remove = SKAction.runBlock { self.removeFromParent() }
            orb.runAction(SKAction.sequence([fadeAction, remove]))
            score += growAmountToPoints(orb.growAmount)
            player.targetRadius += orb.growAmount
        }
        
        // Mines collisions with players (for now just 1 player)
        for mine in goopMines {
            if mine.overlappingCircle(player) {
                // if the mine belongs to the player and the player is going at mine impulse speed, then it means they just left the mine and are boosting away in which case the player shouldn't be killed. Otherwise, GameOver
                if mine.belongsToCreature(player) && player.minePropulsionSpeedActiveTimeCounter < player.minePropulsionSpeedActiveTime {
                    continue
                } else {
                    print("player dead")
                    
                }
            }
        }
        
        
        //      ----DESPAWNING of decayed mines----
        // get rid of the decayed mines and seed orbs in their place
        let mineKillList = goopMines.filter { $0.lifeCounter > $0.lifeSpan }
        goopMines = goopMines.filter { !mineKillList.contains($0) }
        for mine in mineKillList {
            // Kill the mines
            seedOrbClusterWithBudget(mine.growAmount, aboutPoint: mine.position, withinRadius: mine.radius)
            mine.removeFromParent()
            
        }
        
        //      ----SPAWNING of mines (behind players with their flags on)--- 👹 💣
        //For now just our one player.....
        if player.spawnMineAtMyTail {
            player.spawnMineAtMyTail = false
            spawnMineAtPosition(player.position, playerRadius: player.radius, growAmount: player.radius * player.percentSizeSacrificeToLeaveMine, color: player.playerColor, leftByPlayerID: player.playerID)
            player.mineSpawned()
        }

        
        //      ----Orb Spawning----
        let orbsInRadius = orbs.filter { $0.position.distanceTo(player.position) <= orbSpawnRadius && !$0.artificiallySpawned}
        let numOfNeededOrbs = numOfOrbsToSpawnInRadius - orbsInRadius.count
        if numOfNeededOrbs > 0 {
            for _ in 0..<numOfNeededOrbs {
                // Spawn an orb x times depending on how many are needed to achieve the ideal concentration
                let randAngle = CGFloat.random(min: 0, max: 360)
                let randDist = CGFloat.random(min: player.radius, max: orbSpawnRadius)
                let orbX = player.position.x + cos(randAngle) * randDist
                let orbY = player.position.y + sin(randAngle) * randDist
                let orbPos = CGPoint(x: orbX, y: orbY)
                if CGFloat.random() > 0.9 {
                    seedRichOrbAtPosition(orbPos)
                } else {
                    seedSmallOrbAtPosition(orbPos)
                }
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
        camera!.xScale = cameraScaleToPlayerRadiusRatios.x * player.radius
        camera!.yScale = cameraScaleToPlayerRadiusRatios.y * player.radius
        
        camera!.position = player.position //Follow player
        
        //Update the directionArrow's position with directionArrowTargetPosition. The SMOOTH way. I also first update directionArrowAnchor as needed.
        if prefs.showArrow {
            directionArrowAnchor.position = player.position
            directionArrowAnchor.zRotation = player.playerTargetAngle.degreesToRadians()
            
            let deltaX = directionArrowTargetPosition.x - directionArrow.position.x
            let deltaY = directionArrowTargetPosition.y - directionArrow.position.y
            directionArrow.position += CGVector(dx: deltaX / 3, dy: deltaY / 3)
        }
        
        // update the orb spawn radius and the number of orbs that ought to be spawned in that radius using a constant ratio
        orbSpawnRadius = size.width + size.height
        numOfOrbsToSpawnInRadius = Int(orbsToAreaRatio * CGFloat(pi) * (orbSpawnRadius * orbSpawnRadius - player.radius * player.radius))

    }
    
    func seedOrbAtPosition(position: CGPoint, growAmount: CGFloat, minRadius: CGFloat, maxRadius: CGFloat, artificiallySpawned: Bool) -> EnergyOrb {
        let newOrb = EnergyOrb()
        newOrb.position = position
        newOrb.growAmount = growAmount
        newOrb.minRadius = minRadius
        newOrb.maxRadius = maxRadius
        newOrb.artificiallySpawned = artificiallySpawned
        orbs.append(newOrb)
        addChild(newOrb)
        return newOrb
    }
    
    func seedSmallOrbAtPosition(position: CGPoint, artificiallySpawned: Bool = false) -> EnergyOrb {
        return seedOrbAtPosition(position, growAmount: 0.2, minRadius: 5, maxRadius: 7, artificiallySpawned: artificiallySpawned)
    }
    
    func seedRichOrbAtPosition(position: CGPoint, artificiallySpawned: Bool = false) -> EnergyOrb {
        return seedOrbAtPosition(position, growAmount: 5, minRadius: 10, maxRadius: 14, artificiallySpawned: artificiallySpawned)
    }
    
    func seedOrbClusterWithBudget(growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat) {
        //Budget is the growAmount quantity that once existed in the entity that spawned the orbs. Mostly, this will be from dead players or old mines.
        var budget = growAmount
        while budget > 0 {
            let randAngle = CGFloat.random(min: 0, max: 360)
            let randDist = CGFloat.random(min: 0, max: radius)
            let position = CGPoint(x: cos(randAngle) * randDist + aboutPoint.x, y: sin(randAngle) * randDist + aboutPoint.y)
            let newOrb: EnergyOrb
//            if CGFloat.random() > 0.9 {
//                newOrb = seedRichOrb(position, artificiallySpawned: true)
//            } else {
                newOrb = seedSmallOrbAtPosition(position, artificiallySpawned: true)
//            }
            budget -= newOrb.growAmount
        }
        
    }
    
    
    func spawnMineAtPosition(atPosition: CGPoint, playerRadius: CGFloat, growAmount: CGFloat, color: Color, leftByPlayerID: Int) {
        let mine = GoopMine(radius: playerRadius, growAmount: growAmount, color: color, leftByPlayerWithID: leftByPlayerID)
        mine.position = atPosition
        addChild(mine)
        goopMines.append(mine)
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


func growAmountToPoints(growAmount: CGFloat) -> Int {
    return Int(growAmount * 5)
}
