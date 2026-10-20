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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Business rule: only admins can add books, so hide "+" for borrowers.
        if !Session.isAdmin {
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
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            guard Session.isAdmin else { return }   // borrowers can only browse

            let book = sections[indexPath.section].books[indexPath.row]
            guard let editor = storyboard?.instantiateViewController(withIdentifier: "AddBookVC")
                    as? AddBookViewController else { return }
            editor.bookToEdit = book
            navigationController?.pushViewController(editor, animated: true)
        }}
