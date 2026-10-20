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
}
