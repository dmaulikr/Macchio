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
func randomColor() -> Color {
    let allTheColors: [Color] = [.Red, .Green, .Blue, .Yellow]
    let randIndex = Int(CGFloat.random(min: 0, max: CGFloat(allTheColors.count)))
    return allTheColors[randIndex]
}

class GameScene: SKScene {
    
    var prefs = (
        showJoyStick: true,
        showArrow: true
    )
    
    enum State {
        case Playing, GameOver
        //case Tutorial //Do later
    }
    var gameState: State = .Playing
    
    var previousTime: CFTimeInterval? = nil
    //var cameraWidthToPlayerRadiusRatio: CGFloat!, cameraHeightToPlayerRadiusRatio: CGFloat!
    var cameraScaleToPlayerRadiusRatios: (x: CGFloat!, y: CGFloat!) = (x: nil, y: nil)
    
    var player: PlayerCreature?
    let spawnPosition = CGPoint(x: 200, y: 200)
    var otherCreatures: [Creature] = []
    var allCreatures: [Creature] {
        return otherCreatures + (player != nil ? [player!] : [])
    }
    
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
    
    var spawnRadius: CGFloat = 888

    var orbs: [EnergyOrb] = []
    let orbsToAreaRatio: CGFloat = 0.00001
    let creaturesToAreaRatio: CGFloat = 0.000001
    
    var goopMines: [GoopMine] = []
    
    override func didMoveToView(view: SKView) {
        player = PlayerCreature(name: "Yoloz Boy 123", playerID: 1, color: .Blue)
        if let player = player {
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
            directionArrowAnchor.zRotation = player.targetAngle.degreesToRadians()
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
            leaveMineButton.position.y = -size.height/2 + boostButton.size.height + leaveMineButton.size.height / 2
            camera!.addChild(leaveMineButton)
            leaveMineButton.addButtonIconToParent()
            leaveMineButton.onPressed = player.leaveMine
            leaveMineButton.onReleased = { return }
            
//            orbsToAreaRatio = CGFloat(numOfOrbsToSpawnInRadius) / (CGFloat(pi) * (spawnRadius * spawnRadius - player.radius * player.radius))
//            creaturesToAreaRatio = CGFloat(numOfCreaturesToSpawnInRadius) / (CGFloat(pi) * (spawnRadius * spawnRadius - player.radius * player.radius))
            
        
        }
        
        //spawnAICreatureAtPosition(spawnPosition + CGPoint(x: 0, y: 200))

    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if gameState == .GameOver { return }
        if let player = player {
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
                        directionArrow.zRotation = player.targetAngle.degreesToRadians() - CGFloat(90).degreesToRadians()
                        
                    }
                    
                    if prefs.showJoyStick {
                        joyStickBox.hidden = false
                        joyStickBox.position = originalPlayerMovingTouchPositionInCamera!
                    }
                }
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if gameState == .GameOver { return }
        if let player = player {
            for touch in touches {
                if touch == playerMovingTouch {
                    
                    let location = touch.locationInNode(camera!)
                    player.targetAngle = mapRadiansToDegrees0to360((location - originalPlayerMovingTouchPositionInCamera!).angle)
                    //player.velocity.angle = playerTargetAngle
                    
                    if prefs.showArrow {
                        // My means of determining the position of the arrow:
                        // the arrow will be straight ahead of the player's eyeball. How far it is is the distance the current touch location is from its orignal position. I have a value clamp too.
                        var pointInRelationToPlayer = CGPoint(x: player.size.width/2 + location.distanceTo(originalPlayerMovingTouchPositionInCamera!), y: 0)
                        pointInRelationToPlayer.x.clamp(player.size.width/2 + minDirectionArrowDistanceFromPlayer, size.width + size.height)
                        directionArrowTargetPosition = convertPoint(convertPoint(pointInRelationToPlayer, fromNode: directionArrowAnchor), toNode: camera!)
                        directionArrow.zRotation = player.targetAngle.degreesToRadians() - CGFloat(90).degreesToRadians()
                        
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
        if let player = player { player.update(deltaTime) }
        for x in otherCreatures {
            x.update(deltaTime)
        }
        for orb in orbs {
            orb.update(deltaTime)
        }
        for mine in goopMines {
            mine.update(deltaTime)
        }
        
        
        //      ----Handle collisions----
        // Orb collisions with player
        if let player = player {
            let orbKillList = orbs.filter { $0.overlappingCircle(player) }
            orbs = orbs.filter { !orbKillList.contains($0) }
            for orb in orbKillList {
                // Basically, the orbs can do something fancy here and then be removed by parent.
                // In addition to being removed, the player's size and other relevant properties must be updated here
                let fadeAction = SKAction.fadeOutWithDuration(0.4)
                let remove = SKAction.runBlock { self.removeFromParent() }
                orb.runAction(SKAction.sequence([fadeAction, remove]))
                score += growAmountToPoints(orb.growAmount)
                player.targetArea += orb.growAmount
            }
        }
        
        // Orb collisions with otherCreatures
        for c in otherCreatures {
            let orbKillList = orbs.filter { $0.overlappingCircle(c) }
            orbs = orbs.filter { !orbKillList.contains($0) }
            for orb in orbKillList {
                let fadeAction = SKAction.fadeOutWithDuration(0.4)
                let remove = SKAction.runBlock { self.removeFromParent() }
                orb.runAction(SKAction.sequence([fadeAction, remove]))
                c.targetArea += orb.growAmount
            }
        }
     
        
        // Mines collisions with player
        if let player = player {
            for mine in goopMines {
                if mine.overlappingCircle(player) {
                    // if the mine belongs to the player and the player is going at mine impulse speed, then it means they just left the mine and are boosting away in which case the player shouldn't be killed. Otherwise, GameOver
                    if mine === player.freshlySpawnedMine {
                        // Do nothing
                    } else {
                        gameOver()
                        seedRichOrbClusterWithBudget(player.growAmount, aboutPoint: player.position, withinRadius: player.targetRadius * player.orbSpawnUponDeathRadiusMultiplier)
                    }
                }
            }
        }
        
        // Mine collisions with other creatures
        var creatureKillList: [Creature] = []
        for creature in otherCreatures {
            for mine in goopMines {
                if mine.overlappingCircle(creature) && mine !== creature.freshlySpawnedMine {
                    // creature just died
                    creatureKillList.append(creature)
                }
            }
            
        }
        otherCreatures = otherCreatures.filter { !creatureKillList.contains($0) }
        for x in creatureKillList {
            x.removeFromParent()
            seedRichOrbClusterWithBudget(x.growAmount, aboutPoint: x.position, withinRadius: x.targetRadius * x.orbSpawnUponDeathRadiusMultiplier)
        }

        
        // Creatures colliding with other creatures
        var theEaten: [Creature] = []
        for creature in allCreatures {
            for other in allCreatures {
                if creature.overlappingCircle(other) && other !== creature {
                    // Ok so there is a collision between 2 different creatures
                    // So now we check if the bigger creature is big enough to eat the other creature, if so, then are they completely engulfing the smaller player. If the larger player wasn't larger enough to begin with, then the two players will just kinda bump into each other.
                    let theBigger = creature.radius > other.radius ? creature : other
                    let theSmaller = creature !== theBigger ? creature : other
                    if theBigger.radius > theSmaller.radius * 1.11 {
                        if theBigger.position.distanceTo(theSmaller.position) < theBigger.radius {
                            // The bigger has successfully engulfed the smaller
                            theBigger.targetArea += theSmaller.growAmount
                            theEaten.append(theSmaller)
                            if theBigger === player {
                                score += growAmountToPoints(theSmaller.growAmount)
                            }
                        }
                    } else {
                        // Since the two creatures are pretty close in size, they can't eat each other. They can't even overlap
                        // Displacement = r1 - (dist - r2) = r1 - dist + r2
                        let displaceDistance = theBigger.radius - theBigger.position.distanceTo(theSmaller.position) + theSmaller.radius
                        // For now just displace theSmaller by the distance value and at the apppropriate angle
                        let displaceAngle = (theSmaller.position - theBigger.position).angle
                        theSmaller.position += CGPoint(x: cos(displaceAngle) * displaceDistance, y: sin(displaceAngle) * displaceDistance)
                    }

                }
            }
        }
        otherCreatures = otherCreatures.filter() { !theEaten.contains($0) }
        for x in theEaten {
            if x === player && gameState != .GameOver {
                gameOver()
            } else {
                x.removeFromParent()
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
        // Here I believe all creatures will be treated equally
        for creature in allCreatures {
            if creature.spawnMineAtMyTail {
                creature.spawnMineAtMyTail = false
                let freshMine = spawnMineAtPosition(creature.position, playerRadius: creature.radius, growAmount: creature.radius * creature.percentSizeSacrificeToLeaveMine, color: creature.playerColor, leftByPlayerID: creature.playerID)
                creature.freshlySpawnedMine = freshMine
                creature.mineSpawned()
            }
            
            // Take out the fresh mine reference from players if the mine isn't "fresh" anymore i.e. the player has finished the initial contact and can be harmed by their own mine.
            if let freshMine = creature.freshlySpawnedMine {
                if !freshMine.overlappingCircle(creature) { creature.freshlySpawnedMine = nil }
            }
        }
        
        
        //      ----Orb Spawning and Despawning----
        if let player = player {
            let orbsInRadius = orbs.filter { $0.position.distanceTo(player.position) <= spawnRadius && !$0.artificiallySpawned}
            var openArea = areaOfCircleWithRadius(spawnRadius)
            for creature in allCreatures { // including player
                openArea -= areaOfCircleWithRadius(creature.radius)
            }
            let numOfNeededOrbs =  Int(orbsToAreaRatio * openArea) - orbsInRadius.count
            if numOfNeededOrbs > 0 {
                for _ in 0..<numOfNeededOrbs {
                    // Spawn an orb x times depending on how many are needed to achieve the ideal concentration
                    func generateRandomOrbPosition() -> CGPoint {
                        let randAngle = CGFloat.random(min: 0, max: 360)
                        let randDist = CGFloat.random(min: player.radius, max: spawnRadius)
                        let orbX = player.position.x + cos(randAngle) * randDist
                        let orbY = player.position.y + sin(randAngle) * randDist
                        let orbPos = CGPoint(x: orbX, y: orbY)
                        
                        for creature in allCreatures {
                            if creature.position.distanceTo(orbPos) < creature.radius {
                                return generateRandomOrbPosition()
                            }
                        }
                        
                        return orbPos
                    }
                    let orbPos = generateRandomOrbPosition()
                    
                    if CGFloat.random() > 0.9 {
                        seedRichOrbAtPosition(orbPos)
                    } else {
                        seedSmallOrbAtPosition(orbPos)
                    }
                }
            }
            
            
            // Destroy the orbs that aren't in the radius to preserve memory space
            let orbsNotInRadius = orbs.filter { $0.position.distanceTo(player.position) > spawnRadius }
            orbs = orbs.filter { !orbsNotInRadius.contains($0) }
            for orb in orbsNotInRadius {
                orb.removeFromParent()
            }
        }
        
        //      ----Creature Spawning and Despawning----
        if let player = player {
            let creaturesInRadius = otherCreatures.filter { $0.position.distanceTo(player.position) <= spawnRadius }
            var openArea = areaOfCircleWithRadius(spawnRadius)
            for creature in allCreatures {
                openArea -= areaOfCircleWithRadius(creature.radius)
            }
            let numOfCreaturesToSpawnNow = Int(creaturesToAreaRatio * openArea) - creaturesInRadius.count
            if numOfCreaturesToSpawnNow > 0 {
                for _ in 0..<numOfCreaturesToSpawnNow {
                    // spawn a creature x times with random properties.
                    let randAngle = CGFloat.random(min: 0, max: 360).degreesToRadians()
                    let randDist = CGFloat.random(min: (size.width * camera!.xScale) / 5, max: spawnRadius)
                    spawnAICreatureAtPosition(CGPoint(x: player.position.x + cos(randAngle) * randDist, y: player.position.y + sin(randAngle) * randDist))
                }
            }
            
            let creaturesNotInRadius = otherCreatures.filter { $0.position.distanceTo(player.position) + $0.radius > spawnRadius }
            otherCreatures = otherCreatures.filter { !creaturesNotInRadius.contains($0) }
            for c in creaturesNotInRadius { c.removeFromParent() }
        }
        
        //      ---- UI-ey things ----
        if let player = player {
            if gameState != .GameOver {
                camera!.xScale = cameraScaleToPlayerRadiusRatios.x * player.radius * 5 // Follow player on z axis (by rescaling 😀)
                camera!.yScale = cameraScaleToPlayerRadiusRatios.y * player.radius * 5
                camera!.position = player.position //Follow player on the x axis and y axis
                
                //Update the directionArrow's position with directionArrowTargetPosition. The SMOOTH way. I also first update directionArrowAnchor as needed.
                if prefs.showArrow {
                    directionArrowAnchor.position = player.position
                    directionArrowAnchor.zRotation = player.targetAngle.degreesToRadians()
                    
                    let deltaX = directionArrowTargetPosition.x - directionArrow.position.x
                    let deltaY = directionArrowTargetPosition.y - directionArrow.position.y
                    directionArrow.position += CGVector(dx: deltaX / 3, dy: deltaY / 3)
                }
                
                // Change mine buttons image to can leave or can't
                if player.canLeaveMine { leaveMineButton.buttonIcon.texture = leaveMineButton.canPressTexture }
                else { leaveMineButton.buttonIcon.texture = leaveMineButton.unableToPressTexture }
                
            }
        }
        // update the spawn radius and the number of orbs that ought to be spawned in that radius using a constant ratio. Same with other creatures.
        spawnRadius = (size.width * camera!.xScale) / 5 + (size.height * camera!.yScale) / 5
//            numOfOrbsToSpawnInRadius = Int(orbsToAreaRatio * CGFloat(pi) * (spawnRadius * spawnRadius - player.radius * player.radius))
//            numOfCreaturesToSpawnInRadius = Int(creaturesToAreaRatio * CGFloat(pi) * (spawnRadius * spawnRadius - player.radius * player.radius))

        
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
        return seedOrbAtPosition(position, growAmount: 1500, minRadius: 10, maxRadius: 14, artificiallySpawned: artificiallySpawned)
    }
    
    func seedRichOrbAtPosition(position: CGPoint, artificiallySpawned: Bool = false) -> EnergyOrb {
        return seedOrbAtPosition(position, growAmount: 7500, minRadius: 15, maxRadius: 20, artificiallySpawned: artificiallySpawned)
    }
    
    func seedOrbClusterWithBudget(growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat) {
        //Budget is the growAmount quantity that once existed in the entity that spawned the orbs. Mostly, this will be from dead players or old mines.
        var budget = growAmount
        while budget > 0 {
            let randAngle = CGFloat.random(min: 0, max: 360).degreesToRadians()
            let randDist = CGFloat.random(min: 0, max: radius)
            let position = CGPoint(x: cos(randAngle) * randDist + aboutPoint.x, y: sin(randAngle) * randDist + aboutPoint.y)
            let newOrb: EnergyOrb
            newOrb = seedSmallOrbAtPosition(position, artificiallySpawned: true)
            budget -= newOrb.growAmount
        }
        
    }
    
    func seedRichOrbClusterWithBudget(growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat) {
        var budget = growAmount
        while budget > 0 {
            let randAngle = CGFloat.random(min: 0, max: 360).degreesToRadians()
            let randDist = CGFloat.random(min: 0, max: radius)
            let position = CGPoint(x: cos(randAngle) * randDist + aboutPoint.x, y: sin(randAngle) * randDist + aboutPoint.y)
            let newOrb: EnergyOrb
            newOrb = seedRichOrbAtPosition(position, artificiallySpawned: true)
            budget -= newOrb.growAmount
        }

    }
    
    
    func spawnMineAtPosition(atPosition: CGPoint, playerRadius: CGFloat, growAmount: CGFloat, color: Color, leftByPlayerID: Int) -> GoopMine {
        let mine = GoopMine(radius: playerRadius, growAmount: growAmount, color: color, leftByPlayerWithID: leftByPlayerID)
        mine.position = atPosition
        addChild(mine)
        goopMines.append(mine)
        return mine
    }
    
    
    func spawnAICreatureAtPosition(position: CGPoint) {
        let newCreature = AICreature(name: "BS Player ID", playerID: randomID(), color: randomColor(), startRadius: CGFloat.random(min: Creature.minRadius, max: 250), gameScene: self)
        newCreature.position = position
        otherCreatures.append(newCreature)
        addChild(newCreature)
    }
    
    func randomID() -> Int {
        // Generates a random id number, authenticates it, then returns it
        let randNum = Int(CGFloat.random(min: -500, max: 500))
        let takenIDs: [Int] = allCreatures.map { $0.playerID }
        for id in takenIDs {
            if id == randNum { return randomID() }
        }
        return randNum
    }
    
    func gameOver() {
        gameState = .GameOver
        
        if let playerMovingTouch = playerMovingTouch {
            var fakeTouches = Set<UITouch>(); fakeTouches.insert(playerMovingTouch)
            touchesEnded(fakeTouches, withEvent: nil)
        }
        let destroyPlayerAction = SKAction.runBlock {
            self.player!.removeFromParent()
            self.player = nil
        }
        let wait = SKAction.waitForDuration(2)
        let sequence = SKAction.sequence([destroyPlayerAction, wait])
        runAction(sequence, completion: restart)
        
    }
    
    func restart() {
        let skView = self.view as SKView!
        let scene = MainScene(fileNamed:"MainScene") as MainScene!
        scene.scaleMode = .AspectFill
        skView.presentScene(scene, transition: SKTransition.fadeWithColor(SKColor.blackColor(), duration: 1))
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

func areaOfCircleWithRadius(r: CGFloat) -> CGFloat {
    return CGFloat(pi) * r * r
}
