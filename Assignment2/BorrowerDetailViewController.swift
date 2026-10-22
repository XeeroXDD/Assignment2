//
//  BorrowerDetailViewController.swift
//  Assignment2
//
//  Created by Felix KHNEN on 20/10/2026.
//

import UIKit

class BorrowerDetailViewController: UIViewController {

    @IBOutlet weak var detailsLabel: UILabel!

    // Set by the borrower list before this screen opens.
    var borrower: User?
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = borrower?.name

        guard let borrower = borrower else { return }
        detailsLabel.text = """
        Name
        \(borrower.name ?? "")

        Username
        \(borrower.username ?? "")

        Password
        ••••••

        Address
        \(borrower.address ?? "")
        """
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // "Edit" in the top-right corner.
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain,
                                                            target: self, action: #selector(editTapped))
    }

    // Opens the Add Borrower form in edit mode for this borrower.
    @objc func editTapped() {
        guard let borrower = borrower,
              let editor = storyboard?.instantiateViewController(withIdentifier: "AddBorrowerVC")
                as? AddBorrowerViewController else { return }
        editor.borrowerToEdit = borrower
        navigationController?.pushViewController(editor, animated: true)
    }
}
