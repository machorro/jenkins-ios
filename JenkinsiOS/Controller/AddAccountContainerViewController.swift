//
//  AddAccountContainerViewController.swift
//  JenkinsiOS
//
//  Created by Robert on 05.11.18.
//  Copyright © 2018 MobiLab Solutions. All rights reserved.
//

import UIKit

protocol VerificationFailureNotifying: class {
    var verificationFailurePresenter: VerificationFailurePresenting? { get set }
}

protocol DoneButtonContaining: class {
    func setDoneButton(enabled: Bool)
    func setDoneButton(title: String)
    func setDoneButton(alpha: CGFloat)
    func tableViewOffsetForDoneButton() -> CGFloat
    func doneButtonFrame() -> CGRect
}

class AddAccountContainerViewController: UIViewController, VerificationFailurePresenting, AccountProvidable {
    var account: Account?
    var editingCurrentAccount = false
    var addingFirstAccount = false

    var delegate: AddAccountTableViewControllerDelegate?
    var doneButtonEventReceiver: DoneButtonEventReceiving?

    @IBOutlet private var doneButton: BigButton!

    private var errorBanner: ErrorBanner?

    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if var dest = segue.destination as? AccountProvidable {
            dest.account = account
        }

        if let dest = segue.destination as? VerificationFailureNotifying {
            dest.verificationFailurePresenter = self
        }

        if let addAccountViewController = segue.destination as? AddAccountTableViewController {
            addAccountViewController.delegate = delegate
            addAccountViewController.isCurrentAccount = editingCurrentAccount
            addAccountViewController.isFirstAccount = addingFirstAccount
            addAccountViewController.doneButtonContainer = self
            doneButtonEventReceiver = addAccountViewController
        }
    }

    func showVerificationFailure(error: Error) {
        let banner = ErrorBanner()

        switch error {
        case let NetworkManagerError.HTTPResponseNoSuccess(code, _) where code == 401 || code == 403:
            banner.errorDetails = "The username or password entered are incorrect.\nPlease confirm that the values are correct"
        case let
            NetworkManagerError
                .HTTPResponseNoSuccess(code, _) where code == 404:
            banner.errorDetails = "The hostname entered is incorrect.\nPlease enter a correct one"
        case let NetworkManagerError.HTTPResponseNoSuccess(code, _) where code == -1003:
            banner.errorDetails = "A server with the specified hostname could not be found"
        default:
            banner.errorDetails = "Something failed!\nPlease confirm that the fields below are filled correctly"
        }
        if let error = error as? NSError {
            if error.code == -1003{
                banner.errorDetails = "A server with the specified hostname could not be found"
            }
        }
        view.addSubview(banner)

        banner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            banner.leftAnchor.constraint(equalTo: view.leftAnchor),
            banner.rightAnchor.constraint(equalTo: view.rightAnchor),
            banner.widthAnchor.constraint(equalTo: view.widthAnchor),
            banner.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
        ])

        errorBanner = banner
    }

    func hideVerificationFailure() {
        hideErrorBanner()
    }

    @objc private func doneButtonPressed() {
        doneButtonEventReceiver?.doneButtonPressed()
    }

    private func hideErrorBanner() {
        guard let errorBanner = errorBanner
        else { return }

        errorBanner.layoutIfNeeded()
        errorBanner.heightAnchor.constraint(equalToConstant: 0).isActive = true

        UIView.animate(withDuration: 0.1, animations: {
            errorBanner.layoutIfNeeded()
            errorBanner.alpha = 0.2
        }) { _ in
            errorBanner.removeFromSuperview()
            self.errorBanner = nil
        }
    }
}

extension AddAccountContainerViewController: DoneButtonContaining {
    func setDoneButton(enabled: Bool) {
        doneButton.isEnabled = enabled
    }

    func setDoneButton(title: String) {
        doneButton.setTitle(title, for: .normal)
    }

    func setDoneButton(alpha: CGFloat) {
        doneButton.alpha = alpha
    }

    func tableViewOffsetForDoneButton() -> CGFloat {
        return (doneButton.superview?.frame.minY ?? 0) - view.frame.height - UIApplication.shared.statusBarFrame.height
    }

    func doneButtonFrame() -> CGRect {
        return doneButton.convert(doneButton.bounds, to: children.first?.view)
    }
}
