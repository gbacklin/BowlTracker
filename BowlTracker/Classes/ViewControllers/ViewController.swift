//
//  ViewController.swift
//  BowlTracker
//
//  Created by Gene Backlin on 10/26/18.
//  Copyright © 2018 Gene Backlin. All rights reserved.
//

import UIKit

enum ThrowType: Int {
    case ball1 = 0
    case ball2 = 1
    case spare = 2
    case strike = 3
}

class ViewController: UIViewController {
    @IBOutlet weak var pinStackView: UIStackView!
    @IBOutlet weak var ball1Button: UIButton!
    @IBOutlet weak var ball2Button: UIButton!
    @IBOutlet weak var spareButton: UIButton!
    @IBOutlet weak var strikeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var bowlingPins: [UIButton] = [UIButton]()
    var currentFrame: Frame = Frame()
    var currentGame: [Frame] = [Frame]()
    var isTenthFrame = false
    var series: [[Frame]] = [[Frame]]()
    var isGameCompleted = false
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initializePinArray(subviews: pinStackView)
        
        newGame()
    }
    
    // MARK: - @IBAction methods
    
    @IBAction func addPinsLeft(_ sender: UIButton) {
        if ball1Button.isEnabled == false && ball2Button.isEnabled == false {
            ball1Button.isEnabled = true
            strikeButton.isEnabled = false
        }
        
        let currentColor = sender.titleColor(for: .normal)
        if currentColor == UIColor.red {
            sender.setTitleColor(.blue, for: .normal)
            if ball2Button.isEnabled == false {
                strikeButton.isEnabled = false
                currentFrame.ball1Pins.append(sender.tag)
            } else {
                currentFrame.ball2Pins.append(sender.tag)
            }
        } else {
            sender.setTitleColor(.red, for: .normal)
            if ball2Button.isEnabled == false {
                strikeButton.isEnabled = true
                for index in 0...currentFrame.ball1Pins.count - 1 {
                    let pin: Int = currentFrame.ball1Pins[index]
                    if pin == sender.tag {
                        currentFrame.ball1Pins.remove(at: index)
                        break
                    }
                }
            } else {
                for index in 0...currentFrame.ball2Pins.count - 1 {
                    let pin: Int = currentFrame.ball2Pins[index]
                    if pin == sender.tag {
                        currentFrame.ball2Pins.remove(at: index)
                        break
                    }
                }
            }
        }
    }
    
    @IBAction func ballThrown(_ sender: UIButton) {
        currentFrame.isStrike = false
        currentFrame.isSpare = false

        switch sender.tag {
        case ThrowType.ball1.rawValue:
            ball1Button.isEnabled = false
            ball2Button.isEnabled = true
            spareButton.isEnabled = true
            strikeButton.isEnabled = false
            firstBallThrown(frame: currentFrame)
            for pin in currentFrame.ball1Pins {
                currentFrame.ball2Pins.append(pin)
            }
        case ThrowType.ball2.rawValue:
            openFrame(frame: currentFrame)
        case ThrowType.spare.rawValue:
            currentFrame.isStrike = false
            currentFrame.isSpare = true
            currentFrame.ball2Pins.removeAll()
            spare(frame: currentFrame)
        case ThrowType.strike.rawValue:
            currentFrame.isStrike = true
            currentFrame.isSpare = false
            currentFrame.ball1Pins.removeAll()
            currentFrame.ball2Pins.removeAll()
            strike(frame: currentFrame)
        default:
            print("unknown")
        }
    }
    
    @IBAction func startNewSeries(_ sender: UIBarButtonItem) {
        currentFrame = Frame()
        currentGame.removeAll()
        isTenthFrame = false
        series.removeAll()
        isGameCompleted = false
        
        newGame()
        updateScoreDisplay()
    }
    // MARK: - Ball thrown methods
    
    
    func firstBallThrown(frame: Frame) {
        if frame.frameNumber == 1 {
            frame.score = (10 - frame.ball1Pins.count)
        } else if frame.frameNumber < 10 {
            let previousFrame = currentGame[currentGame.count - 1]
            
            updateScoreWithFirstBallThrown(frame: frame, previousFrame: previousFrame)
        } else {
            let frameNumber = frame.tenthFrame.count + 10
            switch frameNumber {
            case 10:
                let previousFrame = currentGame[8]
                updateScoreWithFirstBallThrown(frame: frame, previousFrame: previousFrame)
                break
                
            case 11:
                let previousFrame = currentGame[9].tenthFrame[0]
                updateScoreWithFirstBallThrown(frame: frame, previousFrame: previousFrame)
                if previousFrame.isStrike == false {
                    if frame.isStrike {
                        if previousFrame.isSpare {
                            addNewFrameToGame(frame: frame)
                        }
                    } else if isOpen(frame: frame) {
                        addNewFrameToGame(frame: frame)
                    }
                }
                break
                
            case 12:
                let previousFrame = currentGame[9].tenthFrame[1]
                updateScoreWithFirstBallThrown(frame: frame, previousFrame: previousFrame)
                addNewFrameToGame(frame: frame)
                break
                
            default:
                break
            }
        }
    }
    
    func strike(frame: Frame) {
        frame.isStrike = true
        firstBallThrown(frame: frame)
        addNewFrameToGame(frame: frame)
    }
    
    func spare(frame: Frame) {
        frame.isSpare = true
        displayAllScores()

        if frame.frameNumber == 1 {
            frame.score = (10 - frame.ball2Pins.count)
           addNewFrameToGame(frame: frame)
        } else if frame.frameNumber < 10 {
            let index = currentGame.count - 1
            let previousFrame = currentGame[index]

            if previousFrame.isStrike {
                previousFrame.score += frame.ball1Pins.count
                frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                previousFrame.displayScore = true
                addNewFrameToGame(frame: frame)
            } else if previousFrame.isSpare {
                frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                previousFrame.displayScore = true
                addNewFrameToGame(frame: frame)
            } else {
                frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                previousFrame.displayScore = true
                addNewFrameToGame(frame: frame)
            }
        } else {
            let subFrameNumber = frame.tenthFrame.count + 10

            switch subFrameNumber {
            case 10:
                let index = currentGame.count - 1
                let previousFrame = currentGame[index]
                
                if previousFrame.isStrike {
                    previousFrame.score += frame.ball1Pins.count
                    frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                    previousFrame.displayScore = true
                    addNewFrameToGame(frame: frame)
                } else if previousFrame.isSpare {
                    frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                    previousFrame.displayScore = true
                    addNewFrameToGame(frame: frame)
                } else {
                    frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                    previousFrame.displayScore = true
                    addNewFrameToGame(frame: frame)
                }
                break
                
            case 11:
                let eleventhFrame: Frame = frame.copy() as! Frame
                
                eleventhFrame.frameNumber = subFrameNumber
                eleventhFrame.previousFrame = frame.tenthFrame[frame.tenthFrame.count - 1]

                let previousFrame = frame.tenthFrame[frame.tenthFrame.count - 1]
                
                if previousFrame.isStrike {
                    frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                    previousFrame.displayScore = true
                } else if previousFrame.isSpare {
                    frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                    previousFrame.displayScore = true
                } else {
                    frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                    previousFrame.displayScore = true
                    isGameCompleted = true
                }

                eleventhFrame.previousFrame!.nextFrame = eleventhFrame
                
                frame.tenthFrame.append(eleventhFrame)
                
                currentGame[9] = frame
                addNewFrameToGame(frame: frame)

                break
                
            case 12:
                let twelfthFrame: Frame = frame.copy() as! Frame
                
                twelfthFrame.frameNumber = subFrameNumber
                twelfthFrame.previousFrame = frame.tenthFrame[frame.tenthFrame.count - 1]
                
                let previousFrame = frame.tenthFrame[frame.tenthFrame.count - 1]
                
                if previousFrame.isStrike {
                    previousFrame.score += frame.ball1Pins.count
                    frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                    previousFrame.displayScore = true
                } else if previousFrame.isSpare {
                    frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                    previousFrame.displayScore = true
                } else {
                    frame.score = previousFrame.score + (10 - frame.ball2Pins.count)
                    previousFrame.displayScore = true
                }
                
                twelfthFrame.previousFrame!.nextFrame = twelfthFrame
                
                frame.tenthFrame.append(twelfthFrame)
                //frame.tenthFrame[frame.tenthFrame.count - 1] = eleventhFrame
                
                frame.score = twelfthFrame.score

                currentGame[9] = frame
                currentGame[0].finalScore = currentGame[9].score
                isGameCompleted = true
               break

            default:
                break
            }
        }
    }
    
    func openFrame(frame: Frame) {
        frame.displayScore = true
        
        if frame.frameNumber == 1 {
            frame.score = (10 - frame.ball2Pins.count)
            addNewFrameToGame(frame: frame)
        } else if frame.frameNumber < 10 {
            if frame.previousFrame!.isStrike {
                frame.previousFrame!.score += frame.ball1Pins.count - frame.ball2Pins.count
                frame.score += (frame.ball1Pins.count - frame.ball2Pins.count) * 2
            } else {
                frame.score += frame.ball1Pins.count - frame.ball2Pins.count
            }
            addNewFrameToGame(frame: frame)
            displayAllScores()
        } else {
            switch frame.frameNumber {
            case 10:
                frame.score += frame.ball1Pins.count - frame.ball2Pins.count
                
                let firstFrame = currentGame[0]
                firstFrame.finalScore = frame.score
                currentGame[0] = firstFrame
                
                addNewFrameToGame(frame: frame)
                endGame()
                break
                
            case 11:
                frame.score += frame.ball1Pins.count - frame.ball2Pins.count
                
                addNewFrameToGame(frame: frame)
                let firstFrame = currentGame[0]
                firstFrame.finalScore = frame.score
                currentGame[0] = firstFrame
                endGame()
                break
                
            case 12:
                break
                
            default:
                break
            }
        }
    }

    // MARK: - Frame query methods
    
    func isOpen(frame: Frame) -> Bool {
        return frame.isStrike == false && frame.isSpare == false
    }

    // MARK: - Update score methods
    
    func updateScoreWithFirstBallThrown(frame: Frame, previousFrame: Frame) {
        frame.previousFrame = previousFrame
        previousFrame.nextFrame = frame

        frame.score = (10 - frame.ball1Pins.count)
        
        if previousFrame.isStrike {
            if let twoPreviousFrame = previousFrame.previousFrame {
                if twoPreviousFrame.isStrike {
                    if frame.frameNumber < 10 {
                        twoPreviousFrame.score += (10 - frame.ball1Pins.count)
                        previousFrame.score += (10 - frame.ball1Pins.count) * 2
                        frame.score += previousFrame.score
                    } else {
                        let frameNumber = frame.tenthFrame.count + 10
                        switch frameNumber {
                        case 10:
                            twoPreviousFrame.score += (10 - frame.ball1Pins.count)
                            previousFrame.score += (10 - frame.ball1Pins.count) * 2
                            frame.score += previousFrame.score
                            break
                            
                        case 11:
                            twoPreviousFrame.score += (10 - frame.ball1Pins.count)
                            previousFrame.score += (10 - frame.ball1Pins.count)
                            frame.score += previousFrame.score
                            break
                            
                        case 12:
                            frame.score = previousFrame.score + (10 - frame.ball1Pins.count)
                            break
                            
                        default:
                            break
                        }
                    }
                } else {
                    if frame.frameNumber < 10 {
                        previousFrame.score += (10 - frame.ball1Pins.count)
                        frame.score += previousFrame.score
                    } else {
                        let frameNumber = frame.tenthFrame.count + 10
                        switch frameNumber {
                        case 10:
                            previousFrame.score += (10 - frame.ball1Pins.count)
                            frame.score += previousFrame.score
                            break
                            
                        case 11:
                            frame.score += previousFrame.score
                            break
                            
                        case 12:
                            break
                            
                        default:
                            break
                        }
                    }
                }
            } else {
                previousFrame.score += (10 - frame.ball1Pins.count)
                frame.score += previousFrame.score
            }
        } else if previousFrame.isSpare {
            if frame.frameNumber < 10 {
                previousFrame.score += (10 - frame.ball1Pins.count)
                frame.score += previousFrame.score
                previousFrame.displayScore = true
            } else {
                let frameNumber = frame.tenthFrame.count + 10
                switch frameNumber {
                case 10:
                    previousFrame.score += (10 - frame.ball1Pins.count)
                    frame.score += previousFrame.score
                    previousFrame.displayScore = true
                    break
                    
                case 11:
                    frame.score += previousFrame.score
                    previousFrame.displayScore = true
                    break
                    
                case 12:
                    frame.score = previousFrame.score + (10 - frame.ball1Pins.count)
                    break
                    
                default:
                    break
                }
            }
        } else {
            frame.score += previousFrame.score
        }
    }
    
    // MARK: - Frame Control methods
    
    func addNewFrameToGame(frame: Frame) {
        if frame.frameNumber < 10 {
            if frame.frameNumber > 1 {
                let index = currentGame.count - 1
                let previousFrame = currentGame[index]
                frame.previousFrame = previousFrame
                previousFrame.nextFrame = frame
                currentGame[index] = previousFrame
            }
            currentGame.append(frame)
            currentFrame = Frame()
            currentFrame.frameNumber = frame.frameNumber + 1
            title = "Frame \(currentFrame.frameNumber)"
        } else {
            let subFrame = 10 + frame.tenthFrame.count
            if subFrame < 13 {
                title = "Frame \(subFrame)"
                
                switch subFrame {
                case 10:
                    let tenthFrame: Frame = frame.copy() as! Frame
                    tenthFrame.frameNumber = subFrame
                    
                    frame.tenthFrame.append(tenthFrame)
                    currentGame.append(frame)
                    break
                    
                case 11:
                    let eleventhFrame: Frame = frame.copy() as! Frame
                    eleventhFrame.frameNumber = subFrame
                    frame.tenthFrame.append(eleventhFrame)
                    if isOpen(frame: frame) {
                        frame.finalScore = frame.score
                        currentGame[9] = frame
                        
                        let firstFrame = currentGame[0]
                        firstFrame.finalScore = frame.score
                        currentGame[0] = firstFrame
                        
                        isGameCompleted = true
                        endGame()
                    } else if frame.previousFrame!.isSpare {
                        currentGame[9] = frame
                    } else {
                        currentGame[9] = frame
                    }
                    break
                    
                case 12:
                    let twelvethFrame: Frame = frame.copy() as! Frame
                    twelvethFrame.frameNumber = subFrame
                    frame.tenthFrame.append(twelvethFrame)
                    frame.finalScore = frame.score
                    currentGame[9] = frame
                    
                    let firstFrame = currentGame[0]
                    firstFrame.finalScore = frame.score
                    currentGame[0] = firstFrame
                    
                    isGameCompleted = true
                    endGame()
                    break
                    
                default:
                    break
                }
            }
        }
        
        updateScoreDisplay()
    }
    
    // MARK: - Display methods
    
    func updateScoreDisplay() {
        collectionView.reloadData()
        resetPins()
    }
    
    func displayAllScores() {
        for frame in currentGame {
            frame.displayScore = true
            if frame.frameNumber == 10 {
                for tenthFrame in frame.tenthFrame {
                    tenthFrame.displayScore = true
                }
            }
        }
    }
    
    // MARK: - Pin Control methods
    
    func initializePinArray(subviews: UIStackView) {
        currentFrame.frameNumber = 1
        for subView in subviews.subviews {
            if let stackView = subView as? UIStackView {
                initializePinArray(subviews: stackView)
            } else if let button = subView as? UIButton {
                let image = UIImage(named: "gray")
                button.setBackgroundImage(image, for: .normal)
                bowlingPins.append(button)
            } else {
                print("Unknown object: \(subView)")
            }
        }
    }
    
    func resetPins() {
        ball1Button.isEnabled = false
        ball2Button.isEnabled = false
        spareButton.isEnabled = false
        strikeButton.isEnabled = true
        
        currentFrame.ball1Pins.removeAll()

        for bowlingPin in bowlingPins {
            bowlingPin.setTitleColor(.red, for: .normal)
        }
        
        if currentGame.count > 0 {
            collectionView.scrollToItem(at: IndexPath(row: currentGame.count-1, section: 0), at: .right, animated: true)
        }
    }

    // MARK: - Game Control methods

    func newGame() {
        currentFrame = Frame()
        currentFrame.frameNumber = 1
        title = "Frame \(currentFrame.frameNumber)"
        isGameCompleted = false
        resetPins()
    }
    
    func updateGame(frame: Frame) {
        currentGame.append(frame)
        currentFrame = Frame()
        currentFrame.frameNumber = frame.frameNumber + 1
        title = "Frame \(currentFrame.frameNumber)"
    }
    
    func endGame() {
        let firstGame: Frame = currentGame[0]
        title = "Final score \(firstGame.finalScore)"
        strikeButton.isEnabled = false
        
        displayAllScores()
        self.series.append(currentGame)
        
        if self.series.count < 3 {
            let weakSelf = self
            let alert = UIAlertController(title: nil, message: "New Game ?", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) {(action) in
                weakSelf.isTenthFrame = false
                weakSelf.collectionView.reloadData()
                weakSelf.currentGame.removeAll()
                weakSelf.newGame()
            }
            let noAction = UIAlertAction(title: "No", style: .cancel) { (action) in
                weakSelf.resetPins()
                weakSelf.strikeButton.isEnabled = false
            }
            alert.addAction(yesAction)
            alert.addAction(noAction)
            
            self.present(alert, animated: true, completion: nil)
        } else {
            let game1 = self.series[0]
            let game2 = self.series[1]
            let game3 = self.series[2]
            let game1Score = game1[0].finalScore
            let game2Score = game2[0].finalScore
            let game3Score = game3[0].finalScore
            title = "\(game1Score) \(game2Score) \(game3Score) series (\(game1Score+game2Score+game3Score))"
        }
    }

}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentGame.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! FrameCollectionViewCell
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1.0
        
        let frame = currentGame[indexPath.row]
        
        cell.frameNumberLabel.text = "\(frame.frameNumber)"
        if frame.displayScore {
            cell.frameScoreLabel.text = "\(frame.score)"
        }
        if frame.frameNumber < 10 {
            if frame.isStrike {
                cell.ball1ResultLabel.text = ""
                cell.ball2ResultLabel.text = ""
                cell.ball3ResultLabel.text = "X"
            } else if frame.isSpare {
                cell.ball1ResultLabel.text = ""
                cell.ball2ResultLabel.text = "\(10 - frame.ball1Pins.count)"
                cell.ball3ResultLabel.text = "/"
            } else {
                cell.ball1ResultLabel.text = ""
                cell.ball2ResultLabel.text = "\(10 - frame.ball1Pins.count)"
                if (10 - (10 - (frame.ball1Pins.count - frame.ball2Pins.count))) == 0 {
                    cell.ball3ResultLabel.text = "-"
                } else {
                    cell.ball3ResultLabel.text = "\(10 - (10 - (frame.ball1Pins.count - frame.ball2Pins.count)))"
                }
            }
        } else {
            let tenthFrame = currentGame[9]
            let subFrame = tenthFrame.tenthFrame.last
            let frameNumber = tenthFrame.tenthFrame.count + 9
            switch frameNumber {
            case 10:
                if subFrame!.isStrike {
                    cell.ball1ResultLabel.text = "X"
                    cell.ball2ResultLabel.text = ""
                    cell.ball3ResultLabel.text = ""
                } else if subFrame!.isSpare {
                    cell.ball1ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                    cell.ball2ResultLabel.text = "/"
                    cell.ball3ResultLabel.text = ""
                } else {
                    cell.ball1ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                    if (10 - (10 - (subFrame!.ball1Pins.count - subFrame!.ball2Pins.count))) == 0 {
                        cell.ball2ResultLabel.text = "-"
                    } else {
                        cell.ball2ResultLabel.text = "\(10 - (10 - (subFrame!.ball1Pins.count - subFrame!.ball2Pins.count)))"
                    }
                    cell.ball3ResultLabel.text = ""
                }
//                currentFrame.ball1Pins.removeAll()
//                currentFrame.ball2Pins.removeAll() // GAB
                break
            case 11:
                if subFrame!.isStrike {
                    cell.ball1ResultLabel.text = "X"
                    cell.ball2ResultLabel.text = "X"
                    cell.ball3ResultLabel.text = ""
                } else if subFrame!.isSpare {
                    cell.ball1ResultLabel.text = "X"
                    cell.ball2ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                    cell.ball3ResultLabel.text = "/"
                } else {
                    let previousFrame = subFrame!.previousFrame
                    if previousFrame!.isSpare {
                        cell.ball1ResultLabel.text = "\(10 - previousFrame!.ball1Pins.count)"
                        cell.ball2ResultLabel.text = "/"
                        cell.ball3ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                    } else {
                        cell.ball2ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                        if (10 - (10 - (subFrame!.ball1Pins.count - subFrame!.ball2Pins.count))) == 0 {
                            cell.ball3ResultLabel.text = "-"
                        } else {
                            cell.ball3ResultLabel.text = "\(10 - (10 - (subFrame!.ball1Pins.count - subFrame!.ball2Pins.count)))"
                        }
                    }
                }
                break
            case 12:
                if subFrame!.isStrike {
                    if subFrame!.previousFrame!.isStrike {
                        cell.ball1ResultLabel.text = "X"
                        cell.ball2ResultLabel.text = "X"
                        cell.ball3ResultLabel.text = "X"
                    } else {
                        cell.ball1ResultLabel.text = "\(10 - subFrame!.previousFrame!.ball1Pins.count)"
                        cell.ball2ResultLabel.text = "/"
                        cell.ball3ResultLabel.text = "X"
                    }
                } else if subFrame!.isSpare {
                    cell.ball1ResultLabel.text = "X"
                    cell.ball2ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                    cell.ball3ResultLabel.text = "/"
                } else {
                    cell.ball1ResultLabel.text = "X"
                    cell.ball2ResultLabel.text = "X"
                    cell.ball3ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                }
                break
            default:
                break
            }
        }
        
        if frame.displayScore {
            cell.frameScoreLabel.text = "\(frame.score)"
        } else {
            cell.frameScoreLabel.text = ""
        }
        
        return cell
    }
    
}

extension ViewController: UICollectionViewDelegate {
    
}

