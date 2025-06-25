//
//  AlertManager.swift
//  MMAI-iOS
//
//  Created by vineet patidar on 19/08/24.
//

import UIKit

class AlertManager {
    
    static let shared = AlertManager()
    
    private init() {}
    
    func showAlert(
        on viewController: UIViewController,
        title: String?,
        message: String?,
        actions: [UIAlertAction] = [UIAlertAction(title: "OK", style: .default, handler: nil)],
        preferredStyle: UIAlertController.Style = .alert
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        
        for action in actions {
            alertController.addAction(action)
        }
        
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(
        on viewController: UIViewController,
        title: String?,
        message: String?,
        okActionTitle: String = "OK",
        preferredStyle: UIAlertController.Style = .alert,
        okActionHandler: (() -> Void)? = nil
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        
        let okAction = UIAlertAction(title: okActionTitle, style: .default) { _ in
            okActionHandler?() // Execute the callback if provided
        }
        
        alertController.addAction(okAction)
        
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    func showConfirmationAlert(
        on viewController: UIViewController,
        title: String?,
        message: String?,
        confirmAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil
    ) {
        let confirm = UIAlertAction(title: "Confirm", style: .default) { _ in
            confirmAction()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            cancelAction?()
        }
        
        showAlert(on: viewController, title: title, message: message, actions: [confirm, cancel])
    }
    
    func showDestructiveAlert(
        on viewController: UIViewController,
        title: String?,
        message: String?,
        destructiveTitle: String,
        destructiveAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil
    ) {
        let destructive = UIAlertAction(title: destructiveTitle, style: .destructive) { _ in
            destructiveAction()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            cancelAction?()
        }
        
        showAlert(on: viewController, title: title, message: message, actions: [destructive, cancel])
    }
    
    // New function to handle multiple actions
        func showMultipleActionsAlert(
            on viewController: UIViewController,
            title: String?,
            message: String?,
            actions: [(title: String, style: UIAlertAction.Style, handler: (() -> Void)?)]
        ) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            for action in actions {
                let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                    action.handler?()
                }
                alertController.addAction(alertAction)
            }
            
            viewController.present(alertController, animated: true, completion: nil)
        }
}
