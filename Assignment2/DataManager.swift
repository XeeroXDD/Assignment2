//
//  DataManager.swift
//  Assignment2
//
//  Created by Felix KHNEN on 9/10/2026.
//

import UIKit

import CoreData

enum Role {
    static let admin = "admin"
    static let borrower = "borrower"
}

 

enum BookStatus {
    static let available = "Available"
    static let onLoan = "On Loan"
    static let overdue = "Overdue"
    static let onHold = "On Hold"
}

enum Category {

    static let all = ["Reference", "Fiction", "Non-fiction"]

}
 
class DataManager {

    // Singleton: one shared instance for the whole app.
    static let shared = DataManager()
    private init() {}
    // The context is the "scratchpad" where objects are created, changed and

    // fetched. Nothing is written to disk until save() is called.
    private var context: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    // Writes pending changes to the SQLite store.

    // Returns false instead of crashing if the save fails.

    @discardableResult

    func save() -> Bool {
        guard context.hasChanges else { return true }
        do {
            try context.save()
            return true
        } catch {
            print("Save failed: \(error)")
            context.rollback()
            return false
        }
    }

    func findUser(username: String) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "username ==[c] %@", username)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

 

    // Returns nil if the username is already taken (business rule: unique usernames).

    func addUser(name: String, username: String, password: String,
                 address: String, role: String) -> User? {
        guard findUser(username: username) == nil else { return nil }

        let user = User(context: context)
        user.name = name
        user.username = username
        user.password = password
        user.address = address
        user.role = role
        return save() ? user : nil
    }

 

    // Returns the matching user, or nil for any failure.

    // The caller shows one generic error, so it never reveals which field was wrong.

    func login(username: String, password: String) -> User? {
        guard let user = findUser(username: username),
              user.password == password else { return nil }
        return user
    }

    func fetchBorrowers() -> [User] {

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "role == %@", Role.borrower)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (try? context.fetch(request)) ?? []

    }

    func findBook(bookID: String) -> Book? {
        let request: NSFetchRequest<Book> = Book.fetchRequest()
        request.predicate = NSPredicate(format: "bookID ==[c] %@", bookID)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

 

    // Returns nil if the Book ID is already used (business rule: unique Book IDs).

    // A new book always starts as Available.

    func addBook(bookID: String, title: String, author: String,
                 category: String, dueIn: Int64) -> Book? {
        guard findBook(bookID: bookID) == nil else { return nil }

 

        let book = Book(context: context)
        book.bookID = bookID
        book.title = title
        book.author = author
        book.category = category
        book.dueIn = dueIn
        book.status = BookStatus.available

        return save() ? book : nil

    }
 
    // Whole catalogue, sorted by category and then by title within each category.
    func fetchBooks() -> [Book] {

        let request: NSFetchRequest<Book> = Book.fetchRequest()

        request.sortDescriptors = [
            NSSortDescriptor(key: "category", ascending: true),
            NSSortDescriptor(key: "title", ascending: true,
                             selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        return (try? context.fetch(request)) ?? []

    }

    // Books that can be borrowed right now, sorted by category then title.
    func fetchAvailableBooks() -> [Book] {
        return fetchBooks().filter { $0.status == BookStatus.available }
    }

    // Creates one transaction for a borrower with one LoanItem per book.
    // Each book's due date is calculated automatically from its Due In seconds,
    // and its status changes to On Loan (business rules).
    func createTransaction(borrower: User, books: [Book]) -> BorrowTransaction? {
        // Business rule: a transaction needs at least one book.
        guard !books.isEmpty else { return nil }

        let now = Date()
        let transaction = BorrowTransaction(context: context)
        transaction.id = UUID()	
        transaction.dateCreated = now
        transaction.borrower = borrower

        for book in books {
            let item = LoanItem(context: context)
            item.book = book
            item.transaction = transaction
            item.requestedDate = now
            item.dueDate = now.addingTimeInterval(TimeInterval(book.dueIn))
            item.status = BookStatus.onLoan

            book.status = BookStatus.onLoan
        }

        return save() ? transaction : nil
    }
    func seedIfNeeded() {
        let request: NSFetchRequest<User> = User.fetchRequest()
        let userCount = (try? context.count(for: request)) ?? 0
        guard userCount == 0 else { return }

 

        _ = addUser(name: "Administrator", username: "admin", password: "admin123",
                    address: "169 Macquarie St, Parramatta NSW 2150", role: Role.admin)
        _ = addUser(name: "Alice Nguyen", username: "alice", password: "alice123",
                    address: "1 Martin Place, Sydney NSW 2000", role: Role.borrower)
        _ = addUser(name: "Ben Carter", username: "ben", password: "ben123",
                    address: "100 George St, Parramatta NSW 2150", role: Role.borrower)
 

        // dueIn is in seconds; short values make overdue easy to show in the demo.
        _ = addBook(bookID: "B001", title: "Oxford Dictionary", author: "Oxford Press",
                    category: "Reference", dueIn: 60)
        _ = addBook(bookID: "B002", title: "World Atlas", author: "National Geographic",
                    category: "Reference", dueIn: 60)
        _ = addBook(bookID: "B003", title: "Dune", author: "Frank Herbert",
                    category: "Fiction", dueIn: 120)
        _ = addBook(bookID: "B004", title: "The Hobbit", author: "J.R.R. Tolkien",
                    category: "Fiction", dueIn: 120)
        _ = addBook(bookID: "B005", title: "Sapiens", author: "Yuval Noah Harari",
                    category: "Non-fiction", dueIn: 300)
        _ = addBook(bookID: "B006", title: "Educated", author: "Tara Westover",
                    category: "Non-fiction", dueIn: 300)

    }
    
    func updateBook(_ book: Book, title: String, author: String,
                    category: String, dueIn: Int64) -> Bool {
        book.title = title
        book.author = author
        book.category = category
        book.dueIn = dueIn
        return save()
    }
}

 

