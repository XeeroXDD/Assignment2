//
//  LoginViewController.swift
//  Assignment2
//
//  Created by Felix KHNEN on 19/10/2026.
//

import UIKit

// Remembers who is logged in so any screen can check the role.
class Session {
    static var currentUser: User?

    static var isAdmin: Bool {
        return currentUser?.role == Role.admin
    }
}

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        DataManager.shared.seedIfNeeded()

    }

    @IBAction func loginTapped(_ sender: UIButton) {
        let username = usernameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.text ?? ""

        // Empty-field validation before touching the database.
        guard !username.isEmpty, !password.isEmpty else {
            showAlert("Please enter both a username and a password.")
            return
        }

        // One generic message, so it never reveals which field was wrong.
        guard let user = DataManager.shared.login(username: username, password: password) else {
            showAlert("Incorrect username or password.")
            return
        }

        Session.currentUser = user
        passwordField.text = ""
        performSegue(withIdentifier: "showHome", sender: self)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Login failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
