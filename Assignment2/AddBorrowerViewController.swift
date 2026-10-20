//
//  AddBorrowerViewController.swift
//  Assignment2
//
//  Created by Felix KHNEN on 20/10/2026.
//

import UIKit

class AddBorrowerViewController: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var addressField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Tap anywhere on the background to close the keyboard.
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        view.addGestureRecognizer(tap)
    }

    @IBAction func saveTapped(_ sender: UIButton) {
        let name = clean(nameField)
        let username = clean(usernameField)
        let password = passwordField.text ?? ""
        let address = clean(addressField)

        // All four fields are required.
        guard !name.isEmpty, !username.isEmpty, !password.isEmpty, !address.isEmpty else {
            showAlert("Missing information", "Please fill in every field.")
            return
        }

        // Usernames can't contain spaces.
        guard !username.contains(" ") else {
            showAlert("Invalid username", "Usernames can't contain spaces.")
            return
        }

        // Basic password rule so blank-looking passwords aren't allowed.
        guard password.trimmingCharacters(in: .whitespaces).count >= 4 else {
            showAlert("Weak password", "Passwords must be at least 4 characters.")
            return
        }

        // Business rule: usernames must be unique.
        guard DataManager.shared.findUser(username: username) == nil else {
            showAlert("Username taken", "The username \"\(username)\" is already in use.")
            return
        }

        guard DataManager.shared.addUser(name: name, username: username, password: password,
                                         address: address, role: Role.borrower) != nil else {
            showAlert("Error", "The borrower could not be saved. Please try again.")
            return
        }

        navigationController?.popViewController(animated: true)
    }

    private func clean(_ field: UITextField) -> String {
        return field.text?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
