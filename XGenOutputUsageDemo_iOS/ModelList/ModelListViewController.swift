//
//  ModelListViewController.swift
//  XGenOutputUsageDemo_iOS
//
//  Created by steven on 2023/1/22.
//

import UIKit
import SnapKit

class ModelListViewController: UIViewController {
    var selectModel: ((AIModel) -> Void)?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .custom
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var contentView: ModelListContentView!
}

extension ModelListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        initSubViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        show()
    }
}

private extension ModelListViewController {
    var infoHeight: CGFloat {
        return UIScreen.main.bounds.width * 885 / 750
    }
    
    func initSubViews() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        
        contentView = (Bundle.main.loadNibNamed("ModelListContentView", owner: nil, options: nil)?.first as? ModelListContentView)!
        view.addSubview(contentView)
        contentView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(view.snp.bottom)
            maker.height.equalTo(infoHeight)
        }
        contentView.alpha = 0
        contentView.cancelButton.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        contentView.selectModel = { [weak self] model in
            guard let self = self else { return }
            self.selectModel?(model)
            self.backPressed()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(backPressed))
        view.addGestureRecognizer(tap)
        tap.delegate = self
    }
    
    @objc func cancelButtonPressed() {
        dismissAction()
    }
    
    @objc func createButtonPressed() {
        dismissAction()
    }
    
    func show() {
        contentView.refreshButtonPressed()
        
        let trans = CGAffineTransform(translationX: 0, y: -infoHeight)
        UIView.animate(withDuration: 0.25) {
            self.contentView.transform = trans
            self.contentView.alpha = 1
        }
    }
    
    func dismissAction() {
        UIView.animate(withDuration: 0.25) {
            self.contentView.transform = .identity
            self.contentView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
    
    @objc func backPressed() {
        dismissAction()
    }
}

extension ModelListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: contentView)
        return !contentView.bounds.contains(point)
    }
}
