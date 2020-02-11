import UIKit

class WordContextViewController: ViewController<WordContextView> {
    private let word: String

    init(word: String) {
        self.word = word
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
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "word: \(word) \(String(describing: indexPath.item))"
        return cell
    }
}
