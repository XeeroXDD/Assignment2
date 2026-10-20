//
//  CreateTransactionViewController.swift
//  Assignment2
//
//  Created by Felix KHNEN on 20/10/2026.
//

import UIKit

class CreateTransactionViewController: UITableViewController {

    // Admins pick a borrower; borrowers always borrow for themselves.
    private var selectedBorrower: User?
    private var borrowers: [User] = []

    // Available books grouped by category, A–Z by title within each.
    private var sections: [(category: String, books: [Book])] = []
    private var selectedBooks = Set<Book>()

    private let textColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1)    // #F5F5F0
    private let subColor = UIColor(red: 0.79, green: 0.72, blue: 0.59, alpha: 1)     // #C9B896
    private let honey = UIColor(red: 0.91, green: 0.64, blue: 0.24, alpha: 1)        // #E8A33D

    // Admins get an extra "Borrower" section at the top.
    private var bookSectionOffset: Int { return Session.isAdmin ? 1 : 0 }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Confirm", style: .prominent, target: self, action: #selector(confirmTapped))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SelectCell")

        if Session.isAdmin {
            borrowers = DataManager.shared.fetchBorrowers()
        } else {
            selectedBorrower = Session.currentUser
        }
        loadBooks()
    }

    private func loadBooks() {
        let available = DataManager.shared.fetchAvailableBooks()
        sections = Category.all.compactMap { category in
            let books = available.filter { $0.category == category }
            return books.isEmpty ? nil : (category, books)
        }

        if sections.isEmpty {
            let label = UILabel()
            label.text = "No books are available to borrow right now."
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .lightGray
            tableView.backgroundView = label
        }
        tableView.reloadData()
    }

    // MARK: - Table data

    override func numberOfSections(in tableView: UITableView) -> Int {
        return bookSectionOffset + sections.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < bookSectionOffset { return "Borrower" }
        return sections[section - bookSectionOffset].category
    }

    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = self.tableView(tableView, titleForHeaderInSection: section)?.uppercased()
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
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < bookSectionOffset { return 1 }
        return sections[section - bookSectionOffset].books.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectCell", for: indexPath)
        var content = UIListContentConfiguration.subtitleCell()
        content.textProperties.color = textColor
        content.secondaryTextProperties.color = subColor
        cell.backgroundColor = UIColor(red: 0.23, green: 0.16, blue: 0.07, alpha: 1)  // #3A2A12
        cell.tintColor = honey

        if indexPath.section < bookSectionOffset {
            // Borrower row (admins only).
            content.text = selectedBorrower?.name ?? "Tap to choose a borrower"
            content.secondaryText = selectedBorrower.map { "@\($0.username ?? "")" }
            cell.accessoryType = .disclosureIndicator
        } else {
            let book = sections[indexPath.section - bookSectionOffset].books[indexPath.row]
            content.text = book.title
            content.secondaryText = "\(book.author ?? "")  ·  due in \(book.dueIn)s"
            cell.accessoryType = selectedBooks.contains(book) ? .checkmark : .none
        }

        cell.contentConfiguration = content
        return cell
    }

    // MARK: - Selection

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section < bookSectionOffset {
            chooseBorrower()
            return
        }

        // Tick or untick the tapped book.
        let book = sections[indexPath.section - bookSectionOffset].books[indexPath.row]
        if selectedBooks.contains(book) {
            selectedBooks.remove(book)
        } else {
            selectedBooks.insert(book)
        }
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    // Admin picks an existing borrower from a list.
    private func chooseBorrower() {
        guard !borrowers.isEmpty else {
            showAlert("No borrowers", "Add a borrower account first.")
            return
        }
        let sheet = UIAlertController(title: "Choose a borrower", message: nil, preferredStyle: .actionSheet)
        for borrower in borrowers {
            sheet.addAction(UIAlertAction(title: borrower.name, style: .default) { _ in
                self.selectedBorrower = borrower
                self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    // MARK: - Confirm

    @IBAction func confirmTapped(_ sender: UIBarButtonItem) {
        // Business rule: the borrower must already exist.
        guard let borrower = selectedBorrower else {
            showAlert("No borrower", "Please choose a borrower first.")
            return
        }
        // Business rule: at least one book must be selected.
        guard !selectedBooks.isEmpty else {
            showAlert("No books", "Please select at least one book.")
            return
        }

        let books = Array(selectedBooks)
        guard DataManager.shared.createTransaction(borrower: borrower, books: books) != nil else {
            showAlert("Error", "The transaction could not be saved. Please try again.")
            return
        }

        let titles = books.map { $0.title ?? "" }.joined(separator: ", ")
        let done = UIAlertController(title: "Transaction created",
                                     message: "\(borrower.name ?? "") borrowed: \(titles)",
                                     preferredStyle: .alert)
        done.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(done, animated: true)
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
