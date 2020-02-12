import UIKit

class WordContextViewController: ViewController<WordContextView> {
    private let contexts: [WordContext]

    init(dictionary: UserDictionary, word: String) {
        contexts = dictionary.getContexts(for: word)
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        let tableView = contentView.tableView!
        tableView.dataSource = self
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
        let cell = UITableViewCell()
        let context = contexts[indexPath.item]
        cell.textLabel?.text = context.contextString()
        return cell
    }
}
