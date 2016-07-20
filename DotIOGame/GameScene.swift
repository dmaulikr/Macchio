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
    
    var prefs: (
        showJoyStick: Bool,
        showArrow: Bool,
        zoomOutFactor: CGFloat) = (
            showJoyStick: true,
            showArrow: true,
            zoomOutFactor: 1
    )
    
    enum State {
        case Playing, GameOver
    }
    var gameState: State = .Playing
    
    var previousTime: CFTimeInterval? = nil
    
    let mapSize: (width: CGFloat, height: CGFloat) = (width: 6000, height: 6000)
    
    var cameraScaleToPlayerRadiusRatios: (x: CGFloat!, y: CGFloat!) = (x: nil, y: nil)
    
    var player: PlayerCreature?
    let spawnPosition = CGPoint(x: 200, y: 200)
    var otherCreatures: [Creature] = []
    var allCreatures: [Creature] {
        return (player != nil ? [player!] : []) + otherCreatures
    }
    
    var score: Int = 0 {
        didSet { scoreLabel.text = String(score) }
    }
    var scoreLabel: SKLabelNode!
    
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
    func convertWorldPointToOrbChunkLocation(point: CGPoint) -> (x: Int, y: Int)? {
        if point.x < 0 || point.x > mapSize.width || point.y < 0 || point.y > mapSize.height { return nil }
        let x = Int(point.x / orbChunkWidth); let y = Int(point.y / orbChunkHeight)
        return (x: x, y: y)
    }
    let orbChunkWidth: CGFloat = 600, orbChunkHeight: CGFloat = 600
    var numOfChunkColumns: Int { return Int(mapSize.width / orbChunkWidth) }
    var numOfChunkRows: Int { return Int(mapSize.height / orbChunkHeight) }
    let orbsToAreaRatio: CGFloat = 0.000010
    var numOfOrbsThatNeedToBeInTheWorld: Int { return Int(orbsToAreaRatio * mapSize.width * mapSize.height) }
    let creaturesToAreaRatio: CGFloat = 0.000002
    var numOfCreaturesThatMustExist: Int { return Int(creaturesToAreaRatio * mapSize.width * mapSize.height) }
    
    var goopMines: [GoopMine] = []
    
    override func didMoveToView(view: SKView) {
        player = PlayerCreature(name: "Yoloz Boy 123", playerID: 1, color: .Blue)
        if let player = player {
            player.position = spawnPosition
            self.addChild(player)
            cameraScaleToPlayerRadiusRatios.x = camera!.xScale / player.radius
            cameraScaleToPlayerRadiusRatios.y = camera!.yScale / player.radius
            
            scoreLabel = childNodeWithName("//scoreLabel") as! SKLabelNode
            scoreLabel.horizontalAlignmentMode = .Left
            
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
            c.position.x.clamp(0+c.targetRadius, mapSize.width-c.targetRadius)
            c.position.y.clamp(0+c.targetRadius, mapSize.height-c.targetRadius)
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
        
        //      ----Handle collisions----
        handleCreatureAndOrbCollisions()
        handleCreatureAndMineCollisions()
        handleCreatureAndCreatureCollisions()
        
        handleMineSpawningAndDecay()
        handleOrbSpawning()
        handleCreatureSpawning()
        
        updateUI()
        
        if let player = player {
            score = Int(player.radius * 100000) / 100
        }
        
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
    }
    
    func handleOrbChunkCollision(orbChunk: [EnergyOrb], withCreature c: Creature) -> [EnergyOrb] {
        // returns a new list of orbs for the chunk without the removed ones.
        var orbKillList: [EnergyOrb] = orbChunk.filter { $0.overlappingCircle(c) && !$0.isEaten }
        for orb in orbChunk {
            if orb.overlappingCircle(c) {
                orbKillList.append(orb)
            }
        }
        for orb in orbKillList {
            let fadeAction = SKAction.fadeOutWithDuration(0.4)
            let remove = SKAction.runBlock { self.removeFromParent() }
            orb.runAction(SKAction.sequence([fadeAction, remove]))
            orb.isEaten = true
            c.targetArea += orb.growAmount
            //            if c === player { score += growAmountToPoints(orb.growAmount) }
        }
        return orbChunk.filter { !orbKillList.contains($0) }
    }

    
    func handleCreatureAndMineCollisions() {
        // Mine collisions with creatures including player
        var creatureKillList: [Creature] = []
        for creature in allCreatures {
            for mine in goopMines {
                if mine.overlappingCircle(creature) && mine !== creature.freshlySpawnedMine {
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
            seedAutoOrbClusterWithBudget(x.growAmount, aboutPoint: x.position, withinRadius: x.targetRadius * x.orbSpawnUponDeathRadiusMultiplier)
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
                    if theBigger.radius > theSmaller.radius * 1.11 {
                        if theBigger.position.distanceTo(theSmaller.position) < theBigger.radius {
                            // The bigger has successfully engulfed the smaller
                            theBigger.targetArea += theSmaller.growAmount
                            theEaten.append(theSmaller)
//                            if theBigger === player {
//                                score += growAmountToPoints(theSmaller.growAmount)
//                            }
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

    }
    
    func handleMineSpawningAndDecay() {
        // DESPAWNING of decayed mines
        // get rid of the decayed mines and seed orbs in their place
        let mineKillList = goopMines.filter { $0.lifeCounter > $0.lifeSpan }
        goopMines = goopMines.filter { !mineKillList.contains($0) }
        for mine in mineKillList {
            seedAutoOrbClusterWithBudget(mine.growAmount, aboutPoint: mine.position, withinRadius: mine.radius)
            mine.removeFromParent()
        }
        
        // SPAWNING of mines (behind players with their flags on) 👹 💣
        // Here I believe all creatures will be treated equally
        for creature in allCreatures {
            if creature.spawnMineAtMyTail {
                let freshMine = spawnMineAtPosition(creature.position, playerRadius: creature.radius, growAmount: creature.growAmount * creature.percentSizeSacrificeToLeaveMine, color: creature.playerColor, leftByPlayerID: creature.playerID)
                creature.freshlySpawnedMine = freshMine
                creature.spawnMineAtMyTail = false
                creature.mineSpawned()
            }
            
            // Take out the fresh mine reference from players if the mine isn't "fresh" anymore i.e. the player has finished the initial contact and can be harmed by their own mine.
            if let freshMine = creature.freshlySpawnedMine {
                if !freshMine.overlappingCircle(creature) { creature.freshlySpawnedMine = nil }
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
                seedSmallOrbAtPosition(newPosition)
            }
        }
    }
    
    func handleCreatureSpawning() {
        let numOfCreaturesThatNeedToBeSpawnedNow = numOfCreaturesThatMustExist - otherCreatures.count
        for _ in 0..<numOfCreaturesThatNeedToBeSpawnedNow {
            let x = CGFloat.random(min: 0, max: mapSize.width)
            let y = CGFloat.random(min: 0, max: mapSize.height)
            spawnAICreatureAtPosition(CGPoint(x: x, y: y))
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
                    directionArrow.position += CGVector(dx: deltaX / 3, dy: deltaY / 3)
                }
                
                // Change mine buttons image to can leave or can't
                if player.canLeaveMine { leaveMineButton.buttonIcon.texture = leaveMineButton.canPressTexture }
                else { leaveMineButton.buttonIcon.texture = leaveMineButton.unableToPressTexture }
                
                // Make sure the boost button is greyed if the player can't boost
                if !player.canBoost {
                    boostButton.buttonIcon.texture = boostButton.unableToPressTexture
                } else if player.isBoosting {
                    boostButton.buttonIcon.texture = boostButton.pressedTexture
                } else {
                    boostButton.buttonIcon.texture = boostButton.defaultTexture
                }
                
            }
        }
    }
    
    
    func seedOrbAtPosition(position: CGPoint, growAmount: CGFloat, minRadius: CGFloat, maxRadius: CGFloat, artificiallySpawned: Bool) -> EnergyOrb? {
        if let location = convertWorldPointToOrbChunkLocation(position) {
            let newOrb = EnergyOrb()
            newOrb.position = position
            newOrb.growAmount = growAmount
            newOrb.minRadius = minRadius
            newOrb.maxRadius = maxRadius
            newOrb.artificiallySpawned = artificiallySpawned
            orbChunks[location.x][location.y].append(newOrb)
            addChild(newOrb)
            return newOrb
        }
        return nil
    }
    
    let smallOrbGrowAmount: CGFloat = 400
    let richOrbGrowAmount: CGFloat = 7500
    func seedSmallOrbAtPosition(position: CGPoint, artificiallySpawned: Bool = false) -> EnergyOrb? {
        return seedOrbAtPosition(position, growAmount: smallOrbGrowAmount, minRadius: 10, maxRadius: 14, artificiallySpawned: artificiallySpawned)
    }
    
    func seedRichOrbAtPosition(position: CGPoint, artificiallySpawned: Bool = false) -> EnergyOrb? {
        return seedOrbAtPosition(position, growAmount: richOrbGrowAmount, minRadius: 15, maxRadius: 20, artificiallySpawned: artificiallySpawned)
    }
    
    func seedSmallOrbClusterWithBudget(growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat) {
        //Budget is the growAmount quantity that once existed in the entity that spawned the orbs. Mostly, this will be from dead players or old mines.
        var budget = growAmount
        while budget > 0 {
            let randAngle = CGFloat.random(min: 0, max: 360).degreesToRadians()
            let randDist = CGFloat.random(min: 0, max: radius)
            let position = CGPoint(x: cos(randAngle) * randDist + aboutPoint.x, y: sin(randAngle) * randDist + aboutPoint.y)
            if let newOrb = seedSmallOrbAtPosition(position, artificiallySpawned: true) {
                budget -= newOrb.growAmount
            }
        }
        
    }
    
    func seedRichOrbClusterWithBudget(growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat) {
        var budget = growAmount
        while budget > 0 {
            let randAngle = CGFloat.random(min: 0, max: 360).degreesToRadians()
            let randDist = CGFloat.random(min: 0, max: radius)
            let position = CGPoint(x: cos(randAngle) * randDist + aboutPoint.x, y: sin(randAngle) * randDist + aboutPoint.y)
            if let newOrb = seedRichOrbAtPosition(position, artificiallySpawned: true) {
                budget -= newOrb.growAmount
            }
        }
        
    }
    
    func seedAutoOrbClusterWithBudget(growAmount: CGFloat, aboutPoint: CGPoint, withinRadius radius: CGFloat) {
        let maxNumberOfSmallOrbs = 30
        let costToMaxOutSmallOrbs = CGFloat(maxNumberOfSmallOrbs) * smallOrbGrowAmount
        if growAmount < costToMaxOutSmallOrbs {
            seedSmallOrbClusterWithBudget(growAmount, aboutPoint: aboutPoint, withinRadius: radius)
        } else {
            seedSmallOrbClusterWithBudget(costToMaxOutSmallOrbs, aboutPoint: aboutPoint, withinRadius: radius)
            let richOrbBudget = growAmount - costToMaxOutSmallOrbs
            seedRichOrbClusterWithBudget(richOrbBudget, aboutPoint: aboutPoint, withinRadius: radius)
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
        let newCreature = AICreature(name: "BS Player ID", playerID: randomID(), color: randomColor(), startRadius: CGFloat.random(min: Creature.minRadius, max: 100), gameScene: self, rxnTime: CGFloat.random(min: 0.02, max: 0.5))
        newCreature.position = position
        newCreature.velocity.angle = CGFloat.random(min: 0, max: 360) //Don't forget that velocity.angle for creatures operates in degrees
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


//func growAmountToPoints(growAmount: CGFloat) -> Int {
//    return Int(growAmount / 100)
//}

func areaOfCircleWithRadius(r: CGFloat) -> CGFloat {
    return CGFloat(pi) * r * r
}

//func fastRandom(min: CGFloat, max: CGFloat) -> {
//    rand()
//}

func contains(a:[(x: Int, y: Int)], v:(x: Int, y: Int)) -> Bool {
    let (c1, c2) = v
    for (v1, v2) in a { if v1 == c1 && v2 == c2 { return true } }
    return false
}

