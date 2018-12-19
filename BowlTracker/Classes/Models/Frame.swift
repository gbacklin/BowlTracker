//
//  Frame.swift
//  b
//
//  Created by Backlin,Gene on 10/9/18.
//  Copyright © 2018 My Company. All rights reserved.
//

import UIKit

class Frame: NSObject, NSCopying, NSCoding {
    var frameNumber = 0
    var finalScore = 0
    var score = 0
    var ball1Pins = [Int]()
    var ball2Pins = [Int]()
    var isSpare = false
    var isStrike = false
    var isCompleted = false
    var displayScore = false
    var previousFrame: Frame?
    var nextFrame: Frame?
    var tenthFrame = [Frame]()

    override init() {
        super.init()
    }
    
    init(frameNumber: Int, finalScore: Int, ball1Pins: [Int], ball2Pins: [Int], isSpare: Bool, isStrike: Bool, isCompleted: Bool, displayScore: Bool, score: Int, previousFrame: Frame?, nextFrame: Frame?, tenthFrame: [Frame]) {
        self.frameNumber = frameNumber
        self.finalScore = finalScore
        self.ball1Pins = ball1Pins
        self.ball2Pins = ball2Pins
        self.isSpare = isSpare
        self.isStrike = isStrike
        self.isCompleted = isCompleted
        self.displayScore = displayScore
        self.score = score
        self.previousFrame = previousFrame
        self.nextFrame = nextFrame
        self.tenthFrame = tenthFrame
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Frame(frameNumber: frameNumber, finalScore: finalScore, ball1Pins: ball1Pins, ball2Pins: ball2Pins, isSpare: isSpare, isStrike: isStrike, isCompleted: isCompleted, displayScore: displayScore, score: score, previousFrame: previousFrame, nextFrame: nextFrame, tenthFrame: tenthFrame)
        return copy
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(frameNumber, forKey: "frameNumber")
        aCoder.encode(finalScore, forKey: "finalScore")
        aCoder.encode(ball1Pins, forKey: "ball1Pins")
        aCoder.encode(ball2Pins, forKey: "ball2Pins")
        aCoder.encode(score, forKey: "score")
        aCoder.encode(isSpare, forKey: "isSpare")
        aCoder.encode(isStrike, forKey: "isStrike")
        aCoder.encode(isCompleted, forKey: "isCompleted")
        aCoder.encode(displayScore, forKey: "displayScore")
        aCoder.encode(previousFrame, forKey: "previousFrame")
        aCoder.encode(nextFrame, forKey: "nextFrame")
        aCoder.encode(tenthFrame, forKey: "tenthFrame")
    }
    
    required init?(coder aDecoder: NSCoder) {
        frameNumber = Int(aDecoder.decodeInt32(forKey: "frameNumber"))
        finalScore = Int(aDecoder.decodeInt32(forKey: "finalScore"))
        ball1Pins = aDecoder.decodeObject(forKey: "ball1Pins") as! [Int]
        ball2Pins = aDecoder.decodeObject(forKey: "ball2Pins") as! [Int]
        score = Int(aDecoder.decodeInt32(forKey: "score"))
        isSpare = aDecoder.decodeBool(forKey: "isSpare")
        isStrike = aDecoder.decodeBool(forKey: "isStrike")
        isCompleted = aDecoder.decodeBool(forKey: "isCompleted")
        displayScore = aDecoder.decodeBool(forKey: "displayScore")
        previousFrame = aDecoder.decodeObject(forKey: "previousFrame") as? Frame
        nextFrame = aDecoder.decodeObject(forKey: "nextFrame") as? Frame
        tenthFrame = aDecoder.decodeObject(forKey: "tenthFrame") as! [Frame]
    }
    
}
