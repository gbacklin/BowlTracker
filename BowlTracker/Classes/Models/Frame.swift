//
//  Frame.swift
//  b
//
//  Created by Backlin,Gene on 10/9/18.
//  Copyright © 2018 My Company. All rights reserved.
//

import UIKit

class Frame: NSObject, NSCopying, Codable {
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
    

}
