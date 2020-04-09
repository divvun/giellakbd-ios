import UIKit

final class UserDictionaryViewController: ViewController<UserDictionaryView> {
    private let userDictionary: UserDictionary
    private var userWords: [String] {
        userDictionary.getUserWords()
    }
    private var isEmpty: Bool { userWords.count == 0 }

    private var tableView: UITableView {
        contentView.tableView!
    }

    private var segmentedControl: UISegmentedControl {
        contentView.segmentedControl!
    }

    init(keyboardLocale: KeyboardLocale) {
        self.userDictionary = UserDictionary(locale: keyboardLocale)
        super.init()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: .HostingAppWillEnterForeground, object: nil)
    }

    @objc private func willEnterForeground() {
        self.tableView.reloadData()
        updateEmptyStateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deselectSelectedRow()
    }

    private func setupView() {
        setupNavBar()
        setupSegmentedControl()
        setupTableView()
        updateEmptyStateView()
    }

    private func setupNavBar() {
        title = Strings.userDictionary
        let plusButton = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(showAddWordAlert))
        navigationItem.rightBarButtonItem = plusButton
    }

    private func setupSegmentedControl() {
        let whitelist = "Whitelist" // TODO: LOCALIZE
        let blacklist = "Blacklist" // TODO: LOCALIZE
        segmentedControl.setTitle(whitelist, forSegmentAt: 0)
        segmentedControl.setTitle(blacklist, forSegmentAt: 1)
    }

    private func setupTableView() {
        tableView.isHidden = false
        tableView.register(DisclosureCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }

    private func updateEmptyStateView() {
        tableView.isHidden = isEmpty
    }

    private func deselectSelectedRow() {
        if let selectedRowPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRowPath, animated: true)
        }
    }

    @objc private func showAddWordAlert() {
        let title = "Add Word" // LOCALIZE ME
        let message = "This word will be suggested in the spelling banner for similar input." // LOCALIZE ME
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Word"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.delegate = self
        }

        // LOCALIZE
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            guard let word = alert.textFields?.first?.text,
                word.isEmpty == false else {
                return
            }
            self.insertWordAndUpdateView(word)
        }

        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        self.present(alert, animated: true)
    }

    private func insertWordAndUpdateView(_ word: String) {
        userDictionary.addWordManually(word)
        let insertIndexPath = indexPathForNewWord(word: word)
        tableView.insertRows(at: [insertIndexPath], with: .automatic)
        updateEmptyStateView()
    }

    private func deleteWord(at indexPath: IndexPath) {
        let word = userWords[indexPath.row]
        userDictionary.removeWord(word)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    private func indexPathForNewWord(word: String) -> IndexPath {
        if let index = userWords.firstIndex(where: { word < $0 }) {
            return IndexPath(row: index - 1, section: 0)
        } else {
            return IndexPath(row: userWords.count - 1, section: 0)
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

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        updateEmptyStateView()
    }
}

extension UserDictionaryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let word = userWords[indexPath.row]
        let wordController = WordContextViewController(dictionary: userDictionary, word: word)
        navigationController?.pushViewController(wordController, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let title = "Blacklist"

        let blacklist = UIContextualAction(style: .normal, title: title,
                                           handler: { (_, _, completionHandler) in
                                            // IMPLEMENT ME
                                            let alert = UIAlertController(title: "HI",
                                                                          message: "blacklist",
                                                                          preferredStyle: .alert)
                                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                                            self.present(alert, animated: true)
                                            completionHandler(true)
        })

        let delete = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completionHandler) in
            self.deleteWord(at: indexPath)
            completionHandler(true)
        }

        blacklist.backgroundColor = .gray
        delete.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [delete, blacklist])
        return configuration
    }
}

extension UserDictionaryViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.contains(" ") {
            return false
        }
        return true
    }
}
