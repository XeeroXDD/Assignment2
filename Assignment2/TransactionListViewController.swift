//
//  TransactionListViewController.swift
//  Assignment2
//
//  Created by Felix KHNEN on 21/10/2026.
//
import UIKit

class TransactionListViewController: UITableViewController {

    // Admins: one section per borrower (A–Z). Borrowers: one section of their own.
    private var sections: [(title: String, transactions: [BorrowTransaction])] = []

    private let textColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1)   // #F5F5F0
    private let subColor = UIColor(red: 0.79, green: 0.72, blue: 0.59, alpha: 1)    // #C9B896
    private let honey = UIColor(red: 0.91, green: 0.64, blue: 0.24, alpha: 1)       // #E8A33D

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor(red: 0.11, green: 0.08, blue: 0.06, alpha: 1)  // #1C1410
    }

    // Reload every time, so new transactions and overdue changes show up.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DataManager.shared.refreshOverdue()
        loadTransactions()
    }

    private func loadTransactions() {
        if Session.isAdmin {
            let all = DataManager.shared.fetchTransactions(for: nil)
            let grouped = Dictionary(grouping: all) { $0.borrower?.name ?? "Unknown borrower" }
            sections = grouped.keys.sorted().map { (title: $0, transactions: grouped[$0] ?? []) }
        } else {
            let mine = DataManager.shared.fetchTransactions(for: Session.currentUser)
            sections = mine.isEmpty ? [] : [(title: "My transactions", transactions: mine)]
        }

        if sections.isEmpty {
            let label = UILabel()
            label.text = "No transactions yet."
            label.textAlignment = .center
            label.textColor = .lightGray
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
        tableView.reloadData()
    }

    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].transactions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
        let transaction = sections[indexPath.section].transactions[indexPath.row]

        let titles = DataManager.shared.items(of: transaction).map { $0.book?.title ?? "Deleted book" }
        let date = dateFormatter.string(from: transaction.dateCreated ?? Date())
        let status = DataManager.shared.status(of: transaction)

        var content = UIListContentConfiguration.subtitleCell()
        content.text = titles.joined(separator: ", ")
        content.secondaryText = "\(date)  ·  \(status)"
        content.textProperties.font = .boldSystemFont(ofSize: 16)
        content.textProperties.color = textColor
        content.secondaryTextProperties.color = status == BookStatus.overdue ? .systemRed : subColor
        cell.contentConfiguration = content
        cell.backgroundColor = UIColor(red: 0.23, green: 0.16, blue: 0.07, alpha: 1)   // #3A2A12
        return cell
    }

    // Honey-coloured section headers (borrower names).
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = sections[section].title.uppercased()
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = honey
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        return container
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
}
