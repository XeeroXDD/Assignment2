//
//  HomeViewController.swift
//  Assignment2
//
//  Created by Felix KHNEN on 19/10/2026.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var adminLabel: UILabel!
    @IBOutlet weak var manageBorrowersButton: UIButton!

    // Runs every time Home appears, so it always matches the logged-in user.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        welcomeLabel.text = "Welcome, \(Session.currentUser?.name ?? "")"

        // Borrowers must not see admin-only options.
        adminLabel.isHidden = !Session.isAdmin
        manageBorrowersButton.isHidden = !Session.isAdmin
    }

    @IBAction func logoutTapped(_ sender: UIBarButtonItem) {
        Session.currentUser = nil
        dismiss(animated: true)   // Back to the Login screen
    }
}
