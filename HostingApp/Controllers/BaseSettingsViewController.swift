import UIKit

typealias ViewControllerMaker = (() -> UIViewController)?

struct Row {
    let title: String
    let destinationViewController: ViewControllerMaker
}

protocol SettingsController: BaseSettingsViewController {
    func rows() -> [Row]
}

class BaseSettingsViewController: UITableViewController {

    private lazy var _rows: [Row] = rows()

    init() {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func rows() -> [Row] {
        [Row(title: "Override the rows() method to customize", destinationViewController: nil)]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(DisclosureCell.self)
        enableSwipeToGoBackGesture()
    }

    private func enableSwipeToGoBackGesture() {
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(DisclosureCell.self)
        cell.textLabel?.text = _rows[indexPath.item].title
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = _rows[indexPath.row]
        guard let viewController = row.destinationViewController?() else {
            return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

}
