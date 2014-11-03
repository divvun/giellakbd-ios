//
//  DefaultSettings.swift
//  TastyImitationKeyboard
//
//  Created by Alexei Baboulevitch on 11/2/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

import UIKit

// TODO: move this somewhere else and localize
let settings = [
    (kAutoCapitalization, "Auto-Capitalization"),
    (kPeriodShortcut,  "“.” Shortcut")
]

class DefaultSettings: ExtraView, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView?
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let tableView = self.tableView {
            let numRows = self.tableView(tableView, numberOfRowsInSection: 0)
            let fakeTableHeight = self.bounds.height - 85 //TODO: so sue me
            let rowHeight = self.tableView(tableView, heightForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
            let offset = (fakeTableHeight - (CGFloat(numRows) * rowHeight)) / CGFloat(2)
            
            if offset >= 0 {
                tableView.scrollEnabled = false
                tableView.contentInset = UIEdgeInsetsMake(offset, 0, 0, 0)
            }
            else {
                tableView.scrollEnabled = true
                tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    // TODO: I couldn't add a prototype cell to the table view in the nib for some reason
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        var sw = UISwitch()
        var label = UILabel()
        sw.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        sw.on = NSUserDefaults.standardUserDefaults().boolForKey(settings[indexPath.row].0)
        label.text = settings[indexPath.row].1
        label.sizeToFit()
        
        cell.addSubview(sw)
        cell.addSubview(label)
        
        let left = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: cell, attribute: NSLayoutAttribute.LeftMargin, multiplier: 1, constant: 0)
        let labelCenterY = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: cell, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: cell, attribute: NSLayoutAttribute.RightMargin, multiplier: 1, constant: 0)
        let swCenterY = NSLayoutConstraint(item: sw, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: cell, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        
        cell.addConstraint(left)
        cell.addConstraint(right)
        cell.addConstraint(labelCenterY)
        cell.addConstraint(swCenterY)

        return cell
    }
}