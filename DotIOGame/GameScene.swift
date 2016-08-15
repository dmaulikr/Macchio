//
//  GameScene.swift
//  DotIOGame
//
//  Created by Ryan Anderson on 7/10/16.
//  Copyright (c) 2016 Ryan Anderson. All rights reserved.
//

import Foundation
import SpriteKit

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
            zoomOutFactor: 1.5
    )
    let mixpanelTracker = RYNMixpanelTracker()
    
    var theEnteredInPlayerName = ""
    
    enum State {
        case Playing, GameOver
    }
    var gameState: State = .Playing
    
    var previousTime: CFTimeInterval? = nil
    
    let mapSize: (width: CGFloat, height: CGFloat) = (width: 6000, height: 6000)
    var bgGraphics: SKNode!
    
    //var cameraScaleToPlayerRadiusRatios: (x: CGFloat!, y: CGFloat!) = (x: nil, y: nil)
    //var cameraScaleToPlayerRadiusRatio: CGFloat!
    var cameraTarget: SKNode!
    
    var player: Creature?
    let spawnPosition = CGPoint(x: 200, y: 200)
    var otherCreatures: [Creature] = []
    var allCreatures: [Creature] {
        return (player != nil ? [player!] : []) + otherCreatures
    }
    
    enum PointSource {
        case Orbs, KillsEat, KillsMine, Size
    }
    
    var playerScore: Int = 0 {
        didSet { scoreLabel.text = "Score: \(playerScore)" }
    }
    var scoreLabel: SKLabelNode!
    
    var playerSize: Int = 0 {
        didSet { sizeLabel.text = "Your Size: \(playerSize)" }
    }
    var sizeLabel: SKLabelNode!
    var rankLabel: SKLabelNode!
    
    var hud: SKNode!
    
    var directionArrow: SKSpriteNode!
    var directionArrowTargetPosition: CGPoint!
    var directionArrowAnchor: SKNode! //An invisible node that sticks to the player, constantly faces the player's target angle, and works as an anchor for the direction arrow. It's important that this node ALWAYS be facing the target angle, for the arrow needs to feel responsive and the player can have intermediate turning states.
    let minDirectionArrowDistanceFromPlayer: CGFloat = 60
    var directionArrowDragMultiplierToPlayerRadiusRatio: CGFloat!
    
    var playerMovingTouch: UITouch? = nil
    var originalPlayerMovingTouchPositionInCamera: CGPoint? = nil
    let frozenTouchDetectionTime: CGFloat = 3.0 // If the touch is not moved at all for this many seconds, nullify the touch
    var frozenTouchCounter: CGFloat = 0
    
    var joyStickBox: SKNode!, controlStick: SKNode!
    let maxControlStickDistance: CGFloat = 20
    
    var boostButton: BoostButton!
    var leaveMineButton: MineButton!
    
    var orbLayer: SKNode!
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
    var numOfOrbsThatNeedToBeInTheWorld: Int { return Int(C.orbsToAreaRatio * mapSize.width * mapSize.height) }
    
    var numOfCreaturesThatMustExist: Int { return Int(C.creaturesToAreaRatio * mapSize.width * mapSize.height) }
    
    var goopMines: [Mine] = []
    
    var warningSigns: [WarningSign] = []
    var killPointsLabelOriginal: SKLabelNode!
    var smallScoreLabelOriginal: SKLabelNode!
    var leaderBoard: LeaderBoard!
    var masterPlayerNameLabel: SKLabelNode!
    var playerNameLabelNodeXScaleToPlayerRadiusRatio: CGFloat!
    var playerNameLabelNodeYScaleToPlayerRadiusRatio: CGFloat!
    var playerNameLabelsAndCorrespondingIDs: [(label: SKLabelNode, playerID: Int)] = []
    
    var restartButton: MSButtonNode!
    var backToMenuButton: MSButtonNode!
    
    var loadingImage: SKSpriteNode!
    let loadingImageMoveTime = 0.2
    
    override func didMoveToView(view: SKView) {
//        player = AICreature(name: "Yoloz Boy 123", playerID: 1, color: .Red, startRadius: 80, gameScene: self, rxnTime: 0)
        player = PlayerCreature(name: theEnteredInPlayerName, playerID: randomID(), color: randomColor(), startRadius: 80)
        defer {
            spawnPlayerNameLabel(forCreature: player!)
        }

        player!.position = computeValidCreatureSpawnPoint(player!.radius)
        self.addChild(player!)
        
        //camera!.xScale = (camera!.xScale * prefs.zoomOutFactor).clamped(C.camera_scaleMinimum, 100)
        //camera!.yScale = (camera!.yScale * prefs.zoomOutFactor).clamped(C.camera_scaleMinimum, 100)
        let theCameraScale = calculateCameraScale(givenPlayerRadius: player!.radius, givenMaxPlayerRadiusToScreenWidthRatio: C.maxPlayerRadiusToScreenWidthRatio)
        camera!.xScale = theCameraScale
        camera!.yScale = theCameraScale
        //cameraScaleToPlayerRadiusRatios.x = camera!.xScale / player!.radius
        //cameraScaleToPlayerRadiusRatios.y = camera!.yScale / player!.radius
        //cameraScaleToPlayerRadiusRatio = camera!.xScale / player!.radius
        cameraTarget = player
        
        bgGraphics = childNodeWithName("bgGraphics")
        bgGraphics.xScale = mapSize.width / 6000
        bgGraphics.yScale = mapSize.height / 6000
        
        hud = SKNode() // Hud will act as a container for ui elements
        camera!.addChild(hud)
        
        scoreLabel = childNodeWithName("//scoreLabel") as! SKLabelNode
        sizeLabel = childNodeWithName("//sizeLabel") as! SKLabelNode
        rankLabel = childNodeWithName("//rankLabel") as! SKLabelNode
        // Position all the labels. Kinda like constraints
        let allAroundPadding: CGFloat = 20
        scoreLabel.position = CGPoint(x: -size.width/2 + allAroundPadding, y: size.height/2 - allAroundPadding) // Anchor point at upper left
        sizeLabel.position = CGPoint(x: -size.width/2 + allAroundPadding, y: -size.height/2 + allAroundPadding) // Anchor point at lower left
        rankLabel.position = CGPoint(x: -size.width/2 + allAroundPadding, y: size.height/2 - allAroundPadding - 30) // Anchor point at upper left
        
        directionArrow = SKSpriteNode(imageNamed: "arrow.png")
        directionArrow.zPosition = 100
        directionArrow.size = CGSize(width: player!.size.width/5, height: player!.size.height/5)
        directionArrow.zRotation = player!.velocity.angle.degreesToRadians()
        directionArrow.hidden = true
        directionArrowTargetPosition = directionArrow.position
        hud.addChild(directionArrow)
        directionArrowAnchor = SKNode()
        directionArrowAnchor.position = player!.position
        directionArrowAnchor.zRotation = player!.targetAngle.degreesToRadians()
        directionArrowDragMultiplierToPlayerRadiusRatio = 1 / player!.radius
        self.addChild(directionArrowAnchor)
        
        camera!.zPosition = 100
        joyStickBox = childNodeWithName("//joyStickBox")
        controlStick = childNodeWithName("//controlStick")
        joyStickBox.hidden = true
        
        boostButton = BoostButton()
        boostButton.position.x = size.width/2 - boostButton.size.width/2
        boostButton.position.y = -size.height/2 + boostButton.size.height/2
        hud.addChild(boostButton)
        boostButton.addButtonIconToParent()
        boostButton.onPressed = player!.startBoost
        boostButton.onReleased = player!.stopBoost
        
        leaveMineButton = MineButton()
        leaveMineButton.position.x = size.width/2 - leaveMineButton.size.width / 2
        leaveMineButton.position.y = -size.height/2 + boostButton.size.height + leaveMineButton.size.height / 2
        hud.addChild(leaveMineButton)
        leaveMineButton.addButtonIconToParent()
        leaveMineButton.onPressed = player!.leaveMine
        leaveMineButton.onReleased = { return }
        
        orbLayer = SKNode()
        self.addChild(orbLayer)
        
        // Initialize orbChunks with empty arrays
        for col in 0..<numOfChunkColumns {
            orbChunks.append([])
            for _ in 0..<numOfChunkRows {
                orbChunks[col].append([])
            }
        }
        
        killPointsLabelOriginal = childNodeWithName("killPointsLabel") as! SKLabelNode
        smallScoreLabelOriginal = childNodeWithName("smallScoreLabel") as! SKLabelNode
        
        leaderBoard = LeaderBoard()
        leaderBoard.xScale = 0.3
        leaderBoard.yScale = 0.3
        let boardX = (size.width/2) - (leaderBoard.slotSize.width*leaderBoard.xScale)-10
        let boardY = (size.height/2) - (leaderBoard.slotSize.height*leaderBoard.yScale*CGFloat(leaderBoard.numberOfSlots)) - 10
        
        leaderBoard.position = CGPoint(x: boardX, y: boardY)
        hud.addChild(leaderBoard)
        
        masterPlayerNameLabel = childNodeWithName("playerNameLabelMaster") as! SKLabelNode
        let dummyPlayer = childNodeWithName("playerdummy") as! SKSpriteNode
        let dummyRadius = dummyPlayer.size.width / 2
        playerNameLabelNodeXScaleToPlayerRadiusRatio = masterPlayerNameLabel.xScale / dummyRadius
        playerNameLabelNodeYScaleToPlayerRadiusRatio = masterPlayerNameLabel.yScale / dummyRadius
            
        restartButton = childNodeWithName("//restartButton") as! MSButtonNode
        backToMenuButton = childNodeWithName("//backToMenuButton") as! MSButtonNode
        restartButton.state = .MSButtonNodeStateHidden
        backToMenuButton.state = .MSButtonNodeStateHidden
        restartButton.selectedHandler = restartGameScene
        backToMenuButton.selectedHandler = goBackToMainScene
        
        loadingImage = childNodeWithName("//loadingImage") as! SKSpriteNode
        loadingImage.size = self.size
        loadingImage.position = CGPoint(x: 0, y: 0)
        
    }
    
    func computeValidCreatureSpawnPoint(creatureStartRadius: CGFloat = C.creature_minRadius) -> CGPoint {
        // This function assumes the creature has not been spawned yet
        let randX = CGFloat.random(min: 0 + creatureStartRadius, max: mapSize.width - creatureStartRadius )
        let randY = CGFloat.random(min: 0 + creatureStartRadius, max: mapSize.height - creatureStartRadius)
        let randPoint = CGPoint(x: randX, y: randY)
        for otherLiveCreature in allCreatures {
            if otherLiveCreature.position.distanceTo(randPoint) - creatureStartRadius - otherLiveCreature.radius < 400 {
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
                    frozenTouchCounter = 0
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
                    frozenTouchCounter = 0
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
        handleOrbSpawningAndDecay()
        handleCreatureSpawning()
        
        updateUI()
        
        
        if let player = player {
            playerSize = convertAreaToSizeNumber(player.targetArea)
            playerScore = player.score
            rankLabel.text = "Rank \(leaderBoard.getRankOfCreature(withID: player.playerID)!) of \(allCreatures.count)"
        }
        if let playerMovingTouch = playerMovingTouch {
            //print(frozenTouchCounter)
            frozenTouchCounter += CGFloat(deltaTime)
            if frozenTouchCounter >= frozenTouchDetectionTime {
                frozenTouchCounter = 0
                var fakeTouches = Set<UITouch>(); fakeTouches.insert(playerMovingTouch)
                touchesEnded(fakeTouches, withEvent: nil)
            }
        }
        
    }
    
    func convertAreaToSizeNumber(area: CGFloat) -> Int {
        return Int(radiusOfCircleWithArea(area))
    }
    
    func convertAreaToKillPoints(area: CGFloat) -> Int {
        //return Int(radiusOfCircleWithArea(area) * 100) / 100
        let radius = radiusOfCircleWithArea(area)
        switch radius {
        case let r where r <= 50:
            return 50
        case let r where r > 50 && r <= 100:
            return 100
        case let r where r > 100 && r <= 150:
            return 150
        case let r where r > 150 && r <= 200:
            return 200
        case let r where r > 200 && r <= 250:
            return 250
        case let r where r > 250:
            return 300
        default:
            return 0
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
        
        // After all the orb collisions have been handled, itereate through the beacons to see if there are any that should be removed..
        orbBeacons = orbBeacons.filter { $0.totalValue > C.orbBeacon_minimumValueRequirement }
        //print (orbBeacons.count)
        
    }
    
    func handleOrbChunkCollision(orbChunk: [EnergyOrb], withCreature c: Creature) -> [EnergyOrb] {
        // handles the collisons between a given creature and all the orbs in the given chunk
        // returns a new list of orbs for the chunk without the removed ones.
        let orbKillList: [EnergyOrb] = orbChunk.filter { $0.overlappingCircle(c) }
        
        for orb in orbKillList {
            let fadeAction = SKAction.fadeOutWithDuration(0.3)
            //let remove = SKAction.runBlock { self.removeFromParent() }
            orb.removeAllActions()
            orb.runAction(SKAction.sequence([fadeAction]))
            let waitAction = SKAction.waitForDuration(0.3)
            let removeOrbAction = SKAction.runBlock {
                orb.removeFromParent()
            }
            self.runAction(SKAction.sequence([waitAction, removeOrbAction]))
            c.targetArea += orb.growAmount
            
            // Award Points
            let deltaScore: Int = C.orb_pointValues[orb.type]!
            c.awardPoints(deltaScore, fromSource: .Orbs)
            //c.score += deltaScore
            //c.scoreFromOrbs += deltaScore

            if c === player {
                spawnSmallScoreTextOnPlayerMouth(deltaScore)
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
                    
                    if creature.targetRadius >= C.creature_minimumRadiusToApplyMineSizeReductionInsteadOfInstantDeath {
                        // Creature is large enough so that a size reduction can be applied instead of just instant death
                        let orgRadius = creature.targetRadius
                        let radiusLoss = creature.targetRadius * C.creature_hitMinePercentMassReduction
                        let newRadius = creature.targetRadius - radiusLoss
                        //creature.radius = newRadius
                        creature.targetRadius = newRadius
                        creature.speedDebuffTimeCounter = 0 // Intitiate a speed debuff
                        creature.isBoosting = false
                        
                        // Award points to the creature who left the mine
                        let deltaScore = convertAreaToKillPoints(areaOfCircleWithRadius(radiusLoss))
                        for creature in allCreatures {
                            if creature.playerID == mine.leftByPlayerID {
                                //creature.score += deltaScore
                                creature.awardPoints(deltaScore, fromSource: .KillsMine)
                                break
                            }
                        }
                        // Show kill points if the creature was the player
                        if mine.leftByPlayerID == player?.playerID && creature !== player {
                            spawnKillPoints(deltaScore)
                        }
                        
                        
                        let waitAction = SKAction.waitForDuration(0.3)
                        let spawnOrbClusterAction = SKAction.runBlock {
                            let budgetOfNewCluster = (areaOfCircleWithRadius(orgRadius) - areaOfCircleWithRadius(newRadius)) * C.energyTransferPercent
                            self.seedOrbCluster(ofType: .Glorious, withBudget: budgetOfNewCluster, aboutPoint: creature.position, withinRadius: orgRadius, minRadius: newRadius, exclusivelyInColor: creature.playerColor)
                        }
                        runAction(SKAction.sequence([waitAction, spawnOrbClusterAction]))
                        
                        
                    } else {
                        // creature just died
                        creatureKillList.append(creature)
                        seedOrbCluster(ofType: .Glorious, withBudget: creature.growAmount * C.energyTransferPercent, aboutPoint: creature.position, withinRadius: creature.targetRadius * C.creature_orbSpawnUponDeathRadiusMultiplier, exclusivelyInColor: creature.playerColor)

                        let deltaScore = convertAreaToKillPoints(creature.targetArea)
                        for creature in allCreatures {
                            if creature.playerID == mine.leftByPlayerID {
                                //creature.score += deltaScore
                                creature.awardPoints(deltaScore, fromSource: .KillsMine)
                                break
                            }
                        }
                        if mine.leftByPlayerID == player?.playerID && creature !== player {
                            spawnKillPoints(deltaScore)
                        }
                    }
                }
            }
            
        }
        
        otherCreatures = otherCreatures.filter { !creatureKillList.contains($0) }
        for x in creatureKillList {
            if x === player && gameState != .GameOver {
                gameOver()
            } else {
                let fadeOutAction = SKAction.fadeOutWithDuration(C.creature_deathFadeOutDuration)
                x.runAction(fadeOutAction)
                let waitForFadeOut = SKAction.waitForDuration(C.creature_deathFadeOutDuration)
                runAction(waitForFadeOut, completion: { x.removeFromParent() } )
            }
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
                    if theBigger.radius > theSmaller.radius * C.percentLargerRadiusACreatureMustBeToEngulfAnother {
                        if theBigger.position.distanceTo(theSmaller.position) < theBigger.radius {
                            // The bigger has successfully engulfed the smaller
                            theBigger.targetArea += theSmaller.growAmount * C.energyTransferPercent
                            theEaten.append(theSmaller)
                            let deltaScore = convertAreaToKillPoints(theSmaller.targetArea)
                            //theBigger.score += deltaScore
                            theBigger.awardPoints(deltaScore, fromSource: .KillsEat)
                            if theBigger === player {
                                // add a flying number
                                //spawnFlyingNumberOnPlayerMouth(convertAreaToScore(theSmaller.targetArea))
                                spawnKillPoints(deltaScore)
                            }
                        }
                    } else {
                        // Since the two creatures are pretty close in size, they can't eat each other. They can't even overlap. They just bump into eachother
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
            // when the orb cluster is seeded, mine.growAmount is not multiplied by C.energyTransferPercent, because this was already applied when the creature left the mine. (Remember: energy transfer percent is the grow amount that is kept when it changes state (e.g. creature ->X% mine ->X% orbs)
            seedOrbCluster(ofType: .Glorious, withBudget: mine.growAmount, aboutPoint: mine.position, withinRadius: mine.radius, exclusivelyInColor: mine.leftByPlayerColor)
            let shrinkAction = SKAction.scaleTo(0, duration: 1)
            mine.runAction(shrinkAction)
            let waitForShrink = SKAction.waitForDuration(1)
            runAction(waitForShrink, completion: {
                mine.removeFromParent()
            })
        }
//        let minesInScene = self.children.filter { $0 is Mine }
//        if minesInScene.count > 0 {
//            print(goopMines.count / minesInScene.count)
//        }
        
        // SPAWNING of mines (behind players with their flags on) 👹 💣
        // Here I believe all creatures will be treated equally
        for creature in allCreatures {
            if creature.spawnMineAtMyTail {
                creature.spawnMineAtMyTail = false
                
            
                let valueForMine: CGFloat
                if creature.targetArea * (1-creature.percentSizeSacrificeToLeaveMine) > areaOfCircleWithRadius(C.creature_minRadius) {
                    valueForMine = creature.targetArea * creature.percentSizeSacrificeToLeaveMine * C.energyTransferPercent
                } else {
                    valueForMine = 0
                }
                //let freshMineSpawnAngle = (creature.velocity.angle + 180).degreesToRadians()
                //let freshMineX = creature.position.x + cos(freshMineSpawnAngle) * (creature.radius / 2)
                //let freshMineY = creature.position.y + sin(freshMineSpawnAngle) * (creature.radius / 2)
                //let freshMine = self.spawnMineAtPosition(CGPoint(x: freshMineX, y: freshMineY), mineRadius: creature.radius/2, growAmount: valueForMine, color: creature.playerColor, leftByPlayerID: creature.playerID)
                let freshMine = self.spawnMineAtPosition(creature.position, mineRadius: creature.radius, growAmount: valueForMine, color: creature.playerColor, leftByPlayerID: creature.playerID)
                freshMine.name = "\(creature.name!) shuriken"
                
                
                creature.freshlySpawnedMines.append(freshMine)
                
                // The commented out code below assigns fresh mines to ANY creature that happens to be overlapping the mine when it spawns.
//                for otherCreature in allCreatures {
//                    if otherCreature === creature { continue }
//                    if freshMine.overlappingCircle(otherCreature) {
//                        otherCreature.freshlySpawnedMines.append(freshMine)
//                    }
//                }
//                if creature === player {
//                    //spawnFlyingNumberOnPlayerMouth(-convertAreaToScore(freshMine.growAmount))
//                }

                
            
                creature.mineSpawned()
            }
            
        }
        
        
        for creature in allCreatures {
            // Take out the fresh mine reference from players if the mine isn't "fresh" anymore i.e. the player has finished the initial contact and can be harmed by their own mine.
            var mineRemoveList:[Mine] = []
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
    
    func handleOrbSpawningAndDecay() {
        var currrentOrbCount = 0
        for (colIndex ,chunkCol) in orbChunks.enumerate() {
            for (rowIndex, chunk) in chunkCol.enumerate() {
                //var decayedOrbs: [EnergyOrb] = []
                for orb in chunk {
                    if orb.artificiallySpawned == false { currrentOrbCount += 1 }
                }
                
                // Basically take out all the dead orbs. That means removing them from the array and calling removeFromParent()
                orbChunks[colIndex][rowIndex] = orbChunks[colIndex][rowIndex].filter { $0.isAlive }
                let deadOrbs = orbChunks[colIndex][rowIndex].filter { !$0.isAlive }
                for deadOrb in deadOrbs {
                    deadOrb.removeFromParent()
                }
                
                // And for the ones that are near decay, start a fade effect.
                let orbsInNeedOfAFadeEffect = orbChunks[colIndex][rowIndex].filter { $0.isNearDecay && !$0.isAlreadyFading }
                for nearDecayOrb in orbsInNeedOfAFadeEffect {
                    nearDecayOrb.isAlreadyFading = true
                    nearDecayOrb.runAction(SKAction.fadeOutWithDuration(NSTimeInterval(C.orb_fadeOutForXSeconds)))
                }
            }
        }
                
        let numOfOrbsToSpawnNow = numOfOrbsThatNeedToBeInTheWorld - currrentOrbCount
        if numOfOrbsToSpawnNow > 0 {
            for _ in 0..<numOfOrbsToSpawnNow {
                // x times, spawn an orb at a random world positon
                let newPosition = CGPoint(x: CGFloat.random(min: 0, max: mapSize.width), y: CGFloat.random(min: 0, max: mapSize.height) )
                let randType: OrbType = CGFloat.random() > 0.9 ? .Rich : .Small
                seedOrbWithSpecifiedType(randType, atPosition: newPosition)
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
    
                //let theCameraScale = calculateCameraScale(forGivenPlayerRadius: player.radius)
                let theCameraScale = calculateCameraScale(givenPlayerRadius: player.radius, givenMaxPlayerRadiusToScreenWidthRatio: C.maxPlayerRadiusToScreenWidthRatio)
                camera!.xScale = theCameraScale
                camera!.yScale = theCameraScale
                
                camera!.position = cameraTarget.position //Follow player on the x axis and y axis
                
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
                if player.mineCoolDownCounter >= C.creature_mineCooldownTime &&
                    player.mineCoolDownCounterPreviousValue < C.creature_mineCooldownTime {
                    // The player has their mine ready for the first time this frame
                    let rotate = SKAction.rotateByAngle(CGFloat(180).degreesToRadians(), duration: 0.7)
                    leaveMineButton.buttonIcon.runAction(rotate)
                    let cropNode = leaveMineButton.greenPart.parent as! SKCropNode
                    cropNode.maskNode?.runAction(rotate)
                }
    
                
                
                // Make sure the boost button is greyed if the player can't boost
//                if !player.canBoost {
//                    boostButton.buttonIcon.texture = boostButton.unableToPressTexture
//                } else
                if player.isBoosting {
                    boostButton.buttonIcon.alpha = 0.6
                } else {
                    boostButton.buttonIcon.alpha = 1
                }
                
                
                // Warning Signs dealt with here! ⚠️
                //let testingRange = C.alertPlayerAboutLargerCreaturesInRange * size.width * camera!.xScale
                let testingRange = C.alertPlayerAboutLargerCreaturesInRange
                // spawn new warning signs if a large enough player is within range (range scales with camera)
                for creature in otherCreatures {
                    if creature === player { continue }
                    if creature.radius > player.radius * C.percentLargerRadiusACreatureMustBeToEngulfAnother && creature.position.distanceTo(camera!.position) - creature.radius < testingRange {
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
                            hud.addChild(newWarningSign)
                        }
                    }
                }

                
                // update the positions of warning signs and despawn/hide them as necessary
                var warningSignKillList: [WarningSign] = []
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
                        } else if correspondingCreature.radius < player.radius * C.percentLargerRadiusACreatureMustBeToEngulfAnother {
                        // 2) despawn the warning sign if the corresponding creature can no longer eat the player
                            warningSignKillList.append(warningSign)
                        }
                        
                        // 3) Hide if the corresponding creature inside the camera?
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
                
                
                
                // Update the leaderboard with data from all the creatures that exist
                let creatureData = allCreatures.map { LeaderBoard.CreatureDataSnapshot(playerName: $0.name!, playerID: $0.playerID, score: $0.score, color: $0.playerColor) }
                leaderBoard.update(creatureData)
                
                // Update the player name labels!
                var keepNameLabelsAndIDs: [(label: SKLabelNode, playerID: Int)] = []
                for nameLabelAndIDTuple in playerNameLabelsAndCorrespondingIDs {
                    let labelNode = nameLabelAndIDTuple.label
                    let correspondingID = nameLabelAndIDTuple.playerID
                    // First check if any shouldn't exist. Probably because their corresponding player died. If the creature is dead, then we don't know about it (it's not in all creatures)
                    if let _ = findCreatureByID(correspondingID) {
                        // The creature exists! This name label deserves to live!
                        keepNameLabelsAndIDs.append(nameLabelAndIDTuple)
                    } else {
                        labelNode.removeFromParent()
                        //print("labelNode removed")
                    }
                }
                playerNameLabelsAndCorrespondingIDs = keepNameLabelsAndIDs
                
                // Now with all the bad ID's filtered out, let's update the positions of all the IDs that do exist
                for (labelNode, playerID) in (playerNameLabelsAndCorrespondingIDs.map {($0.label, $0.playerID)}) {
                    let correspondingCreature = findCreatureByID(playerID)!
                    labelNode.position = CGPoint(x: correspondingCreature.position.x, y: correspondingCreature.position.y + (correspondingCreature.radius*1.2))
                    labelNode.xScale = playerNameLabelNodeXScaleToPlayerRadiusRatio * correspondingCreature.radius
                    labelNode.yScale = playerNameLabelNodeYScaleToPlayerRadiusRatio * correspondingCreature.radius
                }
                
                // If the loading image is still in the center, then get it off the screen (the game state is not game over in this block
                if loadingImage.position.x == 0 && loadingImage.position.y == 0 && !loadingImage.hasActions() {
                    let moveJustOutOfTheScreen = SKAction.moveTo(CGPoint(x: 0, y: self.size.height/2 + self.loadingImage.size.height/2), duration: loadingImageMoveTime)
                    loadingImage.runAction(moveJustOutOfTheScreen)
                }
                
            }
        }
        
        // No matter what, move bgGraphics along with the camera so that we get that parallax effect.
        // Note that the position of bgGraphics represents the lower left corner of the background
        let centerOfMap = CGPoint(x: mapSize.width/2, y: mapSize.height/2)
        //bgGraphics.position = camera!.position.distanceTo(centerOfMap) / CGFloat(20)
        bgGraphics.position = (camera!.position - centerOfMap) / CGPoint(x: 4, y: 4)
        
        
    }
    
    func spawnSmallScoreTextOnPlayerMouth(points: Int) {
        if points == 0 { return }
        if let player = player {
            let newLabelNode = smallScoreLabelOriginal.copy() as! SKLabelNode
            newLabelNode.text = "+\(points)"
            newLabelNode.position = convertPoint(convertPoint(CGPoint(x: player.radius, y: 0), fromNode: player), toNode: camera!)
            hud.addChild(newLabelNode)
            newLabelNode.runAction(SKAction.moveBy(CGVector(dx: 0, dy: 60), duration: 0.8))
            newLabelNode.runAction(SKAction.fadeOutWithDuration(0.8), completion: {
                self.removeFromParent()
            })
        }
    }
    
    func spawnKillPoints(points: Int) {
        if points <= 0 { return }
        let newLabelNode = killPointsLabelOriginal.copy() as! SKLabelNode
        newLabelNode.position = CGPoint(x: 0, y: 50)
        newLabelNode.text = "+\(points)"
        hud.addChild(newLabelNode)
        newLabelNode.xScale = 0.5
        newLabelNode.yScale = 0.5
        let scaleToNormalSizeAction = SKAction.scaleTo(1, duration: 0.15)
        newLabelNode.runAction(scaleToNormalSizeAction)
        let waitAction = SKAction.waitForDuration(1)
        let fadeAction = SKAction.fadeOutWithDuration(0.5)
        newLabelNode.runAction(SKAction.sequence([waitAction, fadeAction]), completion: {
            newLabelNode.removeFromParent()
        })
    }
    
    func randomID() -> Int {
        // Generates a random id number, authenticates it, then returns it
        let randNum = Int(CGFloat.random(min: 10, max: 5000))
        let takenIDs: [Int] = allCreatures.map { $0.playerID }
        for id in takenIDs {
            if id == randNum { return randomID() }
        }
        return randNum
    }
    
    func gameOver() {
        gameState = .GameOver
        
        // If the player is still touching the UI, then nullify the touch, getting rid of the arrow
        if let playerMovingTouch = playerMovingTouch {
            var fakeTouches = Set<UITouch>(); fakeTouches.insert(playerMovingTouch)
            touchesEnded(fakeTouches, withEvent: nil)
        }
        
        // Let the camera zoom out over so slowly
        let zoomOutAction = SKAction.scaleBy(3, duration: 30)
        camera!.runAction(zoomOutAction)
        
        // nillfiying player will remove it from allCreatures; it won't move anymore
        let player = self.player!
        self.player = nil
        
        // Track the players final state into mixpanel
        mixpanelTracker.trackGameFinished(Double(player.timePlayed), finalScore: Int(player.score), percentScoreFromSize: player.percentScoreFromSize, percentScoreFromOrbs: player.percentScoreFromOrbs, percentScoreFromKills: player.percentScoreFromKills, finalRank: leaderBoard.getRankOfCreature(withID: player.playerID)!)
        
        // The rest are visual effects
        let fadeOutAction = SKAction.fadeOutWithDuration(C.creature_deathFadeOutDuration)
        player.runAction(fadeOutAction)
        let waitForFade = SKAction.waitForDuration(C.creature_deathFadeOutDuration)
        runAction(waitForFade, completion: {
            player.removeFromParent()
        })
        
        //Hide the HUD
        let hideAction = SKAction.fadeOutWithDuration(0.3)
//        for child in hud.children {
//            child.runAction(hideAction)
//        }
        hud.runAction(hideAction)
        //Hide names
        for nameLabel in (playerNameLabelsAndCorrespondingIDs.map {$0.label}) {
            nameLabel.runAction(hideAction)
        }
//        
//        let waitALittle = SKAction.waitForDuration(2)
//        let fadeOutToBlack = SKAction.fadeOutWithDuration(1)
//        let waitALittleLonger = SKAction.waitForDuration(1)
//        let sequence = SKAction.sequence([waitALittle, fadeOutToBlack, waitALittleLonger])
//        runAction(sequence, completion: {
//            
//        })
        let waitOneSecond = SKAction.waitForDuration(1)
        let showTheButtons = SKAction.runBlock {
            // Showing the buttons in itself is starting an additional SKAction that will cause them to fade in. And then another action to wait for them to fade in and after they are visible, change their state to active. Bear with me.
            let btnFadeInTime = 0.5
            //let fadeInAction = SKAction.fadeInWithDuration(btnFadeInTime)
            let fadeInAction = SKAction.fadeAlphaTo(0.85, duration: btnFadeInTime)
            self.restartButton.runAction(fadeInAction)
            self.backToMenuButton.runAction(fadeInAction)
            
            let waitForButtonsToFadeIn = SKAction.waitForDuration(btnFadeInTime)
            let enableTheButtons = SKAction.runBlock {
                self.restartButton.state = .MSButtonNodeStateActive
                self.backToMenuButton.state = .MSButtonNodeStateActive
            }
            self.runAction(SKAction.sequence([waitForButtonsToFadeIn, enableTheButtons]))
        }
        self.runAction(SKAction.sequence([waitOneSecond, showTheButtons]))
        
        
    }
    
    func restartGameScene() {
        let moveToCenterOfScreen = SKAction.moveTo(CGPoint(x: 0, y: 0), duration: loadingImageMoveTime)
        loadingImage.runAction(moveToCenterOfScreen)
        let waitForLoadingImageToMoveToTheCenterOfScreen = SKAction.waitForDuration(loadingImageMoveTime + 0.1)
        let presentNewGameScene = SKAction.runBlock {
            let skView = self.view as SKView!
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            scene.theEnteredInPlayerName = self.theEnteredInPlayerName
            scene.scaleMode =  SKSceneScaleMode.ResizeFill
            skView.presentScene(scene)
        }
    
        runAction(SKAction.sequence([waitForLoadingImageToMoveToTheCenterOfScreen, presentNewGameScene]))
    }
    
    func goBackToMainScene() {
        let skView = self.view as SKView!
        let scene = MainScene(fileNamed:"MainScene") as MainScene!
        scene.presetPlayerName = theEnteredInPlayerName
        scene.scaleMode =  SKSceneScaleMode.ResizeFill
        //skView.presentScene(scene, transition: SKTransition.fadeWithColor(SKColor.blackColor(), duration: 1))
        skView.presentScene(scene)
    }
    
    // Helper method that returns the reference of a creature with the given ID. Theoretically, all creatures should have a unique ID.
    func findCreatureByID(id: Int) -> Creature? {
        for c in allCreatures {
            if c.playerID == id { return c }
        }
        return nil
    }
    
//    func calculateCameraScale(forGivenPlayerRadius playerRadius: CGFloat) -> CGFloat {
//        let theResultingScale = (cameraScaleToPlayerRadiusRatio * playerRadius * prefs.zoomOutFactor).clamped(C.camera_scaleMinimum, 100)
////        let theResultingYScale = (cameraScaleToPlayerRadiusRatios.y * playerRadius * prefs.zoomOutFactor).clamped(C.camera_scaleMinimum, 100)
//        //return CGVector(dx: theResultingXScale, dy: theResultingYScale)
//        return theResultingScale
//    }
    
    func calculateCameraScale(givenPlayerRadius radius: CGFloat, givenMaxPlayerRadiusToScreenWidthRatio maxRatio: CGFloat) -> CGFloat {
        let returnScale: CGFloat
        if radius / self.size.width > maxRatio {
            returnScale = pow(maxRatio, -1) * radius / self.size.width
        } else {
            returnScale = 1
        }
        return returnScale * prefs.zoomOutFactor
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

