//
//  ExtraKeysPopupView.swift
//  Keyboard
//
//  Created by Ville Petersson on 2018-03-21.
//  Copyright © 2018 Apple. All rights reserved.
//

import UIKit

class ExtraKeysPopupView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var collectionView: UICollectionView!
    
    var keys: [String] = []
    
    var activeIndex: Int = 0 {
        didSet {
            self.collectionView.reloadData()
        }
    }

    func setup() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 4
        flowLayout.minimumLineSpacing = 4

        self.collectionView = UICollectionView(frame: self.bounds.offsetBy(dx: 0, dy: 4), collectionViewLayout: flowLayout)
        self.collectionView.delegate = self
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.dataSource = self
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "extraKeyCell")
        self.addSubview(self.collectionView)

    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return keys.count
    }
    
    let labelTag = 99
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "extraKeyCell", for: indexPath)
        cell.viewWithTag(labelTag)?.removeFromSuperview()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 32, height: 40))
        label.tag = labelTag

        if indexPath.item == self.activeIndex {
            cell.contentView.backgroundColor = cell.tintColor
            cell.contentView.layer.cornerRadius = 4.0
            label.textColor = UIColor.white
        } else {
            cell.contentView.backgroundColor = UIColor.white
            label.textColor = UIColor.black
        }
        label.text = keys[indexPath.item]
        label.textAlignment = .center
        cell.addSubview(label)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 32, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
    
}
