import UIKit

typealias ViewControllerMaker = (() -> UIViewController)?

struct Row {
    let title: String
    let destinationViewController: ViewControllerMaker
}

class SettingsViewController: UITableViewController {

    var rows: [Row] {
        let destinationViewController: ViewControllerMaker
        let locales = KeyboardLocales.allLocales
        if locales.count == 1 {
            destinationViewController = {
                UserDictionaryViewController(keyboardLocale: locales.first!)
            }
        } else {
            destinationViewController = {
                KeyboardLocalesViewController()
            }
        }

        return [
            Row(title: Strings.userDictionary, destinationViewController: destinationViewController)
        ]
    }

    init() {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(DisclosureCell.self)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(DisclosureCell.self)
        cell.textLabel?.text = rows[indexPath.item].title
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        guard let viewController = row.destinationViewController?() else {
            return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

}
