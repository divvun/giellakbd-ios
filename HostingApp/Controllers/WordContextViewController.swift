import UIKit

class WordContextViewController: ViewController<WordContextView> {
    private let word: String
    private let contexts: [WordContext]

    init(dictionary: UserDictionary, word: String, locale: KeyboardLocale) {
        self.word = word
        contexts = dictionary.getContexts(for: word, locale: locale)
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.contextsFor(word: word)
        setupTableView()
    }

    private func setupTableView() {
        let tableView = contentView.tableView!
        tableView.dataSource = self
        tableView.register(WordContextCell.self)
        tableView.tableFooterView = UIView()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WordContextViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contexts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(WordContextCell.self)
        let context = contexts[indexPath.item]
        cell.textLabel?.attributedText = context.contextAttributedString()
        return cell
    }
}

class WordContextCell: UITableViewCell { }
