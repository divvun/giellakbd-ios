import UIKit

class UserDictionaryView: UIView, Nibbable {
    @IBOutlet var tableView: UITableView!

    override func awakeFromNib() {
        super.awakeFromNib()

        // For some reason it's not possible to set auto layout constraints on a table view in nib
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.fill(superview: self)
    }
}
