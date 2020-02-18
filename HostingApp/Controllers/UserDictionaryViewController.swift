import UIKit

class UserDictionaryViewController: ViewController<UserDictionaryView> {
    private let userDictionary = UserDictionary()
    private lazy var userWords: [String] = userDictionary.getUserWords()
    private var isEmpty: Bool { userWords.count == 0 }
    private let keyboardLocale: KeyboardLocale

    private var tableView: UITableView {
        contentView.tableView!
    }

    init(keyboardLocale: KeyboardLocale) {
        self.keyboardLocale = keyboardLocale
        super.init()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.userDictionary
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deselectSelectedRow()
    }

    private func setupView() {
        if isEmpty {
            showEmptyState()
        } else {
            setupTableView()
        }
    }

    private func showEmptyState() {
        tableView.isHidden = true
    }

    private func setupTableView() {
        tableView.isHidden = false
        tableView.register(DisclosureCell.self)
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
        let cell = tableView.dequeueReusableCell(DisclosureCell.self)
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
