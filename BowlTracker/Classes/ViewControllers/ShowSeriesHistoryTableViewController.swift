//
//  ShowSeriesHistoryTableViewController.swift
//  BowlTracker
//
//  Created by Gene Backlin on 12/18/18.
//  Copyright © 2018 Gene Backlin. All rights reserved.
//

import UIKit

class ShowSeriesHistoryTableViewController: UITableViewController {
    var seriesHistory: NSDictionary?
    var textTitle: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundView = UIImageView(image: UIImage(named: "lane")?.stretchableImage(withLeftCapWidth: 0, topCapHeight: 5))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = textTitle
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textTitle = title
        title = " "
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return seriesHistory!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keys: [String] = (seriesHistory!.allKeys as! [String]).sorted()
        let key = keys[indexPath.row]
        let subtitle = seriesScore(for: key, series: seriesHistory!)

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        

        // Configure the cell...
        cell.textLabel?.text = key
        cell.detailTextLabel?.text = subtitle

        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSeriesHistorySummary" {
            let indexPath = tableView.indexPathForSelectedRow
            let keys: [String] = (seriesHistory!.allKeys as! [String]).sorted()
            let key = keys[indexPath!.row]
            let series: [[Frame]] = seriesHistory!.object(forKey: key) as! [[Frame]]
            let cell = tableView.cellForRow(at: indexPath!)
            let controller: SeriesSummaryViewController = segue.destination as! SeriesSummaryViewController
            controller.textTitle = cell!.detailTextLabel?.text
            controller.series = series
            controller.isHistory = true
       }
    }

    // MARK: - Utility
    
    func seriesScore(for key: String, series: NSDictionary) -> String? {
        let series: [[Frame]] = series.object(forKey: key) as! [[Frame]]
        var seriesScore = 0
        var frameScores = ""
        for game: [Frame] in series {
            let frame: Frame = game[0]
            frameScores += "\(frame.finalScore) "
            seriesScore += frame.finalScore
        }
        
        return "\(frameScores) - (\(seriesScore))"
    }
    

}
