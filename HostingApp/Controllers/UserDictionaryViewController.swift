import UIKit

class UserDictionaryViewController: ViewController<UserDictionaryView> {
    private let userDictionary = UserDictionary()
    private lazy var userWords: [String] = userDictionary.getUserWords()

    private var tableView: UITableView {
        contentView.tableView!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "User Dictionary" // LOCALIZE ME
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deselectSelectedRow()
    }

    private func setupTableView() {
        tableView.register(UserDictionaryWordCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }

    private func deselectSelectedRow() {
        if let selectedRowPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRowPath, animated: true)
        }
    }
}

extension UserDictionaryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userWords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(UserDictionaryWordCell.self)
        cell.textLabel?.text = userWords[indexPath.item]
        return cell
    }
}

extension UserDictionaryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let word = userWords[indexPath.row]
        let wordController = WordContextViewController(dictionary: userDictionary, word: word)
        navigationController?.pushViewController(wordController, animated: true)
    }
}

class UserDictionaryWordCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
