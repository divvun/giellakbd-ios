import UIKit

typealias ViewControllerMaker = (() -> UIViewController)?

struct Row {
    let title: String
    let destinationViewController: ViewControllerMaker
}

class BaseSettingsViewController: UITableViewController {

    var rows: [Row] {
        []
    }

    init() {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getInt() -> Int {
        return 1
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
