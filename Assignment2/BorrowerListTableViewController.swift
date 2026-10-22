//
//  BorrowerListTableViewController.swift
//  Assignment2
//
//  Created by Felix KHNEN on 20/10/2026.
//
import UIKit

class BorrowerListViewController: UITableViewController {

    private var borrowers: [User] = []
    
    // Buttons for Select mode.
    private var addButton: UIBarButtonItem?
    private lazy var selectButton = UIBarButtonItem(title: "Select", style: .plain,
                                                    target: self, action: #selector(toggleSelectMode))
    private lazy var deleteButton = UIBarButtonItem(title: "Delete", style: .plain,
                                                    target: self, action: #selector(deleteSelected))

    override func viewDidLoad() {
        super.viewDidLoad()
        addButton = navigationItem.rightBarButtonItem        // the "+" from the storyboard
        navigationItem.leftItemsSupplementBackButton = true   // keep the back arrow
        navigationItem.leftBarButtonItem = selectButton
        deleteButton.tintColor = .systemRed
        tableView.allowsMultipleSelectionDuringEditing = true
    }
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
    // Tapping a borrower: ticks them in Select mode, otherwise opens their details.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateDeleteButton()
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        performSegue(withIdentifier: "showBorrowerDetail", sender: cell)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showBorrowerDetail",
              let detail = segue.destination as? BorrowerDetailViewController,
              let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        detail.borrower = borrowers[indexPath.row]
    }
    // MARK: - Select mode (single and bulk delete)

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

    // Shows how many borrowers are ticked, e.g. "Delete (2)".
    private func updateDeleteButton() {
        let count = tableView.indexPathsForSelectedRows?.count ?? 0
        deleteButton.title = count > 0 ? "Delete (\(count))" : "Delete"
        deleteButton.isEnabled = count > 0
    }

    // Deletes every ticked borrower, skipping any with books still on loan.
    @objc func deleteSelected() {
        let selected = (tableView.indexPathsForSelectedRows ?? []).map { borrowers[$0.row] }
        guard !selected.isEmpty else { return }

        let ask = UIAlertController(title: "Delete \(selected.count) borrower(s)?",
                                    message: "Their returned transactions are deleted too. This can't be undone.",
                                    preferredStyle: .alert)
        ask.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ask.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            var deleted = 0
            var refused: [String] = []
            for borrower in selected {
                if let problem = DataManager.shared.deleteUser(borrower) {
                    refused.append(problem)
                } else {
                    deleted += 1
                }
            }

            self.toggleSelectMode()
            self.viewWillAppear(false)   // reloads the list from the database

            if !refused.isEmpty {
                self.showAlert("Deleted \(deleted) borrower(s)", refused.joined(separator: "\n\n"))
            }
        })
        present(ask, animated: true)
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }}
