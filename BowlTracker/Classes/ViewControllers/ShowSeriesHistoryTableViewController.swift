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

        navigationItem.rightBarButtonItem = editButtonItem

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
        
        var groupAverage = 0.0
        var groupSerieseTotal = 0
        var groupTotalGames = 0
        var groupsCount = 0
        var seriesGames: [[Any]] = [[Any]]()
        for seriesAverage in seriesGroup.groupAverage {
            seriesGames = seriesGroup.groups![groupsCount] as! [[Any]]
            groupSerieseTotal += seriesAverage as! Int
            groupTotalGames += seriesGames.count
            groupsCount += 1
        }
        
        groupAverage = round(Double((groupSerieseTotal/groupTotalGames)))
        let date = dateFormatter.date(from: stringTimestamp)!
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        let month = months[components.month!-1]
        
        return "\(String(describing: month)) \(String(describing: components.year!)) - Avg (\(Int(groupAverage)))"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let groupKeys: [String] = ((seriesGroupHistory.allKeys as! [String]).sorted()).reversed()
        let groupKey = groupKeys[indexPath.section]
        let seriesArray: NSArray = seriesGroupHistory.object(forKey: groupKey) as! NSArray
        let series: [[Frame]] = seriesArray.object(at: indexPath.row) as! [[Frame]]

        let subtitle = seriesScoreTitle(for: series)
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            let groupKeys: [String] = ((seriesGroupHistory.allKeys as! [String]).sorted()).reversed()
            let groupKey = groupKeys[indexPath.section]
            let seriesArray: NSMutableArray = (seriesGroupHistory.object(forKey: groupKey) as! NSArray).mutableCopy() as! NSMutableArray
            
            // Remove from group history
            seriesArray.removeObject(at: indexPath.row)
            if seriesArray.count > 0 {
                seriesGroupHistory.setObject(seriesArray, forKey: groupKey as NSCopying)
            } else {
                seriesGroupHistory.removeObject(forKey: groupKey)
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .fade)
           }
            
            // Remove from series history
            let cell = tableView.cellForRow(at: indexPath)
            let key = cell!.textLabel?.text
            let mutableSeriesHistory: NSMutableDictionary = seriesHistory!.mutableCopy() as! NSMutableDictionary
            mutableSeriesHistory.removeObject(forKey: key as Any)
            seriesHistory = mutableSeriesHistory
            
            let result = PropertyList.writePropertyListFromDictionary(filename: "SeriesHistory" as NSString, plistDict: seriesHistory! as NSDictionary)
            if result {
                print("Series was saved")
                let success = PropertyList.delete("temp")
                debugPrint("Deleting temp file: \(success)")
            } else {
                print("Series was not saved")
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
            //After this, you must reload data of table
            groupSeriesHistory()
            tableView.reloadData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
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
            controller.seriesDateTextTitle = cell!.textLabel?.text
            controller.seriesTextTitle = cell!.detailTextLabel?.text
            controller.series = series
            controller.maxGames = series.count
            controller.isHistory = true
       }
    }

    // MARK: - Utility
    
    func seriesScore(for key: String, series: NSDictionary) -> String? {
        let series: [[Frame]] = series.object(forKey: key) as! [[Frame]]
        var seriesScore = 0
        var frameScores = ""
        
        for index in 0...series.count-1 {
            let game = series[index]
            let frame: Frame = game[0]
            frameScores += "\(frame.finalScore) "
            seriesScore += frame.finalScore
        }
        
        return "\(frameScores) - (\(seriesScore))"
    }
    
    func seriesScoreTitle(for series: [[Frame]]) -> String? {
        var seriesScore = 0
        var frameScores = ""
        
        for index in 0...series.count-1 {
            let game = series[index]
            let frame: Frame = game[0]
            frameScores += "\(frame.finalScore) "
            seriesScore += frame.finalScore
        }
        
        return "\(frameScores) - (\(seriesScore))"
    }
    
    func seriesScore(for series: [[Frame]]) -> Int? {
        var seriesScore = 0
        
        for index in 0...series.count-1 {
            let game = series[index]
            let frame: Frame = game[0]
            seriesScore += frame.finalScore
        }
        
        return seriesScore
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
                seriesGroup.groupAverage.add(seriesScore(for: series)!)

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
                seriesGroup.groupAverage.add(seriesScore(for: series)!)

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
