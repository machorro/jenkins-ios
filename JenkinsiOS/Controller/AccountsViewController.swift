//
//  AccountsTableViewController.swift
//  JenkinsiOS
//
//  Created by Robert on 25.09.16.
//  Copyright © 2016 MobiLab Solutions. All rights reserved.
//

import UIKit

protocol CurrentAccountProviding {
    var account: Account? { get }
    var currentAccountDelegate: CurrentAccountProvidingDelegate? { get set }
}

protocol CurrentAccountProvidingDelegate: class {
    func didChangeCurrentAccount(current: Account)
}

class AccountsViewController: UIViewController, AccountProvidable, UITableViewDelegate, UITableViewDataSource,
    CurrentAccountProviding, AddAccountTableViewControllerDelegate {
    weak var currentAccountDelegate: CurrentAccountProvidingDelegate?

    @IBOutlet var tableView: UITableView!
    @IBOutlet var newAccountButton: BigButton!

    var account: Account?

    private var hasAccounts: Bool {
        return AccountManager.manager.accounts.isEmpty == false
    }

    private lazy var handler = { OnBoardingHandler() }()

    // MARK: - View controller lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = Constants.UI.backgroundColor

        navigationItem.rightBarButtonItem = editButtonItem

        title = "Accounts"

        tableView.backgroundColor = Constants.UI.backgroundColor
        tableView.tableHeaderView?.backgroundColor = Constants.UI.backgroundColor
        tableView.separatorStyle = .none

        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - newAccountButton.frame.maxY, right: 0)

        newAccountButton.addTarget(self, action: #selector(showAddAccountViewController), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.reloadData()
    }

    // MARK: - View controller navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Identifiers.editAccountSegue, let dest = segue.destination as? AddAccountTableViewController, let indexPath = sender as? IndexPath {
            prepare(viewController: dest, indexPath: indexPath)
        } else if let dest = segue.destination as? AddAccountTableViewController {
            dest.delegate = self
        }

        navigationController?.isToolbarHidden = true
    }

    fileprivate func prepare(viewController: UIViewController, indexPath: IndexPath) {
        if let addAccountViewController = viewController as? AddAccountTableViewController {
            addAccountViewController.account = AccountManager.manager.accounts[indexPath.row]
            addAccountViewController.delegate = self
        }
    }

    @objc func showAddAccountViewController() {
        performSegue(withIdentifier: Constants.Identifiers.editAccountSegue, sender: nil)
    }

    func didEditAccount(account: Account) {
        if account.baseUrl == self.account?.baseUrl {
            // The current account was edited
            currentAccountDelegate?.didChangeCurrentAccount(current: account)
        }

        navigationController?.popViewController(animated: true)
    }

    // MARK: - Tableview datasource and delegate

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Identifiers.accountCell, for: indexPath) as! BasicTableViewCell

        let account = AccountManager.manager.accounts[indexPath.row]

        cell.title = AccountManager.manager.accounts[indexPath.row].displayName ?? account.baseUrl.absoluteString

        if isEditing {
            cell.nextImageType = .next
            cell.selectionStyle = .default
        } else {
            cell.nextImageType = account.baseUrl == self.account?.baseUrl ? .checkmark : .none
            cell.selectionStyle = .none
        }

        return cell
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return AccountManager.manager.accounts.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAccount = AccountManager.manager.accounts[indexPath.row]

        if isEditing {
            performSegue(withIdentifier: Constants.Identifiers.editAccountSegue, sender: indexPath)
        } else if selectedAccount.baseUrl != account?.baseUrl {
            account = selectedAccount
            currentAccountDelegate?.didChangeCurrentAccount(current: selectedAccount)
            AccountManager.manager.currentAccount = selectedAccount
            tableView.reloadSections([0], with: .automatic)
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        return hasAccounts ? 1 : 0
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && !hasAccounts {
            return 0
        }

        return 44
    }

    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        return true
    }

    func tableView(_: UITableView, editingStyleForRowAt _: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_: UITableView, shouldIndentWhileEditingRowAt _: IndexPath) -> Bool {
        return false
    }

    func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return [
            UITableViewRowAction(style: .destructive, title: "Delete", handler: { _, indexPath in
                self.deleteAccount(at: indexPath)
            }),
            UITableViewRowAction(style: .normal, title: "Edit", handler: { _, indexPath in
                self.performSegue(withIdentifier: Constants.Identifiers.editAccountSegue, sender: indexPath)
            }),
        ]
    }

    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt _: IndexPath) {
        cell.backgroundColor = .clear
    }

    private func deleteAccount(at indexPath: IndexPath) {
        do {
            try AccountManager.manager.deleteAccount(account: AccountManager.manager.accounts[indexPath.row])
            tableView.reloadData()

            if AccountManager.manager.accounts.isEmpty && handler.shouldShowAccountCreationViewController() {
                let navigationController = UINavigationController()
                present(navigationController, animated: false, completion: nil)
                handler.showAccountCreationViewController(on: navigationController, delegate: self)
            }
        } catch {
            displayError(title: "Error", message: "Something went wrong", textFieldConfigurations: [], actions: [
                UIAlertAction(title: "Alright", style: .cancel, handler: nil),
            ])
            tableView.reloadData()
        }
    }
}

extension AccountsViewController: OnBoardingDelegate {
    func didFinishOnboarding(didAddAccount _: Bool) {
        dismiss(animated: true, completion: nil)
    }
}
