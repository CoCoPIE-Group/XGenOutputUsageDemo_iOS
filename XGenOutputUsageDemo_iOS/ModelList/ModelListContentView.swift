//
//  ModelListContentView.swift
//  XGenOutputUsageDemo_iOS
//
//  Created by steven on 2023/1/22.
//

import UIKit
import Toast_Swift

class ModelListContentView: UIView {
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var refreshButton: UIButton!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    private let cellID = "ModelListNameTableViewCell"
    
    private var list: [AIModel] = []
    
    var selectModel: ((AIModel) -> Void)?
    
    @IBAction func refreshButtonPressed() {
        refreshButton.isHidden = true
        indicator.isHidden = false
        indicator.startAnimating()
        
        ResourceLoadManager.default.requestList { [weak self] list in
            guard let self = self else { return }
            
            self.refreshButton.isHidden = false
            self.indicator.stopAnimating()
            self.indicator.isHidden = true
            
            guard let list else {
                self.makeToast("load failed, please retry later", position: .center)
                return
            }
            
            self.list = [ResourceLoadManager.default.localModel] + list
            self.tableView.reloadData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tableView.register(ModelListNameTableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: C.Distance.safeAreaEdgeInsets.bottom, right: 0)
        
        indicator.isHidden = true
    }
}

extension ModelListContentView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = list[indexPath.row]
        selectModel?(model)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID)
        let model = list[indexPath.row]
        (cell as? ModelListNameTableViewCell)?.nameLabel.text = model.name
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
