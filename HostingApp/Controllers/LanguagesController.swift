import UIKit

class LanguagesController: UITableViewController {
    let rows = Strings.supportedLocales

    var selectedRow: IndexPath?

    @objc private func onDoneTapped() {
        if let row = selectedRow?.row {
            KeyboardSettings.languageCode = rows[row].languageCode!
            Strings.languageCode = KeyboardSettings.languageCode
        }

        navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let selectedLocale = Locale(identifier: KeyboardSettings.languageCode)

        if let i = rows.firstIndex(where: { $0.languageCode == selectedLocale.languageCode }) {
            selectedRow = IndexPath(item: i, section: 0)
            tableView.reloadData()
        }

        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: Strings.save,
            style: .done,
            target: self,
            action: #selector(onDoneTapped)
        )

        title = Strings.language

        tableView.tableFooterView = UIView()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if selectedRow == indexPath { return }

        if let s = selectedRow {
            tableView.cellForRow(at: s)?.accessoryType = .none
        }

        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark

        selectedRow = indexPath
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = Strings.languageName(for: rows[indexPath.row])!
        cell.accessoryType = selectedRow == indexPath ? .checkmark : .none

        return cell
    }
}
