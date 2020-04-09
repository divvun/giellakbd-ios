import UIKit

final class UserDictionaryView: UIView, Nibbable {
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableContainer: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyState: UIView!
    @IBOutlet weak var dictionaryIconContainer: UIView!
    @IBOutlet weak var noWordsLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupEmptyState()
    }

    private func setupEmptyState() {
        dictionaryIconContainer.layer.cornerRadius = dictionaryIconContainer.frame.height / 2.0
        noWordsLabel.text = Strings.noUserWords
        detailLabel.text = Strings.noUserWordsDescription
    }
}
