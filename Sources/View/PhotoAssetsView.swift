//
//  PhotoAssetsView.swift
//  SwiftyPhotos
//
//  Created by Chris Hu on 24/05/2018.
//  Copyright © 2018 com.icetime. All rights reserved.
//

import UIKit
import Photos


public protocol PhotoAssetsViewDelegate: class {
    func PhotoAssetsViewDidSelectPhotoInAlbum(_ photoAlbum: PhotoAlbumModel, at indexPath: IndexPath)
}


public class PhotoAssetsView: UIView {
    
    public weak var delegate: PhotoAssetsViewDelegate?
    
    // album
    fileprivate var photoAlbum: PhotoAlbumModel
    
    // whether to keep photo ratio
    fileprivate let isKeepingPhotoRatio: Bool
    fileprivate var photoRatios = [CGFloat]()
    
    // cell count of one line
    fileprivate let cellCountOfLine: Int
    // offset between cells
    fileprivate let cellOffset: CGFloat
    
    public lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = self.cellOffset
        layout.minimumLineSpacing = self.cellOffset
        
        // in case items can not be displayed in one line
        let itemWidth = (self.frame.width - self.cellOffset * CGFloat(self.cellCountOfLine - 1) - 1.0) / CGFloat(self.cellCountOfLine)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        let cv: UICollectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.white
        
        cv.register(PhotoAssetsCell.classForCoder(), forCellWithReuseIdentifier: "PhotoAssetsCell")
        
        cv.dataSource = self
        cv.delegate = self
        
        return cv
    }()
    
    public init(frame: CGRect, photoAlbum: PhotoAlbumModel, isKeepingPhotoRatio: Bool, cellCountOfLine: Int, cellOffset: CGFloat) {
        self.photoAlbum = photoAlbum
        self.isKeepingPhotoRatio = isKeepingPhotoRatio
        self.cellCountOfLine = cellCountOfLine
        self.cellOffset = cellOffset
        
        super.init(frame: frame)
        
        self.photoAlbum.delegate = self
        
        if self.isKeepingPhotoRatio {
            self.setupPhotoRatios()
        }
        
        self.addSubview(self.collectionView)
        
        self.scrollsToBottom()
    }
    
    public func reload(_ photoAlbum: PhotoAlbumModel) {
        self.photoAlbum = photoAlbum
        self.collectionView.reloadData()
        
        self.scrollsToBottom()
    }
    
    private func scrollsToBottom() {
        let count = self.photoAlbum.photoAssets.count
        if count > 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.collectionView.scrollToItem(at: IndexPath(item: count - 1, section: 0), at: .centeredVertically, animated: false)
            })
        }
    }
    
    fileprivate func setupPhotoRatios() {
        self.photoRatios.removeAll()
        for (_, photoAsset) in self.photoAlbum.photoAssets.enumerated() {
            self.photoRatios.append(photoAsset.photoSize.height / photoAsset.photoSize.width)
        }
        
        let lineCount = self.photoRatios.count / self.cellCountOfLine
        for i in 0 ..< lineCount {
            var arr = [CGFloat]()
            for j in 0 ..< self.cellCountOfLine {
                arr.append(self.photoRatios[self.cellCountOfLine * i + j])
            }
            let finalRatio = self._maxValueForAll(arr: arr)
            for k in 0 ..< self.cellCountOfLine {
                self.photoRatios[self.cellCountOfLine * i + k] = finalRatio
            }
        }
        
        let others = self.photoRatios.count % self.cellCountOfLine
        if others > 1 {
            var arr = [CGFloat]()
            for i in 0 ..< others {
                arr.append(self.photoRatios[self.cellCountOfLine * lineCount + i])
            }
            let finalRatio = self._maxValueForAll(arr: arr)
            for j in 0 ..< others {
                self.photoRatios[self.cellCountOfLine * lineCount + j] = finalRatio
            }
        }
    }
    
    private func _maxValueForAll(arr: [CGFloat]) -> CGFloat {
        var maxValue: CGFloat = 0.0
        for (_, v) in arr.enumerated() {
            if v > maxValue {
                maxValue = v
            }
        }
        return maxValue
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UICollectionViewDataSource

extension PhotoAssetsView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoAlbum.photoAssets.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAssetsCell", for: indexPath) as! PhotoAssetsCell
        
        cell.isKeepingPhotoRatio = self.isKeepingPhotoRatio
        
        cell.photoAsset = self.photoAlbum.photoAssets[indexPath.item]
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension PhotoAssetsView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.PhotoAssetsViewDidSelectPhotoInAlbum(self.photoAlbum, at: indexPath)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension PhotoAssetsView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // in case items can not be displayed in one line
        let itemWidth = (collectionView.frame.width - self.cellOffset * CGFloat(self.cellCountOfLine - 1) - 1.0) / CGFloat(self.cellCountOfLine)
        
        // height for photo
        var itemHeight: CGFloat
        if self.isKeepingPhotoRatio {
            itemHeight = itemWidth * self.photoRatios[indexPath.item]
        } else {
            itemHeight = itemWidth
        }
        
        return CGSize(width: itemWidth, height: CGFloat(itemHeight))
    }
}

// MARK: - PhotoAlbumDelegate

extension PhotoAssetsView: PhotoAlbumDelegate {
    public func PhotoAlbumChangeWithDetails(_ changeDetails: PHFetchResultChangeDetails<PHAsset>) {
        if self.isKeepingPhotoRatio {
            self.setupPhotoRatios()
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}
