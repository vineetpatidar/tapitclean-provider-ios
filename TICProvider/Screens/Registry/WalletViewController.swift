//
//  WalletViewController.swift
//  TICProvider
//
//  Created by vineet patidar on 07/09/25.
//

import UIKit

class WalletViewController: BaseViewController,Storyboarded {
    @IBOutlet weak var lblCredit: UILabel!
    var coordinator: MainCoordinator?
    var appDelegate : AppDelegate?
    var walletViewModel = WalletViewModel()
    @IBOutlet weak var tblView: UITableView!
    
    // NEW: UI elements for refresh & footer loading
    private let refreshControl = UIRefreshControl()
    private let footerSpinner = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lblCredit.text = "\(CurrentUserInfo.totalCredit ?? 0)"
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        if((self.navigationController?.viewControllers.count)! >= 2){
            setNavWithOutView(.back)
        }
        else{
            setNavWithOutView(.menu)
        }
        
        WalletCell.registerWithTable(tblView)
        tblView.rowHeight = UITableView.automaticDimension
        tblView.estimatedRowHeight = 142
        tblView.delegate = self
        tblView.showsVerticalScrollIndicator = false
        tblView.showsHorizontalScrollIndicator = false
        
        // Pull-to-refresh
        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        tblView.refreshControl = refreshControl

        // Footer spinner for “load more”
        footerSpinner.hidesWhenStopped = true
        tblView.tableFooterView = footerSpinner
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        walletViewModel.resetPagination()
        self.getWalletInfo()
    }
    
    @IBAction func btnCouponCode_Clicked(_ sender: Any) {
        coordinator?.goToCouponCodeView()
    }
    
    // MARK: - Fetching

    @objc private func onPullToRefresh() {
        walletViewModel.resetPagination()
        getWalletInfo(showLoader: false)
    }
    
    private func getWalletInfo(showLoader:Bool = true) {
        let endpoint = APIsEndPoints.kwalletRequest.rawValue
        walletViewModel.getWallet(apiEndPoint: endpoint, showLoader: showLoader) { [weak self] (result: Result<WalletDriverResponse, WalletError>) in
            guard let self = self else { return }
            self.footerSpinner.stopAnimating()
            self.refreshControl.endRefreshing()
            
            switch result {
            case .success(_):
                // Update header UI
                self.lblCredit.text = walletViewModel.totalCreditText
                // Reload table with transactions
                self.tblView.reloadData()
            case .failure(let err):
                print("Wallet fetch failed:", err)
            }
        }
    }
    
    /// Call when user scrolls near bottom
    private func loadMoreIfNeeded(for indexPath: IndexPath) {
        let lastIndex = walletViewModel.transactions.count - 1
        guard lastIndex >= 0 else { return }
        if indexPath.row == lastIndex, !walletViewModel.reachedEnd{
            footerSpinner.startAnimating()
            getWalletInfo(showLoader:false)
        }     
    }
}

// UITableViewDataSource
extension WalletViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return walletViewModel.transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < walletViewModel.transactions.count,
                  let cell = tableView.dequeueReusableCell(withIdentifier: WalletCell.reuseIdentifier,
                                                           for: indexPath) as? WalletCell
            else {
                return UITableViewCell()
            }

            cell.selectionStyle = .none
            let transaction = walletViewModel.transactions[indexPath.row]
            cell.commonInit(transaction, indexPath.row + 1)
            return cell
    }
}

// MARK: - UITableViewDelegate (pagination trigger)
extension WalletViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        loadMoreIfNeeded(for: indexPath)
    }
}
