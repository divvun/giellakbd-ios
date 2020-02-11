import UIKit

class UserDictionaryViewController: ViewController<UserDictionaryView>, UITableViewDataSource, UITableViewDelegate {

    private let userDictionary = UserDictionary()
    private var userWords: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        userWords = userDictionary.getUserWords()

        contentView.tableView.dataSource = self
        contentView.tableView.delegate = self
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userWords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = userWords[indexPath.item]
        return cell
    }
}
