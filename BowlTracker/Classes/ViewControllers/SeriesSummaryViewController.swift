//
//  SeriesSummaryViewController.swift
//  BowlTracker
//
//  Created by Gene Backlin on 12/6/18.
//  Copyright © 2018 Gene Backlin. All rights reserved.
//

import UIKit

class SeriesSummaryViewController: UIViewController {
    
    @IBOutlet weak var seriesSummaryLabel: UILabel!
    @IBOutlet weak var series1CollectionView: UICollectionView!
    @IBOutlet weak var series2CollectionView: UICollectionView!
    @IBOutlet weak var series3CollectionView: UICollectionView!
    
    var textTitle: String?
    var series: [[Frame]]?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Series Summary"
        
        seriesSummaryLabel.text = textTitle
    }
}

extension SeriesSummaryViewController: UICollectionViewDataSource {
    func indexTitles(for collectionView: UICollectionView) -> [String]? {
        return ["Game 1", "Game 2", "Game 3"]
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return series!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return series![section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var headerView: CustomCollectionReusableView?
        
        if kind == UICollectionView.elementKindSectionHeader {
            headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderCell", for: indexPath) as? CustomCollectionReusableView
            headerView!.titleLabel.text = "Game \(indexPath.section + 1)"
            collectionView.reloadSections(IndexSet(integer: indexPath.section))
        }
        
        return headerView!
    }

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! FrameCollectionViewCell
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1.0
        
        let currentGame: [Frame] = series![indexPath.section]
        
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

extension SeriesSummaryViewController: UICollectionViewDelegate {

}
