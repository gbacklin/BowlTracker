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
    case open = 1
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
    @IBOutlet weak var helpBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var showSeriesButton: UIButton!
    @IBOutlet weak var tournamentButton: UIButton!
    
    var bowlingPins: [UIButton] = [UIButton]()
    var currentFrame: Frame = Frame()
    var currentFrameTitle = ""
    var currentGame: [Frame] = [Frame]()
    var undoGame: [Frame] = [Frame]()
    var isTenthFrame = false
    var series: [[Frame]] = [[Frame]]()
    var isGameCompleted = false
    var textTitle: String?
    var seriesHistory: NSDictionary?
    var maxGames = 3
    var seriesSummaryTitle = ""

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let appDefaults = [String:AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
        let (game, maxGame, frameTitle, frame, currentSeries, frameNum) = readTempSeries(filename: "Temp")
        if game.count > 0 {
            self.tournamentButton.isHidden = true
            currentGame = game
            maxGames = maxGame
            currentFrame = frame
            series = currentSeries
            textTitle = "Game \(series.count + 1) - Frame \(frameNum)"
            initializePinArray(subviews: pinStackView, frameNumber: frame.frameNumber)
            updateScoreDisplay()
        } else {
            if currentSeries.count > 0 {
                self.tournamentButton.isHidden = true
                currentGame = game
                maxGames = maxGame
                textTitle = frameTitle
                currentFrame = frame
                series = currentSeries
                textTitle = "Game \(series.count + 1) - Frame \(frameNum)"
                initializePinArray(subviews: pinStackView, frameNumber: frame.frameNumber)
                updateScoreDisplay()
            } else {
                self.tournamentButton.isHidden = false
                newGame()
                initializePinArray(subviews: pinStackView, frameNumber: 1)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = textTitle
        shouldShowSeriesButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textTitle = title
        title = " "
    }

    // MARK: - @IBAction methods
    @IBAction func setTournamentOrLeague(_ sender: Any) {
        let alertController: UIAlertController = UIAlertController(title: "Mail Action", message: "Enter the number of games in the tournament", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "# Games"
            textField.keyboardType = .decimalPad
        }

        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { [self] alert -> Void in
            if let textField = alertController.textFields?[0] {
                self.tournamentButton.isHidden = true
                if textField.text!.count > 0 {
                    self.maxGames = Int(textField.text!)!
                } else {
                    self.maxGames = 3
                }
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in })

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        alertController.preferredAction = saveAction

        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func addPinsLeft(_ sender: UIButton) {
        tournamentButton.isHidden = true
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
        tournamentButton.isHidden = true
        currentFrame.isStrike = false
        currentFrame.isSpare = false
        processBallThrown(throwType: sender.tag, isFrameReset: false)
    }
    
    @IBAction func promptForGameOption(_ sender: Any) {
        promptForGameOption()
    }
    
    @IBAction func promptForSummaryDisplay(_ sender: Any) {
        promptForSummaryDisplay(showHistory: true)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowInstructions" {
            let controller: InstructionsViewController = segue.destination as! InstructionsViewController
            controller.textTitle = title
        } else if segue.identifier == "ShowSeriesSummary" {
            let controller: SeriesSummaryViewController = segue.destination as! SeriesSummaryViewController
            controller.seriesTextTitle = seriesSummaryTitle
            controller.series = series
            controller.isHistory = false
            controller.maxGames = maxGames
        } else if segue.identifier == "ShowSeriesHistory" {
            let controller: ShowSeriesHistoryTableViewController = segue.destination as! ShowSeriesHistoryTableViewController
            controller.textTitle = "History"
            controller.seriesHistory = seriesHistory
        }
    }

    // MARK: - Ball thrown methods
    
    func processBallThrown(throwType: Int, isFrameReset: Bool) {
        switch throwType {
        case ThrowType.ball1.rawValue:
            if isFrameReset == false {
                ball1Button.isEnabled = false
                ball2Button.isEnabled = true
                spareButton.isEnabled = true
                strikeButton.isEnabled = false
            }
            firstBallThrown(frame: currentFrame)
            for pin in currentFrame.ball1Pins {
                currentFrame.ball2Pins.append(pin)
            }
        case ThrowType.open.rawValue:
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
            let currentTenthFrameNumber = frame.frameNumber + frame.tenthFrame.count
            switch currentTenthFrameNumber {
            case 10:
                if frame.previousFrame!.isStrike {
                    frame.previousFrame!.score += frame.ball1Pins.count - frame.ball2Pins.count
                    frame.score = frame.previousFrame!.score + (10 - frame.ball2Pins.count)
                } else {
                    frame.score = frame.previousFrame!.score + (10 - frame.ball2Pins.count)
                }
                
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
    
    func updateUndoGame() {
        undoGame = [Frame]()
        for tempGame in currentGame {
            undoGame.append(tempGame)
        }
    }
    
    func addNewFrameToGame(frame: Frame) {
        if frame.frameNumber < 10 {
            if frame.frameNumber > 1 {
                let index = currentGame.count - 1
                let previousFrame = currentGame[index]
                frame.previousFrame = previousFrame
                previousFrame.nextFrame = frame
                currentGame[index] = previousFrame
            }
            updateUndoGame()
            currentGame.append(frame)
            currentFrame = Frame()
            currentFrame.frameNumber = frame.frameNumber + 1
            title = "Game \(series.count + 1) - Frame \(currentFrame.frameNumber)"
        } else {
            let subFrame = 10 + frame.tenthFrame.count
            if subFrame < 13 {
                title = "Game \(series.count + 1) - Frame \(subFrame)"
                
                switch subFrame {
                case 10:
                    let tenthFrame: Frame = frame.copy() as! Frame
                    tenthFrame.frameNumber = subFrame
                    
                    frame.tenthFrame.append(tenthFrame)
                    updateUndoGame()
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
        
        saveTempSeries(filename: "Temp", tempGame: currentGame, currentFrame: currentFrame)
        updateScoreDisplay()
    }
    
    func saveTempSeries(filename: String, tempGame: [Frame], currentFrame: Frame) {
        var dict = [String : AnyObject]()
        
        dict["tempGame"] = tempGame as AnyObject
        dict["maxGames"] = maxGames as AnyObject
        dict["title"] = textTitle as AnyObject
        dict["currentFrame"] = currentFrame as AnyObject
        dict["series"] = series as AnyObject
        dict["frameNumber"] = currentFrame.frameNumber as AnyObject

        let result = PropertyList.writePropertyListFromDictionary(filename: filename as NSString, plistDict: dict as NSDictionary)
        if result {
            debugPrint("Saved temp series")
        } else {
            debugPrint("Saved temp series failed")
        }
    }
    
    func readTempSeries(filename: String) -> ([Frame], Int, String, Frame, series: [[Frame]], frameNumber: Int) {
        var dict = [String : AnyObject]()
        var temp: [Frame] = [Frame]()
        var maxGame: Int = 0
        var frameTitle: String = ""
        var frame = Frame()
        var series: [[Frame]] = [[Frame]]()
        var frameNum: Int = 0

        if let history = PropertyList.dictionaryFromPropertyList(filename: filename as NSString) {
            dict = history as! [String : AnyObject]
            temp = dict["tempGame"] as! [Frame]
            maxGame = dict["maxGames"] as! Int
            frameTitle = dict["title"] as! String
            frame = dict["currentFrame"] as! Frame
            series = dict["series"] as! [[Frame]]
            frameNum = dict["frameNumber"] as! Int
        }
        return (temp, maxGame, frameTitle, frame, series, frameNum)
    }
    
    func deleteTempGame(filename: String) {
        let result = PropertyList.delete("Temp")
        if result {
            debugPrint("Saved temp series")
        } else {
            debugPrint("Saved temp series failed")
        }
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
    
    // MARK: - User prompt methods
    
    func promptForGameOption() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if series.count < maxGames {
            let resetFrameAction = UIAlertAction(title: "Reset Last Frame", style: .default) {[weak self] (action) in
                self!.resetCurrentFrame()
            }
            let resetGameAction = UIAlertAction(title: "Reset Current Game", style: .default) {[weak self] (action) in
                self!.restartGame()
            }
            actionSheet.addAction(resetFrameAction)
            actionSheet.addAction(resetGameAction)
        } else {
            let resetSeriesAction = UIAlertAction(title: "Reset Current Series", style: .default) {[weak self] (action) in
                self!.startNewSeries()
            }
            actionSheet.addAction(resetSeriesAction)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func promptForSummaryDisplay(showHistory: Bool) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if series.count > 0 {
            let showSeriesSummary = UIAlertAction(title: "Show Series Summary", style: .default) {[weak self] (action) in
                self!.deleteTempGame(filename: "Temp")
                self!.performSegue(withIdentifier: "ShowSeriesSummary", sender: self!)
            }
            actionSheet.addAction(showSeriesSummary)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(cancelAction)
        
        if showHistory {
            if let history = seriesHistory {
                if history.count > 0 {
                    let showSeriesHistory = UIAlertAction(title: "Show Series History", style: .default) {[weak self] (action) in
                        self!.deleteTempGame(filename: "Temp")
                        self!.performSegue(withIdentifier: "ShowSeriesHistory", sender: self!)
                    }
                    actionSheet.addAction(showSeriesHistory)
                }
            }
        }

        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - Pin Control methods
    
    func initializePinArray(subviews: UIStackView, frameNumber: Int) {
        currentFrame.frameNumber = frameNumber
        for subView in subviews.subviews {
            if let stackView = subView as? UIStackView {
                initializePinArray(subviews: stackView, frameNumber: frameNumber)
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
        title = "Game \(series.count + 1) - Frame \(currentFrame.frameNumber)"
        textTitle = title
        isGameCompleted = false
        resetPins()
        saveTempSeries(filename: "Temp", tempGame: currentGame, currentFrame: currentFrame)
    }
    
    func updateGame(frame: Frame) {
        currentGame.append(frame)
        currentFrame = Frame()
        currentFrame.frameNumber = frame.frameNumber + 1
        title = "Game \(series.count + 1) - Frame \(currentFrame.frameNumber)"
    }
    
    func endGame() {
        let weakSelf = self
        let firstGame: Frame = currentGame[0]
        title = "Final score \(firstGame.finalScore)"
        strikeButton.isEnabled = false
        
        displayAllScores()
        
        if self.series.count < maxGames - 1 {
            let alert = UIAlertController(title: nil, message: "New Game ?", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) {(action) in
                weakSelf.saveTempSeries(filename: "Temp", tempGame: weakSelf.currentGame, currentFrame: weakSelf.currentFrame)
                weakSelf.updateSeriesWith(game: weakSelf.currentGame)
                weakSelf.isTenthFrame = false
                weakSelf.collectionView.reloadData()
                weakSelf.currentGame.removeAll()
                weakSelf.newGame()
            }
            let noAction = UIAlertAction(title: "No", style: .cancel) { (action) in
                weakSelf.resetPins()
                weakSelf.strikeButton.isEnabled = false
                weakSelf.deleteTempGame(filename: "Temp")
            }
            alert.addAction(yesAction)
            alert.addAction(noAction)
            
            self.present(alert, animated: true, completion: nil)
        } else {
            self.updateSeriesWith(game: self.currentGame)
            var seriesScore = ""
            var seriesTotal = 0
            for index in 0...self.series.count-1 {
                let game: [Frame] = self.series[index]
                let score = game[0].finalScore
                seriesScore.append("\(score) ")
                seriesTotal += score
            }
            seriesSummaryTitle = "\(seriesScore) - \(seriesTotal)"
            if self.series.count > 3 {
                title = "\(self.series.count) Games - \(seriesTotal)"
            } else {
                title = "\(seriesScore) - \(seriesTotal)"
            }
            /*
            let game1 = self.series[0]
            let game2 = self.series[1]
            let game3 = self.series[2]
            let game1Score = game1[0].finalScore
            let game2Score = game2[0].finalScore
            let game3Score = game3[0].finalScore
            title = "\(game1Score) \(game2Score) \(game3Score) - (\(game1Score+game2Score+game3Score))"
            */
            deleteTempGame(filename: "Temp")
            promptForSummaryDisplay(showHistory: false)
        }
    }
    
    // MARK: - Series methods
    
    func updateSeriesWith(game: [Frame]) {
        if series.count < maxGames {
            series.append(game)
        }
    }
    
    // MARK: - Resetting methods

    func resetCurrentFrame() {
        currentFrame = Frame()
        
        currentGame = [Frame]()
        currentFrame.frameNumber = currentGame.count + 1
        if undoGame.count > 0 {
            for tempFrame in undoGame {
                if tempFrame.isStrike {
                    processBallThrown(throwType: ThrowType.strike.rawValue, isFrameReset: true)
                } else if tempFrame.isSpare {
                    currentFrame.ball1Pins = tempFrame.ball1Pins
                    processBallThrown(throwType: ThrowType.ball1.rawValue, isFrameReset: true)
                    processBallThrown(throwType: ThrowType.spare.rawValue, isFrameReset: true)
                } else {
                    currentFrame.ball1Pins = tempFrame.ball1Pins
                    processBallThrown(throwType: ThrowType.ball1.rawValue, isFrameReset: true)
                    currentFrame.ball2Pins = tempFrame.ball2Pins
                    processBallThrown(throwType: ThrowType.open.rawValue, isFrameReset: true)
                }
            }
        } else {
            removeAllFramesInGame()
        }
    }
    
    func removeAllFramesInGame() {
        currentFrame = Frame()
        currentGame.removeAll()
        undoGame.removeAll()
        isTenthFrame = false
        isGameCompleted = false
        
        newGame()
        updateScoreDisplay()
    }
    
    func restartGame() {
        let alert = UIAlertController(title: "New Game", message: "Selecting yes, will remove all frames from this game.", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) {[weak self] (action) in
            self!.removeAllFramesInGame()
            self!.maxGames = 3
            self!.seriesSummaryTitle = ""
            self!.tournamentButton.isHidden = false
            self!.deleteTempGame(filename: "Temp")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(yesAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func startNewSeries() {
        let alert = UIAlertController(title: "New Series", message: "Selecting yes, will remove all games from your series.", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) {[weak self] (action) in
            self!.currentFrame = Frame()
            self!.currentGame.removeAll()
            self!.undoGame.removeAll()
            self!.isTenthFrame = false
            self!.series.removeAll()
            self!.isGameCompleted = false
            self!.shouldShowSeriesButton()
            self!.maxGames = self!.maxGames
            self!.seriesSummaryTitle = ""
            self!.tournamentButton.isHidden = false
            self!.saveTempSeries(filename: "Temp", tempGame: self!.currentGame, currentFrame: self!.currentFrame)

            self!.newGame()
            self!.updateScoreDisplay()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {[weak self] (action) in
            self!.shouldShowSeriesButton()
        }
        
        alert.addAction(yesAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)

    }
    
    // MARK: - Utility methods
    
    func isSplit(pins: [Int]) -> Bool {
        let splits = ["7-10", "7-9", "8-10", "5-7", "5-10", "6-7", "5-7-10", "3-7", "2-10", "2-7", "3-10", "2-7-10", "3-7-10", "4-7-10", "6-7-10", "4-6-7-10", "4-5", "5-6", "7-8", "9-10", "4-6-7-8-10", "4-6-7-9-10", "3-4-6-7-10", "2-4-6-7-10", "2-4-6-7-8-10", "3-4-6-7-9-10", "4-10", "2-3", "4-6", "8-9", "6-7", "6-8", "4-9", "2-6", "3-4", "4-7-9", "2-6-8", "2-4-9", "3-6-8", "3-6-7", "3-6-8", "2-4-10", "6-8-10", "3-4-9", "4-6-9", "4-6-9-10", "4-6-7-8", "4-6-8", "3-6-7-10", "2-4-7-10", "3-9-10", "2-7-8", "4-6-10", "4-6-7", "2-8-10", "3-7-9", "2-7-8", "3-9-10", "4-5-7", "5-6-10", "2-5-7-8", "3-5-9-10", "4-7-9-10", "6-7-9-10", "4-7-8-10", "4-6-7-9", "4-6-7-9", "4-6-8-10", "2-5-7", "3-5-10", "2-4-8-10", "3-6-7-9", "2-7-8-10", "3-9-7-10", "7-8-9-10", "7-9-10", "7-8-10"]

        var split = ""
        for pin in pins.sorted() {
            split += "\(pin)-"
        }
        
        if split.last == "-" {
            split = String(split.dropLast())
        }
        
        return splits.contains(split)
    }

    func shouldShowSeriesButton() {
        if let history = PropertyList.dictionaryFromPropertyList(filename: "SeriesHistory") {
            seriesHistory = history
            showSeriesButton.isHidden = false
        } else {
            if series.count > 0 {
                showSeriesButton.isHidden = false
            } else {
                showSeriesButton.isHidden = true
            }
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
                cell.ball3ResultLabel.textColor = UIColor.black
            } else if frame.isSpare {
                cell.ball2ResultLabel.textColor = UIColor.black
                cell.ball1ResultLabel.text = ""
                cell.ball2ResultLabel.text = "\(10 - frame.ball1Pins.count)"
                if isSplit(pins: frame.ball1Pins) {
                    cell.ball2ResultLabel.textColor = UIColor.red
                } else {
                    cell.ball2ResultLabel.textColor = UIColor.black
                }
                cell.ball3ResultLabel.textColor = UIColor.black
                cell.ball3ResultLabel.text = "/"
            } else {
                cell.ball1ResultLabel.text = ""
                cell.ball2ResultLabel.text = "\(10 - frame.ball1Pins.count)"
                if (10 - (10 - (frame.ball1Pins.count - frame.ball2Pins.count))) == 0 {
                    cell.ball3ResultLabel.text = "-"
                    cell.ball3ResultLabel.textColor = UIColor.black
                } else {
                    cell.ball3ResultLabel.text = "\(10 - (10 - (frame.ball1Pins.count - frame.ball2Pins.count)))"
                }
                if isSplit(pins: frame.ball1Pins) {
                    cell.ball2ResultLabel.textColor = UIColor.red
                } else {
                    cell.ball2ResultLabel.textColor = UIColor.black
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
                    if isSplit(pins: subFrame!.ball1Pins) {
                        cell.ball1ResultLabel.textColor = UIColor.red
                    } else {
                        cell.ball1ResultLabel.textColor = UIColor.black
                    }
                    cell.ball2ResultLabel.textColor = UIColor.black
                } else {
                    cell.ball1ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                    if (10 - (10 - (subFrame!.ball1Pins.count - subFrame!.ball2Pins.count))) == 0 {
                        cell.ball2ResultLabel.text = "-"
                        cell.ball2ResultLabel.textColor = UIColor.black
                        if isSplit(pins: subFrame!.ball1Pins) {
                            cell.ball1ResultLabel.textColor = UIColor.red
                        } else {
                            cell.ball1ResultLabel.textColor = UIColor.black
                        }
                        cell.ball2ResultLabel.textColor = UIColor.black
                    } else {
                        cell.ball2ResultLabel.text = "\(10 - (10 - (subFrame!.ball1Pins.count - subFrame!.ball2Pins.count)))"
                        if isSplit(pins: subFrame!.ball1Pins) {
                            cell.ball1ResultLabel.textColor = UIColor.red
                        } else {
                            cell.ball1ResultLabel.textColor = UIColor.black
                        }
                        cell.ball2ResultLabel.textColor = UIColor.black
                    }
                    cell.ball3ResultLabel.text = ""
                }
                break
            case 11:
                if subFrame!.isStrike {
                    cell.ball1ResultLabel.text = "X"
                    cell.ball2ResultLabel.text = "X"
                    cell.ball3ResultLabel.text = ""
                    cell.ball2ResultLabel.textColor = UIColor.black
                } else if subFrame!.isSpare {
                    cell.ball1ResultLabel.text = "X"
                    cell.ball2ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                    if isSplit(pins: subFrame!.ball1Pins) {
                        cell.ball2ResultLabel.textColor = UIColor.red
                    } else {
                        cell.ball2ResultLabel.textColor = UIColor.black
                    }
                    cell.ball3ResultLabel.textColor = UIColor.black
                    cell.ball3ResultLabel.text = "/"
                } else {
                    let previousFrame = subFrame!.previousFrame
                    if previousFrame!.isStrike {
                        cell.ball1ResultLabel.text = "X"
                        cell.ball2ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                        if ((subFrame!.ball1Pins.count) - (subFrame!.ball2Pins.count)) == 0 {
                            cell.ball3ResultLabel.text = "-"
                            cell.ball3ResultLabel.textColor = UIColor.black
                        } else {
                            cell.ball3ResultLabel.text = "\(10 - (10 - (subFrame!.ball1Pins.count - subFrame!.ball2Pins.count)))"
                        }
                        if isSplit(pins: subFrame!.ball1Pins) {
                            cell.ball2ResultLabel.textColor = UIColor.red
                        } else {
                            cell.ball2ResultLabel.textColor = UIColor.black
                        }
                    } else if previousFrame!.isSpare {
                        cell.ball1ResultLabel.text = "\(10 - previousFrame!.ball1Pins.count)"
                        cell.ball2ResultLabel.text = "/"
                        cell.ball3ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                        cell.ball2ResultLabel.textColor = UIColor.black
                        if isSplit(pins: previousFrame!.ball1Pins) {
                            cell.ball1ResultLabel.textColor = UIColor.red
                        } else {
                            cell.ball1ResultLabel.textColor = UIColor.black
                        }
                        if isSplit(pins: subFrame!.ball1Pins) {
                            cell.ball3ResultLabel.textColor = UIColor.red
                        } else {
                            cell.ball3ResultLabel.textColor = UIColor.black
                        }
                    } else {
                        cell.ball2ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                        if (10 - (10 - (subFrame!.ball1Pins.count - subFrame!.ball2Pins.count))) == 0 {
                            cell.ball3ResultLabel.text = "-"
                            cell.ball3ResultLabel.textColor = UIColor.black
                            if isSplit(pins: subFrame!.ball1Pins) {
                                cell.ball2ResultLabel.textColor = UIColor.red
                            } else {
                                cell.ball2ResultLabel.textColor = UIColor.black
                            }
                        } else {
                            cell.ball3ResultLabel.text = "\(10 - (10 - (subFrame!.ball1Pins.count - subFrame!.ball2Pins.count)))"
                            if isSplit(pins: subFrame!.ball1Pins) {
                                cell.ball2ResultLabel.textColor = UIColor.red
                            } else {
                                cell.ball2ResultLabel.textColor = UIColor.black
                            }
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
                        cell.ball2ResultLabel.textColor = UIColor.black
                    } else {
                        cell.ball1ResultLabel.text = "\(10 - subFrame!.previousFrame!.ball1Pins.count)"
                        cell.ball2ResultLabel.text = "/"
                        cell.ball3ResultLabel.text = "X"
                        if isSplit(pins: subFrame!.previousFrame!.ball1Pins) {
                            cell.ball1ResultLabel.textColor = UIColor.red
                        } else {
                            cell.ball1ResultLabel.textColor = UIColor.black
                        }
                    }
                } else if subFrame!.isSpare {
                    cell.ball1ResultLabel.text = "X"
                    cell.ball2ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                    if isSplit(pins: subFrame!.ball1Pins) {
                        cell.ball2ResultLabel.textColor = UIColor.red
                    } else {
                        cell.ball2ResultLabel.textColor = UIColor.black
                    }
                    cell.ball3ResultLabel.textColor = UIColor.black
                    cell.ball3ResultLabel.text = "/"
                } else {
                    cell.ball1ResultLabel.text = "X"
                    cell.ball2ResultLabel.text = "X"
                    cell.ball3ResultLabel.text = "\(10 - subFrame!.ball1Pins.count)"
                    cell.ball2ResultLabel.textColor = UIColor.black
                    if isSplit(pins: subFrame!.ball1Pins) {
                        cell.ball3ResultLabel.textColor = UIColor.red
                    } else {
                        cell.ball3ResultLabel.textColor = UIColor.black
                    }
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
