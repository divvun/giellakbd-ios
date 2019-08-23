//
//  LongPressController.swift
//  RewriteKeyboard
//
//  Created by Ville Petersson on 2019-07-08.
//  Copyright © 2019 The Techno Creatives AB. All rights reserved.
//

import UIKit

protocol LongPressControllerDelegate {
    
    func longpress(didCreateOverlayContentView contentView: UIView)
    func longpressDidCancel()
    func longpress(didSelectKey key: KeyDefinition)
    
    func longpressFrameOfReference() -> CGRect
    func longpressKeySize() -> CGSize
}

class LongPressController: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    class LongpressCollectionView: UICollectionView {}
    
    static let multirowThreshold = 3
    
    private let deadZone: CGFloat = 20.0
    
    let key: KeyDefinition
    let longpressValues: [KeyDefinition]
    
    private var baselinePoint: CGPoint?
    private var collectionView: UICollectionView?
    
    private let reuseIdentifier = "longpressCell"
    
    private var selectedKey: KeyDefinition? {
        didSet {
            if selectedKey?.type != oldValue?.type {
                self.collectionView?.reloadData()
            }
        }
    }
    
    var delegate: LongPressControllerDelegate?
    
    init(key: KeyDefinition, longpressValues: [KeyDefinition]) {
        self.key = key
        self.longpressValues = longpressValues
    }
    
    private func setup() {
        self.collectionView = LongpressCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout.init())
        self.collectionView?.register(LongpressKeyCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        self.collectionView?.backgroundColor = .clear
        
        if let delegate = self.delegate {
            delegate.longpress(didCreateOverlayContentView: self.collectionView!)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func touchesBegan(_ point: CGPoint) {
        if baselinePoint == nil {
            baselinePoint = point
            setup()
        }
        pointUpdated(point)
    }
    
    public func touchesMoved(_ point: CGPoint) {
        if baselinePoint == nil {
            baselinePoint = point
            setup()
        }
        pointUpdated(point)
    }
    
    public func touchesEnded(_ point: CGPoint) {
        pointUpdated(point)
        
        if let selectedKey = self.selectedKey {
            delegate?.longpress(didSelectKey: selectedKey)
        } else {
            delegate?.longpressDidCancel()
        }
    }
    
    private func pointUpdated(_ point: CGPoint) {
        let cellSize = self.delegate?.longpressKeySize() ?? CGSize(width: 20, height: 30.0)
        let bigFrame = delegate!.longpressFrameOfReference()
        var superView: UIView? = collectionView
        
        repeat {
            superView = superView?.superview
        } while (superView?.bounds != bigFrame && superView != nil)
        
        guard let wholeView = superView else { return }
        guard let collectionView = self.collectionView else { return }
        
        let frame = wholeView.convert(collectionView.frame, from: collectionView.superview)
        
        // TODO: Logic for multiline popups
        if let indexPath = collectionView.indexPathForItem(at: CGPoint(x: min(max(point.x - frame.minX, collectionView.bounds.minX + cellSize.width/2.0), collectionView.bounds.maxX - cellSize.width/2.0),
                                                                       y: min(max(point.y - (baselinePoint?.y ?? 0), collectionView.bounds.minY + cellSize.height/2.0), collectionView.bounds.maxY - cellSize.height/2.0))) {
            self.selectedKey = longpressValues[indexPath.row + Int(ceil(Double(longpressValues.count) / 2.0)) * indexPath.section]
        } else {
            self.selectedKey = nil

            // TODO: Logic for canceling it
            if false {
                delegate?.longpressDidCancel()
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return longpressValues.count >= LongPressController.multirowThreshold ? 2 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if longpressValues.count >= LongPressController.multirowThreshold {
            return section == 0 ? Int(ceil(Double(longpressValues.count) / 2.0)) : Int(floor(Double(longpressValues.count) / 2.0))
        }
        return longpressValues.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LongpressKeyCell
        let key = longpressValues[indexPath.row + Int(ceil(Double(longpressValues.count) / 2.0)) * indexPath.section]
        
        if case let .input(string) = key.type {
            cell.label.text = string
        } else {
            print("ERROR: Non-input key type in longpress")
        }
        
        cell.isSelectedKey = key.type == self.selectedKey?.type
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.delegate?.longpressKeySize() ?? CGSize(width: 20, height: 30.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellSize = self.delegate?.longpressKeySize() ?? CGSize(width: 20, height: 30.0)
        let cellWidth = cellSize.width
        let numberOfCells = CGFloat(longpressValues.count)
        
        guard numberOfCells <= 1 else { return .zero }
        
        // Center single cells
        let edgeInsets = (collectionView.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
        return UIEdgeInsets(top: 0, left: edgeInsets, bottom: 0, right: edgeInsets)
    }
    
    
    class LongpressKeyCell: UICollectionViewCell {
        let label: UILabel
        var isSelectedKey: Bool = false {
            didSet {
                label.textColor = isSelectedKey ? KeyboardView.theme.activeTextColor : KeyboardView.theme.textColor
                label.backgroundColor = isSelectedKey ? KeyboardView.theme.activeColor : KeyboardView.theme.popupColor
            }
        }
        
        override init(frame: CGRect) {
            label = UILabel(frame: frame)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.layer.cornerRadius = KeyboardView.theme.keyCornerRadius
            label.clipsToBounds = true
            super.init(frame: frame)
            self.addSubview(label)
            label.fillSuperview(self)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
