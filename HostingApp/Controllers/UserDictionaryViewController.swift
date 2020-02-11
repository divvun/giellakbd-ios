import UIKit

class UserDictionaryViewController: ViewController<UserDictionaryView>, UITableViewDataSource, UITableViewDelegate {

    private lazy var userWords: [String] = {
        let userDictionary = UserDictionary()
        return userDictionary.getUserWords()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        let tableView = contentView.tableView!
        tableView.register(UserDictionaryWordCell.self,
                                       forCellReuseIdentifier: UserDictionaryWordCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userWords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserDictionaryWordCell.reuseIdentifier) else {
            fatalError("Couldn't dequeue User Dictionary Word Cell")
        }
        cell.textLabel?.text = userWords[indexPath.item]
        return cell
    }
}

class UserDictionaryWordCell: UITableViewCell {
    static let reuseIdentifier = String(describing: self)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
