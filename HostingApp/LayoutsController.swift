////
////  LayoutsController.swift
////  GiellaKeyboard
////
////  Created by Brendan Molloy on 15/5/17.
////  Copyright © 2017 Apple. All rights reserved.
////
//
//import UIKit
//
//class LayoutsController: UITableViewController {
//    var rows = KeyboardDefinition.definitions
//
//    var selectedRow = IndexPath(item: KeyboardSettings.currentKeyboard, section: 0)
//
//    @objc private func onDoneTapped() {
//        KeyboardSettings.currentKeyboard = selectedRow.row
//        navigationController?.popViewController(animated: true)
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        tableView.allowsSelection = true
//        tableView.allowsMultipleSelection = false
//
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.save, style: .done, target: self, action: #selector(onDoneTapped))
//
//        title = Strings.layouts
//
//        tableView.tableFooterView = UIView()
//
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
//    }
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return rows.count
//    }
//
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        if selectedRow == indexPath { return }
//
//        tableView.cellForRow(at: selectedRow)?.accessoryType = .none
//        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
//
//        selectedRow = indexPath
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//
//        cell.textLabel?.text = rows[indexPath.row].name
//        cell.accessoryType = selectedRow == indexPath ? .checkmark : .none
//
//        return cell
//    }
//}

