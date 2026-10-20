//
//  AddBookViewController.swift
//  Assignment2
//
//  Created by Felix KHNEN on 20/10/2026.
//

import UIKit

class AddBookViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var bookIDField: UITextField!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var authorField: UITextField!
    @IBOutlet weak var categoryField: UITextField!
    @IBOutlet weak var dueInField: UITextField!
    var bookToEdit: Book?
    // Shown instead of the keyboard when the Category field is tapped.
    private let categoryPicker = UIPickerView()

    override func viewDidLoad() {
        super.viewDidLoad()

        categoryPicker.dataSource = self
        categoryPicker.delegate = self
        categoryField.inputView = categoryPicker
        categoryField.text = Category.all[0]

        dueInField.keyboardType = .numberPad

        // Tap anywhere on the background to close the keyboard or picker.
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        view.addGestureRecognizer(tap)
        // Edit mode: show the existing information so it can be updated.
        if let book = bookToEdit {
            title = "Edit Book"
            bookIDField.text = book.bookID
            bookIDField.isEnabled = false      // Book ID identifies the book, so it can't change
            bookIDField.alpha = 0.5
            titleField.text = book.title
            authorField.text = book.author
            categoryField.text = book.category
            dueInField.text = String(book.dueIn)
            if let row = Category.all.firstIndex(of: book.category ?? "") {
                categoryPicker.selectRow(row, inComponent: 0, animated: false)
            }
        }    }

    

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Category.all.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Category.all[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryField.text = Category.all[row]
    }

    

    @IBAction func saveTapped(_ sender: UIButton) {
        let bookID = clean(bookIDField)
        let title = clean(titleField)
        let author = clean(authorField)
        let category = clean(categoryField)
        let dueText = clean(dueInField)

        // Every field is required.
        guard !bookID.isEmpty, !title.isEmpty, !author.isEmpty,
              !category.isEmpty, !dueText.isEmpty else {
            showAlert("Missing information", "Please fill in every field.")
            return
        }

        // Due In must be a whole number of seconds greater than zero.
        guard let dueIn = Int64(dueText), dueIn > 0 else {
            showAlert("Invalid Due In", "Enter the loan period as a whole number of seconds, e.g. 60.")
            return
        }

        if let book = bookToEdit {
            // Editing an existing book.
            guard DataManager.shared.updateBook(book, title: title, author: author,
                                                category: category, dueIn: dueIn) else {
                showAlert("Error", "The changes could not be saved.")
                return
            }
        } else {
            // Adding a new book: Book IDs must be unique.
            guard DataManager.shared.findBook(bookID: bookID) == nil else {
                showAlert("Duplicate Book ID", "A book with ID \(bookID) already exists.")
                return
            }
            // addBook sets the status to Available automatically.
            guard DataManager.shared.addBook(bookID: bookID, title: title, author: author,
                                             category: category, dueIn: dueIn) != nil else {
                showAlert("Error", "The book could not be saved. Please try again.")
                return
            }
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
