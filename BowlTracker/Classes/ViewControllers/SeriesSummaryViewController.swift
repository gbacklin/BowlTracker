//
//  SeriesSummaryViewController.swift
//  BowlTracker
//
//  Created by Gene Backlin on 12/6/18.
//  Copyright © 2018 Gene Backlin. All rights reserved.
//

import UIKit
import MessageUI

class SeriesSummaryViewController: UIViewController {
    
    @IBOutlet weak var seriesSummaryLabel: UILabel!
    @IBOutlet weak var series1CollectionView: UICollectionView!
    @IBOutlet weak var series2CollectionView: UICollectionView!
    @IBOutlet weak var series3CollectionView: UICollectionView!
    
    var textTitle: String?
    var series: [[Frame]]?
    var isHistory: Bool?

    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        seriesSummaryLabel.text = textTitle
        
        let sendButton = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(SeriesSummaryViewController.send(_:)))
        navigationItem.rightBarButtonItem = sendButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Series Summary"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textTitle = title
        title = " "
    }

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DisplayPDF" {
//            let controller: PDFViewerViewController = segue.destination as! PDFViewerViewController
//            let pdfData = PDFConverter.convertView(view: view)
//            controller.pdfData = pdfData
        }
    }

    // MARK: - User prompt methods
    
    func promptForSendOption() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let sendAsEmailAction = UIAlertAction(title: "Send as Email", style: .default) {[weak self] (action) in
            self!.sendImageInMail(image: self!.view.screenShot())
        }
        let sendAsSMSAction = UIAlertAction(title: "Send as SMS", style: .default) {[weak self] (action) in
            self!.sendImageInSMS(image: self!.view.screenShot())
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(sendAsEmailAction)
        actionSheet.addAction(sendAsSMSAction)
        actionSheet.addAction(cancelAction)
        
        if isHistory == false {
            let saveSeriesAction = UIAlertAction(title: "Save Series", style: .default) {[weak self] (action) in
                self!.saveSeries(filename: "SeriesHistory")
            }
            actionSheet.addAction(saveSeriesAction)
        }

        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - Utility
    
    func dateToString(now: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy hh:mm a"
        
        return dateFormatter.string(from: now)
    }

    func dateToKey(now: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-hh:mm a"
        
        return dateFormatter.string(from: now)
    }

    func displayAction(message: String) {
        let alertController: UIAlertController = UIAlertController(title: "Mail Action", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Mail/SMS methods
    
    func sendImageInMail(image: UIImage) {
        if (MFMailComposeViewController.canSendMail()) {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setSubject("Series as of \(dateToString(now: Date()))")
            mailComposer.setMessageBody("My latest series as of \(dateToString(now: Date()))", isHTML: false)
            mailComposer.addAttachmentData(image.pngData()!, mimeType: "image/png", fileName: "image.png")

            present(mailComposer, animated: true, completion: nil)
        } else {
            displayAction(message: "Cannot send email.")
        }
    }
    
    func sendImageInSMS(image: UIImage) {
        if (MFMessageComposeViewController.canSendAttachments()) {
            let controller = MFMessageComposeViewController()
            controller.messageComposeDelegate = self
            
            controller.body = "My latest series as of \(dateToString(now: Date()))"
            controller.addAttachmentData(image.pngData()!, typeIdentifier: "image/png", filename: "image.png")
            
            present(controller, animated: true, completion: nil)
        } else {
            displayAction(message: "Cannot send SMS.")
        }
    }
    
    func saveSeries(filename: String) {
        var dict = [String : [[Frame]]]()
        let key = dateToKey(now: Date())
        var message: String?
        
        if let history = PropertyList.dictionaryFromPropertyList(filename: "SeriesHistory") {
            dict = history as! [String : [[Frame]]]
        }
        dict[key] = series!
        
        let result = PropertyList.writePropertyListFromDictionary(filename: filename as NSString, plistDict: dict as NSDictionary)
        if result {
            message = "Series was saved"
        } else {
            message = "Series was not saved"
        }
        let alertController: UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)

    }

    // MARK: - Utility methods
    
    func isSplit(pins: [Int]) -> Bool {
        let splits = ["7-10", "7-9", "8-10", "5-7", "5-10", "6-7", "5-7-10", "3-7", "2-10", "2-7", "3-10", "2-7-10", "3-7-10", "4-7-10", "6-7-10", "4-6-7-10", "4-5", "5-6", "7-8", "9-10", "4-6-7-8-10", "4-6-7-9-10", "3-4-6-7-10", "2-4-6-7-10", "2-4-6-7-8-10", "3-4-6-7-9-10", "4-10", "2-3", "4-6", "8-9", "6-7", "6-8", "4-9", "2-6", "3-4", "4-7-9", "2-6-8", "2-4-9", "3-6-8", "3-6-7", "3-6-8", "2-4-10", "6-8-10", "3-4-9", "4-6-9", "4-6-9-10", "4-6-7-8", "4-6-8", "3-6-7-10", "2-4-7-10", "3-9-10", "2-7-8", "3-5-9", "2-5-8"]
        var split = ""
        for pin in pins.sorted() {
            split += "\(pin)-"
        }
        
        if split.last == "-" {
            split = String(split.dropLast())
        }
        
        return splits.contains(split)
    }

}

// MARK: - Selector methods

extension SeriesSummaryViewController {
    @objc func send(_ sender: AnyObject) {
        promptForSendOption()
    }
}

// MARK: - UICollectionViewDataSource

extension SeriesSummaryViewController: UICollectionViewDataSource {
    func indexTitles(for collectionView: UICollectionView) -> [String]? {
        return ["Game 1", "Game 2", "Game 3"]
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        var count = series!.count
        if count > 3 {
            count = 3
        }
        return count
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
                cell.ball3ResultLabel.textColor = UIColor.black
            } else if frame.isSpare {
                cell.ball1ResultLabel.text = ""
                cell.ball2ResultLabel.text = "\(10 - frame.ball1Pins.count)"
                if isSplit(pins: frame.ball1Pins) {
                    cell.ball2ResultLabel.textColor = UIColor.red
                } else {
                    cell.ball2ResultLabel.textColor = UIColor.black
                }
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
                        cell.ball2ResultLabel.textColor = UIColor.black
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
                    cell.ball3ResultLabel.text = "/"
                    cell.ball3ResultLabel.textColor = UIColor.black
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

// MARK: - UICollectionViewDelegate

extension SeriesSummaryViewController: UICollectionViewDelegate {

}

// MARK: - UIView utility

extension UIView {
    func screenShot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, UIScreen.main.scale)
        let contextRef = UIGraphicsGetCurrentContext()
        contextRef!.translateBy(x: -1.0, y: -1.0)
        layer.render(in: contextRef!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension SeriesSummaryViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            print("Email cancelled")
        case .saved:
            print("Email saved")
        case .sent:
            print("Email sent")
        case .failed:
            print("Email failed")
        default:
            print("default")
        }
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - MFMessageComposeViewControllerDelegate

extension SeriesSummaryViewController: MFMessageComposeViewControllerDelegate {
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled:
            print("SMS cancelled")
        case .sent:
            print("SMS sent")
        case .failed:
            print("SMS failed")
        default:
            print("default")
        }
        dismiss(animated: true, completion: nil)
    }
    
}

