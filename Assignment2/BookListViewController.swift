//
//  BookListViewController.swift
//  Assignment2
//
//  Created by Felix KHNEN on 20/10/2026.
//

import UIKit

class BookListViewController: UITableViewController {
    
    // One entry per category, each holding its books sorted by title.
    private var sections: [(category: String, books: [Book])] = []
    
    // Buttons for Select mode (admins only).
    private var addButton: UIBarButtonItem?
    private lazy var selectButton = UIBarButtonItem(title: "Select", style: .plain,
                                                    target: self, action: #selector(toggleSelectMode))
    private lazy var deleteButton = UIBarButtonItem(title: "Delete", style: .plain,
                                                    target: self, action: #selector(deleteSelected))

    override func viewDidLoad() {
        super.viewDidLoad()

        // Business rule: only admins can add or delete books.
        if Session.isAdmin {
            addButton = navigationItem.rightBarButtonItem       // the "+" from the storyboard
            navigationItem.leftItemsSupplementBackButton = true  // keep the back arrow
            navigationItem.leftBarButtonItem = selectButton
            deleteButton.tintColor = .systemRed
            tableView.allowsMultipleSelectionDuringEditing = true
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    // Reload every time the screen appears, so a newly added book shows up.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBooks()
    }
    
    private func loadBooks() {
        // fetchBooks() already sorts by category, then title A–Z.
        let allBooks = DataManager.shared.fetchBooks()
        
        // Group into sections, keeping the fixed category order.
        sections = Category.all.compactMap { category in
            let books = allBooks.filter { $0.category == category }
            return books.isEmpty ? nil : (category, books)
        }
        
        tableView.backgroundView = sections.isEmpty ? emptyLabel() : nil
        tableView.reloadData()
    }
    
    // Shown when the catalogue has no books.
    private func emptyLabel() -> UILabel {
        let label = UILabel()
        label.text = "No books in the catalogue yet."
        label.textAlignment = .center
        label.textColor = .lightGray
        return label
    }
    
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].category
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].books.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookCell", for: indexPath)
        let book = sections[indexPath.section].books[indexPath.row]
        
        // Title on top; author, category and status underneath.
        var content = UIListContentConfiguration.subtitleCell()
        content.text = book.title
        content.secondaryText = "\(book.author ?? "")  ·  \(book.category ?? "")  ·  \(book.status ?? "")"
        content.textProperties.font = .boldSystemFont(ofSize: 16)
        content.textProperties.color = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1)       // #F5F5F0
        content.secondaryTextProperties.color = UIColor(red: 0.79, green: 0.72, blue: 0.59, alpha: 1) // #C9B896
        cell.contentConfiguration = content
        
        return cell
    }
    
    // Swipe left on a book to delete it (admins only).
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // In Select mode, tapping just ticks the row.
        if tableView.isEditing {
            updateDeleteButton()
            return
        }

        // Otherwise, tapping opens the book in the edit form (admins only).
        tableView.deselectRow(at: indexPath, animated: true)
        guard Session.isAdmin else { return }

        let book = sections[indexPath.section].books[indexPath.row]
        guard let editor = storyboard?.instantiateViewController(withIdentifier: "AddBookVC")
                as? AddBookViewController else { return }
        editor.bookToEdit = book
        navigationController?.pushViewController(editor, animated: true)
    }
    
    // Asks before deleting, then shows why if the delete was refused.
    private func confirmDelete(_ book: Book) {
        let ask = UIAlertController(title: "Delete \"\(book.title ?? "")\"?",
                                    message: "This can't be undone.", preferredStyle: .alert)
        ask.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ask.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            if let problem = DataManager.shared.deleteBook(book) {
                self.showAlert("Can't delete", problem)
            } else {
                self.loadBooks()
            }
        })
        present(ask, animated: true)
    }
    
   

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing { updateDeleteButton() }
    }

    // Switches between normal mode and tick-box mode.
    @objc func toggleSelectMode() {
        let selecting = !tableView.isEditing
        tableView.setEditing(selecting, animated: true)
        selectButton.title = selecting ? "Done" : "Select"
        navigationItem.rightBarButtonItem = selecting ? deleteButton : addButton
        updateDeleteButton()
    }

    // Shows how many books are ticked, e.g. "Delete (3)".
    private func updateDeleteButton() {
        let count = tableView.indexPathsForSelectedRows?.count ?? 0
        deleteButton.title = count > 0 ? "Delete (\(count))" : "Delete"
        deleteButton.isEnabled = count > 0
    }

    // Deletes every ticked book, skipping any that are On Loan or Overdue.
    @objc func deleteSelected() {
        let selected = (tableView.indexPathsForSelectedRows ?? []).map {
            sections[$0.section].books[$0.row]
        }
        guard !selected.isEmpty else { return }

        let ask = UIAlertController(title: "Delete \(selected.count) book(s)?",
                                    message: "This can't be undone.", preferredStyle: .alert)
        ask.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ask.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            var deleted = 0
            var refused: [String] = []
            for book in selected {
                if let problem = DataManager.shared.deleteBook(book) {
                    refused.append(problem)
                } else {
                    deleted += 1
                }
            }

            self.toggleSelectMode()   // back to normal mode
            self.loadBooks()

            if !refused.isEmpty {
                self.showAlert("Deleted \(deleted) book(s)", refused.joined(separator: "\n\n"))
            }
        })
        present(ask, animated: true)
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }}
