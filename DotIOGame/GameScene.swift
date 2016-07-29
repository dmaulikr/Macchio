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
    let allTheColors: [Color] = [.Red, .Blue, .Yellow]
    let randIndex = Int(CGFloat.random(min: 0, max: CGFloat(allTheColors.count)))
    return allTheColors[randIndex]
}


class GameScene: SKScene {
    
    var prefs: (
        showJoyStick: Bool,
        showArrow: Bool,
        zoomOutFactor: CGFloat) = (
            showJoyStick: true,
            showArrow: true,
            zoomOutFactor: 10
    )
    
    enum State {
        case Playing, GameOver
    }
    var gameState: State = .Playing
    
    var previousTime: CFTimeInterval? = nil
    
    let mapSize: (width: CGFloat, height: CGFloat) = (width: 6000, height: 6000)
    var bgGraphics: SKNode!
    
    var cameraScaleToPlayerRadiusRatios: (x: CGFloat!, y: CGFloat!) = (x: nil, y: nil)
    
    var player: Creature?
    let spawnPosition = CGPoint(x: 200, y: 200)
    var otherCreatures: [Creature] = []
    var allCreatures: [Creature] {
        return (player != nil ? [player!] : []) + otherCreatures
    }
    
    var score: Int = 0 {
        didSet { scoreLabel.text = String(score) }
    }
    var scoreLabel: SKLabelNode!
    
    var playerSize: Int = 0 {
        didSet { sizeLabel.text = String(playerSize) }
    }
    var sizeLabel: SKLabelNode!
    
    var directionArrow: SKSpriteNode!
    var directionArrowTargetPosition: CGPoint!
    var directionArrowAnchor: SKNode! //An invisible node that sticks to the player, constantly faces the player's target angle, and works as an anchor for the direction arrow. It's important that this node ALWAYS be facing the target angle, for the arrow needs to feel responsive and the player can have intermediate turning states.
    let minDirectionArrowDistanceFromPlayer: CGFloat = 60
    var directionArrowDragMultiplierToPlayerRadiusRatio: CGFloat!
    
    var playerMovingTouch: UITouch? = nil
    var originalPlayerMovingTouchPositionInCamera: CGPoint? = nil
    
    var joyStickBox: SKNode!, controlStick: SKNode!
    let maxControlStickDistance: CGFloat = 20
    
    var boostButton: BoostButton!
    var leaveMineButton: MineButton!
    
    var orbChunks: [[[EnergyOrb]]] = [] // A creature, when checking for orb collisions, will use for orb in orbChunks[x][y] where x and y are the positions of the corresponding orb chunks
    var orbBeacons: [OrbBeacon] = []
    func convertWorldPointToOrbChunkLocation(point: CGPoint) -> (x: Int, y: Int)? {
        if point.x < 0 || point.x > mapSize.width || point.y < 0 || point.y > mapSize.height { return nil }
        var x = Int(point.x / orbChunkWidth); var y = Int(point.y / orbChunkHeight)
        if x < 0 { x = 0 }; if x >= numOfChunkColumns { x = numOfChunkColumns - 1 }
        if y < 0 { y = 0 }; if y >= numOfChunkRows { y = numOfChunkRows - 1 }
        return (x: x, y: y)
    }
    let orbChunkWidth: CGFloat = 600, orbChunkHeight: CGFloat = 600
    var numOfChunkColumns: Int { return Int(mapSize.width / orbChunkWidth) }
    var numOfChunkRows: Int { return Int(mapSize.height / orbChunkHeight) }
    let orbsToAreaRatio: CGFloat = 0.00002
    var numOfOrbsThatNeedToBeInTheWorld: Int { return Int(orbsToAreaRatio * mapSize.width * mapSize.height) }
    let creaturesToAreaRatio: CGFloat = 0.0000011
    var numOfCreaturesThatMustExist: Int { return Int(creaturesToAreaRatio * mapSize.width * mapSize.height) }
    
    var goopMines: [GoopMine] = []
    
    var warningSigns: [WarningSign] = []
    
    override func didMoveToView(view: SKView) {
//        player = AICreature(name: "Yoloz Boy 123", playerID: 1, color: .Red, startRadius: 80, gameScene: self, rxnTime: 0)
        player = PlayerCreature(name: "Yoloz Boy 123", playerID: 1, color: randomColor(), startRadius: 80)
        if let player = player {
            player.position = computeValidCreatureSpawnPoint(player.radius)
            self.addChild(player)
            cameraScaleToPlayerRadiusRatios.x = camera!.xScale / player.radius
            cameraScaleToPlayerRadiusRatios.y = camera!.yScale / player.radius
            
            bgGraphics = childNodeWithName("bgGraphics")
            bgGraphics.xScale = mapSize.width / 6000
            bgGraphics.yScale = mapSize.height / 6000
            
            scoreLabel = childNodeWithName("//scoreLabel") as! SKLabelNode
            sizeLabel = childNodeWithName("//sizeLabel") as! SKLabelNode
            
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
            directionArrowDragMultiplierToPlayerRadiusRatio = 1 / player.radius
            self.addChild(directionArrowAnchor)
            
            camera!.zPosition = 100
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
            
            // Initialize orbChunks with empty arrays
            for col in 0..<numOfChunkColumns {
                orbChunks.append([])
                for _ in 0..<numOfChunkRows {
                    orbChunks[col].append([])
                }
            }
            
        }
    }
    
    func computeValidCreatureSpawnPoint(creatureStartRadius: CGFloat = C.creature_minRadius) -> CGPoint {
        // This function assumes the creature has not been spawned yet
        let randX = CGFloat.random(min: 0 + creatureStartRadius, max: mapSize.width - creatureStartRadius )
        let randY = CGFloat.random(min: 0 + creatureStartRadius, max: mapSize.height - creatureStartRadius)
        let randPoint = CGPoint(x: randX, y: randY)
        for otherLiveCreature in allCreatures {
            if otherLiveCreature.position.distanceTo(randPoint) - creatureStartRadius - otherLiveCreature.radius < 200 {
                return computeValidCreatureSpawnPoint(creatureStartRadius)
            }
        }
        return randPoint
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
                        var pointInRelationToPlayer = CGPoint(x: player.size.width/2 + (location.distanceTo(originalPlayerMovingTouchPositionInCamera!))*directionArrowDragMultiplierToPlayerRadiusRatio * player.radius, y: 0)
                        pointInRelationToPlayer.x.clamp(player.size.width/2 + minDirectionArrowDistanceFromPlayer, size.width * camera!.xScale + size.height * camera!.yScale)
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
        for c in allCreatures { //Includes player
            c.update(deltaTime)
            c.position.x.clamp(0 + c.targetRadius, mapSize.width-c.targetRadius)
            c.position.y.clamp(0 + c.targetRadius, mapSize.height-c.targetRadius)
        }
        for orbChunkCol in orbChunks {
            for orbChunk in orbChunkCol {
                for orb in orbChunk {
                    orb.update(deltaTime)
                }
            }
        }
        for mine in goopMines {
            mine.update(deltaTime)
        }
        for warningSign in warningSigns { warningSign.update(CGFloat(deltaTime)) }
        
        //      ----Handle collisions----
        handleCreatureAndOrbCollisions()
        handleCreatureAndMineCollisions()
        handleCreatureAndCreatureCollisions()
        
        handleMineSpawningAndDecay()
        handleOrbSpawning()
        handleCreatureSpawning()
        
        updateUI()
        
        if let player = player {
            playerSize = convertAreaToScore(player.targetArea)
        }
        
    }
    
    func convertAreaToScore(area: CGFloat) -> Int {
        return Int(radiusOfCircleWithArea(area) * 100) / 100
    }

    
    func handleCreatureAndOrbCollisions() {
        // Orb collisions with any creature including the player
        for c in allCreatures {
            var locationsThatWillBeTested: [CGPoint] = [] //Used to make sure we don't test the same chunk twice
            //var orbChunksToTest: [[EnergyOrb]] = [[]]
            for point in c.nineNotablePoints {
                // The nine notable points are the center and eight points on the outside
                if let location = convertWorldPointToOrbChunkLocation(point) {
                    let locationAsCGPoint = CGPoint(x: CGFloat(location.x), y: CGFloat(location.y))
                    if !(locationsThatWillBeTested.contains(locationAsCGPoint)) {
                        locationsThatWillBeTested.append(locationAsCGPoint)
                        //orbChunksToTest.append( orbChunks[location.x][location.y] )
                        // Test the chunk right now
                        let testingChunk = orbChunks[location.x][location.y]
                        let newChunkWithoutTheRemovedOrbs = handleOrbChunkCollision(testingChunk, withCreature: c)
                        orbChunks[location.x][location.y] = newChunkWithoutTheRemovedOrbs
                    }
                }
            }
        }
        
        // After all the orb collisions have been handled, itereate through the beacons to see if there are any that should be removed..
        orbBeacons = orbBeacons.filter { $0.totalValue > 10000 }
        //print (orbBeacons.count)
        
    }
    
    func handleOrbChunkCollision(orbChunk: [EnergyOrb], withCreature c: Creature) -> [EnergyOrb] {
        // handles the collisons between a given creature and all the orbs in the given chunk
        // returns a new list of orbs for the chunk without the removed ones.
        let orbKillList: [EnergyOrb] = orbChunk.filter { $0.overlappingCircle(c) }
        
        for orb in orbKillList {
            let fadeAction = SKAction.fadeOutWithDuration(1)
            let remove = SKAction.runBlock { self.removeFromParent() }
            orb.runAction(SKAction.sequence([fadeAction, remove]))
            c.targetArea += orb.growAmount
            if c === player {
                spawnFlyingNumberOnPlayerMouth(convertAreaToScore(orb.growAmount))
                //print("flying number spawned")
                score += convertAreaToScore(orb.growAmount)
            }
            for beacon in orbBeacons {
                if beacon.overlappingCircle(orb) { beacon.totalValue -= orb.growAmount }
            }
        }
        return orbChunk.filter { !orbKillList.contains($0) }
    }

    
    func handleCreatureAndMineCollisions() {
        // Mine collisions with creatures including player
        var creatureKillList: [Creature] = []
        for creature in allCreatures {
            for mine in goopMines {
                if mine.overlappingCircle(creature) && !creature.freshlySpawnedMines.contains(mine) {
                    // creature just died
                    creatureKillList.append(creature)
                }
            }
            
        }
        
        otherCreatures = otherCreatures.filter { !creatureKillList.contains($0) }
        for x in creatureKillList {
            if x === player && gameState != .GameOver {
                gameOver()
            } else {
                x.removeFromParent()
            }
            seedAutoOrbClusterWithBudget(x.growAmount * Creature.percentGrowAmountToBeDepositedUponDeath, aboutPoint: x.position, withinRadius: x.targetRadius * x.orbSpawnUponDeathRadiusMultiplier, exclusivelyInColor: x.playerColor)
        }

    }
    
    func handleCreatureAndCreatureCollisions() {
        // Creatures colliding with other creatures
        var theEaten: [Creature] = []
        for creature in allCreatures {
            for other in allCreatures {
                if creature.overlappingCircle(other) && other !== creature {
                    // Ok so there is a collision between 2 different creatures
                    // So now we check if the bigger creature is big enough to eat the other creature, if so, then are they completely engulfing the smaller player. If the larger player wasn't larger enough to begin with, then the two players will just kinda bump into each other.
                    let theBigger = creature.radius > other.radius ? creature : other
                    let theSmaller = creature !== theBigger ? creature : other
                    if theBigger.radius > theSmaller.radius * C.percentLargerACreatureMustBeToEngulfAnother {
                        if theBigger.position.distanceTo(theSmaller.position) < theBigger.radius {
                            // The bigger has successfully engulfed the smaller
                            theBigger.targetArea += theSmaller.growAmount * Creature.percentGrowAmountToBeDepositedUponDeath
                            theEaten.append(theSmaller)
                            if theBigger === player {
                                // add a flying number
                                spawnFlyingNumberOnPlayerMouth(convertAreaToScore(theSmaller.targetArea))
                                score += convertAreaToScore(theSmaller.targetArea)
                            }
                        }
                    } else {
                        // Since the two creatures are pretty close in size, they can't eat each other. They can't even overlap
                        // Displacement = r1 - (dist - r2) = r1 - dist + r2
                        let displaceDistance = theBigger.radius - theBigger.position.distanceTo(theSmaller.position) + theSmaller.radius
                        // For now just displace theSmaller by the distance value and at the apppropriate angle
                        let displaceAngle = (theSmaller.position - theBigger.position).angle
                        let totalMassInvolved = theBigger.targetArea + theSmaller.targetArea
                        let theSmallerFraction = theSmaller.targetArea / totalMassInvolved
                        let theBiggerFraction = theBigger.targetArea / totalMassInvolved
                        
                        theSmaller.position.x += cos(displaceAngle) * (displaceDistance * theSmallerFraction)
                        theSmaller.position.y += sin(displaceAngle) * (displaceDistance * theSmallerFraction)
                        theBigger.position.x -= cos(displaceAngle) * (displaceDistance * theBiggerFraction)
                        theBigger.position.y -= sin(displaceAngle) * (displaceDistance * theBiggerFraction)
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

    }
    
    func handleMineSpawningAndDecay() {
        // DESPAWNING of decayed mines
        // get rid of the decayed mines and seed orbs in their place
        let mineKillList = goopMines.filter { $0.lifeCounter > $0.lifeSpan }
        goopMines = goopMines.filter { !mineKillList.contains($0) }
        for mine in mineKillList {
            seedAutoOrbClusterWithBudget(mine.growAmount * Creature.percentGrowAmountToBeDepositedUponDeath, aboutPoint: mine.position, withinRadius: mine.radius)
            mine.removeFromParent()
        }
        
        // SPAWNING of mines (behind players with their flags on) 👹 💣
        // Here I believe all creatures will be treated equally
        for creature in allCreatures {
            if creature.spawnMineAtMyTail {
                creature.spawnMineAtMyTail = false
                creature.mineSpawned()
                let valueForMine: CGFloat
                if creature.targetArea * (1-creature.percentSizeSacrificeToLeaveMine) > areaOfCircleWithRadius(C.creature_minRadius) {
                    valueForMine = creature.targetArea * (1-creature.percentSizeSacrificeToLeaveMine) * Creature.percentGrowAmountToBeDepositedUponDeath
                } else {
                    valueForMine = 0
                }
                //let freshMineSpawnAngle = (creature.velocity.angle + 180).degreesToRadians()
                //let freshMineX = creature.position.x + cos(freshMineSpawnAngle) * (creature.radius / 2)
                //let freshMineY = creature.position.y + sin(freshMineSpawnAngle) * (creature.radius / 2)
                //let freshMine = self.spawnMineAtPosition(CGPoint(x: freshMineX, y: freshMineY), mineRadius: creature.radius/2, growAmount: valueForMine, color: creature.playerColor, leftByPlayerID: creature.playerID)
                let freshMine = spawnMineAtPosition(creature.position, mineRadius: creature.radius, growAmount: valueForMine, color: creature.playerColor, leftByPlayerID: creature.playerID)
                freshMine.name = "\(creature.name!) shuriken"
                
                creature.freshlySpawnedMines.append(freshMine)
                for otherCreature in allCreatures {
                    if otherCreature === creature { continue }
                    if freshMine.overlappingCircle(otherCreature) {
                        otherCreature.freshlySpawnedMines.append(freshMine)
                    }
                }
                if creature === player {
                    //spawnFlyingNumberOnPlayerMouth(-convertAreaToScore(freshMine.growAmount))
                }
            }
            
        }
        
        
        for creature in allCreatures {
            // Take out the fresh mine reference from players if the mine isn't "fresh" anymore i.e. the player has finished the initial contact and can be harmed by their own mine.
            var mineRemoveList:[GoopMine] = []
            for freshMine in creature.freshlySpawnedMines {
                if !freshMine.overlappingCircle(creature) {
                    //freshMine.zPosition = 90
                    mineRemoveList.append(freshMine)
                    //print("freshly spawned mine removed: \(freshMine.name)")
                }
            }
         
            creature.freshlySpawnedMines = creature.freshlySpawnedMines.filter { !mineRemoveList.contains($0) }
        }
        
        
        for mine in (goopMines.filter { $0.zPosition != 90 }) {
            var isFreshToSomebody = false
            for creature in (allCreatures.filter { $0.freshlySpawnedMines.count > 0 }) {
                if creature.freshlySpawnedMines.contains(mine) {
                    isFreshToSomebody = true
                    break
                }
            }
            if !isFreshToSomebody {
                mine.zPosition = 90
            }
        }
    }
    
    func handleOrbSpawning() {
        var currrentOrbCount = 0
        for chunkCol in orbChunks {
            for chunk in chunkCol {
                for orb in chunk {
                    if orb.artificiallySpawned == false { currrentOrbCount += 1 }
                }
            }
        }
        
        let numOfOrbsToSpawnNow = numOfOrbsThatNeedToBeInTheWorld - currrentOrbCount
        if numOfOrbsToSpawnNow > 0 {
            for _ in 0..<numOfOrbsToSpawnNow {
                // x times, spawn an orb at a random world positon
                let newPosition = CGPoint(x: CGFloat.random(min: 0, max: mapSize.width), y: CGFloat.random(min: 0, max: mapSize.height) )
                seedOrbWithSpecifiedType(.Small, atPosition: newPosition)
            }
        }
    }
    
    func handleCreatureSpawning() {
        let numOfCreaturesThatNeedToBeSpawnedNow = numOfCreaturesThatMustExist - otherCreatures.count
        for _ in 0..<numOfCreaturesThatNeedToBeSpawnedNow {
            spawnAICreature()
        }
    }
    
    func updateUI() {
        //      ---- UI-ey things ----
        if let player = player {
            if gameState != .GameOver {
                camera!.xScale = cameraScaleToPlayerRadiusRatios.x * player.radius * prefs.zoomOutFactor // Follow player on z axis (by rescaling 😀)
                camera!.yScale = cameraScaleToPlayerRadiusRatios.y * player.radius * prefs.zoomOutFactor
                camera!.position = player.position //Follow player on the x axis and y axis
                
                //Update the directionArrow's position with directionArrowTargetPosition. The SMOOTH way. I also first update directionArrowAnchor as needed.
                if prefs.showArrow {
                    directionArrowAnchor.position = player.position
                    directionArrowAnchor.zRotation = player.targetAngle.degreesToRadians()
                    
                    let deltaX = directionArrowTargetPosition.x - directionArrow.position.x
                    let deltaY = directionArrowTargetPosition.y - directionArrow.position.y
                    directionArrow.position += CGVector(dx: deltaX / 2, dy: deltaY / 2)
                }
                
                // Change mine buttons image to can leave or can't
                //if player.canLeaveMine { leaveMineButton.buttonIcon.texture = leaveMineButton.canPressTexture }
                //else { leaveMineButton.buttonIcon.texture = leaveMineButton.unableToPressTexture }
                leaveMineButton.greenPart.xScale = player.mineCoolDownCounter / C.creature_mineCooldownTime
                leaveMineButton.greenPart.yScale = player.mineCoolDownCounter / C.creature_mineCooldownTime
                
                
                
                // Make sure the boost button is greyed if the player can't boost
                if !player.canBoost {
                    boostButton.buttonIcon.texture = boostButton.unableToPressTexture
                } else if player.isBoosting {
                    boostButton.buttonIcon.texture = boostButton.pressedTexture
                } else {
                    boostButton.buttonIcon.texture = boostButton.defaultTexture
                }
                
                // update the positions of warning signs
                var warningSignKillList: [WarningSign] = []
                let testingRange = C.alertPlayerAboutLargerCreaturesInRange * cameraScaleToPlayerRadiusRatios.x * player.radius

                for warningSign in warningSigns {
                    if let correspondingCreature = warningSign.correspondingCreature {
                        let creaturePositionInRelationToCamera = camera!.convertPoint(correspondingCreature.position, fromNode: self)
                        warningSign.position = creaturePositionInRelationToCamera
                        warningSign.position.x.clamp(-size.width / 2 + warningSign.size.width/2, size.width / 2 - warningSign.size.width/2)
                        warningSign.position.y.clamp(-size.height / 2 + warningSign.size.height/2, size.height / 2 - warningSign.size.height/2)
                        
                        // Test for despawning based on distance ( how far away is the creature from the camera center? )
                        // 1) is the corresponding creature too far away?
                        if camera!.position.distanceTo(correspondingCreature.position) - correspondingCreature.radius > testingRange {
                            warningSignKillList.append(warningSign)
                        }
                        
                        // 2) Hide if the corresponding creature inside the camera?
                        let angleToCamera = (camera!.position - correspondingCreature.position).angle // in radians 😁
                        let closestX = correspondingCreature.position.x + cos(angleToCamera) * correspondingCreature.radius
                        let closestY = correspondingCreature.position.y + sin(angleToCamera) * correspondingCreature.radius
                        let creatureClosestPointToCameraCenter = CGPoint(x: closestX, y: closestY)
                        if creatureClosestPointToCameraCenter.x > camera!.position.x - size.width/2 * camera!.xScale &&
                           creatureClosestPointToCameraCenter.x < camera!.position.x + size.width/2 * camera!.xScale &&
                           creatureClosestPointToCameraCenter.y > camera!.position.y - size.height/2 * camera!.yScale &&
                           creatureClosestPointToCameraCenter.y < camera!.position.y + size.height/2 * camera!.yScale {
                            warningSign.hidden = true
                        } else {
                            warningSign.hidden = false
                        }
                        
                        // Change the flash rate to be the inverse of the distance between the center of the camera and the corresponding creature
                        warningSign.flashRate = 1000 / camera!.position.distanceTo(correspondingCreature.position)
                        
                    } else {
                        // Despawn warning signs if the corresponding creature is nil
                        warningSignKillList.append(warningSign)
                    }
                }
                
                
                // destroy and remove the warning signs in the kill List
                warningSigns = warningSigns.filter { !warningSignKillList.contains($0) }
                for theFallen in warningSignKillList {
                    theFallen.removeFromParent()
                }
                
                
                // spawn new warning signs if a large enough player is within range (range scales with camera)
                for creature in otherCreatures {
                    if creature === player { continue }
                    if creature.radius > player.radius * C.percentLargerACreatureMustBeToEngulfAnother && creature.position.distanceTo(camera!.position) - creature.radius < testingRange {
                        var warningSignAlreadyExists = false
                        for sign in warningSigns {
                            if sign.correspondingCreature === creature { warningSignAlreadyExists = true }
                        }
                        if !warningSignAlreadyExists {
                            let newWarningSign = WarningSign(creature: creature)
                            newWarningSign.position = camera!.convertPoint(creature.position, fromNode: self)
                            newWarningSign.position.x.clamp(-size.width / 2 + newWarningSign.size.width/2, size.width / 2 - newWarningSign.size.width/2)
                            newWarningSign.position.y.clamp(-size.height / 2 + newWarningSign.size.height/2, size.height / 2 - newWarningSign.size.height/2)

                            newWarningSign.zPosition = -6
                            warningSigns.append(newWarningSign)
                            camera!.addChild(newWarningSign)
                        }
                    }
                }
                
            }
        }
    }
    
    let masterNode = SKLabelNode(fontNamed: "Chalkboard SE Regular 32.0")
    func spawnFlyingNumberOnPlayerMouth(points: Int) {
        if points == 0 { return }
        if let player = player {
            let labelNode = masterNode.copy() as! SKLabelNode
            var text: String = String(points)
            if points > 0 { text = "+\(text)" }
            labelNode.text = text
            let pointOnPlayersMouth = convertPoint(CGPoint(x: player.radius, y: 0), fromNode: player)
            labelNode.position = pointOnPlayersMouth
            labelNode.zPosition = 100
            labelNode.xScale = camera!.xScale
            labelNode.yScale = camera!.yScale
            addChild(labelNode)
            labelNode.runAction(SKAction.moveBy(CGVector(dx: 0, dy: 60), duration: 0.6))
            labelNode.runAction(SKAction.fadeOutWithDuration(0.6), completion: {
                self.removeFromParent()
            })
        }
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


func areaOfCircleWithRadius(r: CGFloat) -> CGFloat {
    return CGFloat(pi) * r * r
}

func radiusOfCircleWithArea(a: CGFloat) -> CGFloat {
    // a = pi * r**2
    // a / pi = r**2
    // r = sqrt(a / pi)
    return CGFloat(sqrt( a / CGFloat(pi) ))
}


func contains(a:[(x: Int, y: Int)], v:(x: Int, y: Int)) -> Bool {
    let (c1, c2) = v
    for (v1, v2) in a { if v1 == c1 && v2 == c2 { return true } }
    return false
}

