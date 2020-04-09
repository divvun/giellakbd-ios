import UIKit

final class UserDictionaryViewController: ViewController<UserDictionaryView> {
    enum SegmentIndex: Int {
        case detected = 0
        case userDefined
        case blocked
    }

    private let userDictionary: UserDictionary
    private var detectedWords: [String] {
        userDictionary.getDetectedWords()
    }
    private var userDefinedWords: [String] {
        userDictionary.getUserDefinedWords()
    }
    private var blockedWords: [String] {
        userDictionary.getBlacklistedWords()
    }
    private var currentWordlist: [String] {
        switch currentSegment {
        case .detected:
            return detectedWords
        case .userDefined:
            return userDefinedWords
        case .blocked:
            return blockedWords
        }
    }
    private var isEmpty: Bool {
        detectedWords.isEmpty
            && userDefinedWords.isEmpty
            && blockedWords.isEmpty
    }

    private var tableContainer: UIView {
        contentView.tableContainer!
    }

    private var tableView: UITableView {
        contentView.tableView!
    }

    private var segmentedControl: UISegmentedControl {
        contentView.segmentedControl!
    }

    private var currentSegment: SegmentIndex {
        SegmentIndex(rawValue: segmentedControl.selectedSegmentIndex)!
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
        segmentedControl.setTitle(Strings.detected, forSegmentAt: SegmentIndex.detected.rawValue)
        segmentedControl.setTitle(Strings.userDefined, forSegmentAt: SegmentIndex.userDefined.rawValue)
        segmentedControl.setTitle(Strings.blocked, forSegmentAt: SegmentIndex.blocked.rawValue)
        segmentedControl.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
    }

    private func setupTableView() {
        tableView.isHidden = false
        tableView.register(DisclosureCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }

    @objc private func refreshTable() {
        tableView.reloadData()
    }

    private func updateEmptyStateView() {
        tableContainer.isHidden = isEmpty
    }

    private func deselectSelectedRow() {
        if let selectedRowPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRowPath, animated: true)
        }
    }

    @objc private func showAddWordAlert() {
        let alert = UIAlertController(title: Strings.addWord, message: Strings.addWordMessage, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = Strings.word
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.delegate = self
        }

        let addAction = UIAlertAction(title: Strings.add, style: .default) { _ in
            guard let word = alert.textFields?.first?.text,
                word.isEmpty == false else {
                return
            }
            self.insertWordAndUpdateView(word)
        }

        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel))

        self.present(alert, animated: true)
    }

    private func insertWordAndUpdateView(_ word: String) {
        userDictionary.addWordManually(word)
        if currentSegment == .userDefined {
            let insertIndexPath = indexPathForNewWord(word: word)
            tableView.insertRows(at: [insertIndexPath], with: .automatic)
        }
        updateEmptyStateView()
    }

    private func deleteWord(at indexPath: IndexPath) {
        let word = currentWordlist[indexPath.row]
        userDictionary.removeWord(word)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    private func blockWord(at indexPath: IndexPath) {
        let word = currentWordlist[indexPath.row]
        userDictionary.blacklistWord(word)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    private func unblockWord(at indexPath: IndexPath) {
        let word = blockedWords[indexPath.row]
        userDictionary.unblacklistWord(word)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    private func indexPathForNewWord(word: String) -> IndexPath {
        if let index = userDefinedWords.firstIndex(where: { word < $0 }) {
            return IndexPath(row: index - 1, section: 0)
        } else {
            return IndexPath(row: userDefinedWords.count - 1, section: 0)
        }
    }
}

extension UserDictionaryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentWordlist.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(DisclosureCell.self)
        cell.textLabel?.text = currentWordlist[indexPath.item]
        return cell
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        updateEmptyStateView()
    }
}

extension UserDictionaryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let word = currentWordlist[indexPath.row]
        let wordController = WordContextViewController(dictionary: userDictionary, word: word)
        navigationController?.pushViewController(wordController, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return currentSegment == .blocked
            ? blockedWordsSwipeConfiguration(indexPath: indexPath)
            : normalWordsSwipeConfiguration(indexPath: indexPath)
    }

    private func normalWordsSwipeConfiguration(indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let block = UIContextualAction(style: .normal, title: Strings.block, handler: { (_, _, completionHandler) in
            self.blockWord(at: indexPath)
            completionHandler(true)
        })
        block.backgroundColor = .gray

        let delete = UIContextualAction(style: .destructive, title: Strings.delete) { (_, _, completionHandler) in
            self.deleteWord(at: indexPath)
            completionHandler(true)
        }
        delete.backgroundColor = .red

        return UISwipeActionsConfiguration(actions: [delete, block])
    }

    private func blockedWordsSwipeConfiguration(indexPath: IndexPath) -> UISwipeActionsConfiguration {
        let unblock = UIContextualAction(style: .normal, title: Strings.unblock, handler: { (_, _, completionHandler) in
            self.unblockWord(at: indexPath)
            completionHandler(true)
        })
        unblock.backgroundColor = .gray

        return UISwipeActionsConfiguration(actions: [unblock])
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
