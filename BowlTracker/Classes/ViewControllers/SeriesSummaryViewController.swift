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
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - Utility
    
    func dateToString(now: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        
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

