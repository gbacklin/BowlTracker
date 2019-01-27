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
    var seriesGroupHistory = NSMutableDictionary()
    var seriesGroupTimeStampHistory = NSMutableDictionary()
    var textTitle: String?
    let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundView = UIImageView(image: UIImage(named: "lane")?.stretchableImage(withLeftCapWidth: 0, topCapHeight: 5))
        groupSeriesHistory()
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
        return seriesGroupHistory.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let keys: [String] = ((seriesGroupHistory.allKeys as! [String]).sorted()).reversed()
        let key = keys[section]
        let seriesArray: NSArray = seriesGroupHistory.object(forKey: key) as! NSArray

        return seriesArray.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.white.withAlphaComponent(0.4)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-hh:mm a"

        let keys: [String] = ((seriesGroupHistory.allKeys as! [String]).sorted()).reversed()
        let groupKey = keys[section]
        
        let seriesGroup: SeriesGroup = seriesGroupTimeStampHistory.object(forKey: groupKey) as! SeriesGroup

        let stringTimestamp: String = seriesGroup.timeStamps![0] as! String
        
        let date = dateFormatter.date(from: stringTimestamp)!
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        let month = months[components.month!-1]
        
        return "\(String(describing: month)) \(String(describing: components.year!))"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let groupKeys: [String] = ((seriesGroupHistory.allKeys as! [String]).sorted()).reversed()
        let groupKey = groupKeys[indexPath.section]
        let seriesArray: NSArray = seriesGroupHistory.object(forKey: groupKey) as! NSArray
        let series: [[Frame]] = seriesArray.object(at: indexPath.row) as! [[Frame]]

        let subtitle = seriesScore(for: series)
        let seriesGroup: SeriesGroup = seriesGroupTimeStampHistory.object(forKey: groupKey) as! SeriesGroup
        let timestamp: String = seriesGroup.timeStamps?.object(at: indexPath.row) as! String

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let accessory = DisclosureIndicator.create(color: UIColor.black, highlightedColor: UIColor.black)
        cell.accessoryView = accessory

        // Configure the cell...
        cell.textLabel?.text = timestamp
        cell.detailTextLabel?.text = subtitle

        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSeriesHistorySummary" {
            let indexPath = tableView.indexPathForSelectedRow
            let groupKeys: [String] = ((seriesGroupHistory.allKeys as! [String]).sorted()).reversed()
            let groupKey = groupKeys[indexPath!.section]
            let seriesArray: NSArray = seriesGroupHistory.object(forKey: groupKey) as! NSArray
            let series: [[Frame]] = seriesArray.object(at: indexPath!.row) as! [[Frame]]
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
        
        for index in 0...2 {
            let game = series[index]
            let frame: Frame = game[0]
            frameScores += "\(frame.finalScore) "
            seriesScore += frame.finalScore
        }
        
        return "\(frameScores) - (\(seriesScore))"
    }
    
    func seriesScore(for series: [[Frame]]) -> String? {
        var seriesScore = 0
        var frameScores = ""
        
        for index in 0...2 {
            let game = series[index]
            let frame: Frame = game[0]
            frameScores += "\(frame.finalScore) "
            seriesScore += frame.finalScore
        }
        
        return "\(frameScores) - (\(seriesScore))"
    }
    
    // MARK: - Grouping
    
    func groupSeriesHistory() {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-hh:mm a"
        
        seriesGroupHistory.removeAllObjects()

        let keys: [String] = ((seriesHistory!.allKeys as! [String]).sorted()).reversed()
        for key in keys {
            let date = dateFormatter.date(from: key)!
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
            let month = String(format: "%02d", arguments: [components.month!])
            let groupKey = "\(String(describing: components.year!))\(String(describing: month))"
            if let groups: NSMutableArray = seriesGroupHistory.object(forKey: groupKey) as? NSMutableArray {
                let seriesGroup: SeriesGroup = seriesGroupTimeStampHistory.object(forKey: groupKey) as! SeriesGroup
                let series: [[Frame]] = seriesHistory!.object(forKey: key) as! [[Frame]]
                let timestamps: NSMutableArray = seriesGroup.timeStamps!
                groups.add(series)
                timestamps.add(key)

                seriesGroup.groups = groups
                seriesGroup.timeStamps = timestamps

                seriesGroupHistory.setObject(groups, forKey: groupKey as NSCopying)
                seriesGroupTimeStampHistory.setObject(seriesGroup, forKey: groupKey as NSCopying)
            } else {
                let groups = NSMutableArray()
                let timestamps = NSMutableArray()
                let series: [[Frame]] = seriesHistory!.object(forKey: key) as! [[Frame]]
                groups.add(series)
                timestamps.add(key)

                let seriesGroup = SeriesGroup()
                seriesGroup.groups = groups
                seriesGroup.timeStamps = timestamps
                
                seriesGroupHistory.setObject(groups, forKey: groupKey as NSCopying)
                seriesGroupTimeStampHistory.setObject(seriesGroup, forKey: groupKey as NSCopying)
            }
       }
    }
    
    func dateToGroupKey(now: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-hh:mm a"
        
        return dateFormatter.string(from: now)
    }

}
