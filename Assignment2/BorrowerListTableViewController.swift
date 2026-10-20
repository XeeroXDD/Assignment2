//
//  BorrowerListTableViewController.swift
//  Assignment2
//
//  Created by Felix KHNEN on 20/10/2026.
//
import UIKit

class BorrowerListViewController: UITableViewController {

    private var borrowers: [User] = []

    // Reload each time, so a newly added borrower appears.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        borrowers = DataManager.shared.fetchBorrowers()   // sorted A–Z by name

        let empty = UILabel()
        empty.text = "No borrowers yet."
        empty.textAlignment = .center
        empty.textColor = .lightGray
        tableView.backgroundView = borrowers.isEmpty ? empty : nil

        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return borrowers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BorrowerCell", for: indexPath)
        let borrower = borrowers[indexPath.row]

        var content = UIListContentConfiguration.subtitleCell()
        content.text = borrower.name
        content.secondaryText = "@\(borrower.username ?? "")  ·  \(borrower.address ?? "")"
        content.textProperties.font = .boldSystemFont(ofSize: 16)
        content.textProperties.color = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1)       // #F5F5F0
        content.secondaryTextProperties.color = UIColor(red: 0.79, green: 0.72, blue: 0.59, alpha: 1) // #C9B896
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator   // ">" arrow shows it can be tapped

        return cell
    }
    // Tapping a row opens that borrower's detail screen.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        performSegue(withIdentifier: "showBorrowerDetail", sender: cell)
    }    // Pass the tapped borrower to the detail screen.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showBorrowerDetail",
              let detail = segue.destination as? BorrowerDetailViewController,
              let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        detail.borrower = borrowers[indexPath.row]
    }
}
