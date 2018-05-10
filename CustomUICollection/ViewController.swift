//
//  ViewController.swift
//  CustomUICollection
//
//  Created by ls on 2018/5/8.
//  Copyright © 2018年 ls. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    
    var myCollectionView: UICollectionView!
    var itemHeaders = [String]()
    var itemNames: Dictionary<Int, [String]>!
    var dragingIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        initUI()
    }
}
//MARK: - data
extension ViewController {
    func initData() {
        itemHeaders = ["我的频道","频道推荐"]
        itemNames = [0: [String](["关注","推荐","视频","热点","北京","新时代","图片","头条号","娱乐","问答","体育","科技","懂车帝","财经","军事","国际"]),1: [String](["健康","冬奥","特产","房产","小说","时尚","历史","育儿","直播","搞笑","数码","美食","养生","电影","手机","旅游","宠物","情感"])]
        
    }
}
//MARK: - UI
extension ViewController {
    func initUI() {
        //计算单个Item的大小
        let width: CGFloat = (self.view.frame.width -  5 * 10) / 4
        let height: CGFloat = 40
        
        let flowLayout = UICollectionViewFlowLayout()
        //滚动方向
        flowLayout.scrollDirection = .vertical
        //网格中各行项目之间使用的最小间距
        flowLayout.minimumLineSpacing = 10
        //在同一行中的项目之间使用的最小间距
        flowLayout.minimumInteritemSpacing = 10
        //用于单元格的默认大小
        flowLayout.itemSize = CGSize.init(width: width, height: height)
        //用于标题的默认大小
        flowLayout.headerReferenceSize = CGSize.init(width: self.view.frame.width, height: 50)
        myCollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        myCollectionView.register(UINib.init(nibName: "EditCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: EditCollectionViewCell.forCellReuseIdentifier)
        myCollectionView.register(UINib(nibName: "HeaderCollectionReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderCollectionReusableView.forCellReuseIdentifier)
        myCollectionView.contentInset = UIEdgeInsets.init(top: 44, left: 0, bottom: 0, right: 0)
        myCollectionView.backgroundColor = UIColor.white
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        myCollectionView.dragDelegate = self
        myCollectionView.dropDelegate = self
        //示集合视图是否支持应用程序之间的拖放
        myCollectionView.dragInteractionEnabled = true
        view.addSubview(myCollectionView)
        myCollectionView.snp.makeConstraints{ make in
            make.width.height.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }
}
//MARK: - UICollectionViewDelegate
extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let clickString = self.itemNames[indexPath.section]![indexPath.row]
        if indexPath.section == 0 {
            self.itemNames[1]?.append(clickString)
            self.itemNames[0]?.remove(at: indexPath.item)
            let indexPath1 = IndexPath.init(row: 0, section: 1)
            collectionView.moveItem(at: indexPath, to: indexPath1)
        }else if indexPath.section == 1 {
            self.itemNames[0]?.append(clickString)
            self.itemNames[1]?.remove(at: indexPath.item)
            let indexPath1 = IndexPath.init(item: itemNames[0]!.count - 1, section: 0)
            collectionView.moveItem(at: indexPath, to: indexPath1)
        }
        
    }
}
//MARK: - UICollectionViewDropDelegate
extension ViewController: UICollectionViewDropDelegate {
    ///处理拖动放下后如何处理
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else {
            return
        }
        switch coordinator.proposal.operation {
        case .move:
            let items = coordinator.items
            if let item = items.first, let sourceIndexPath = item.sourceIndexPath {
                //执行批量更新
                collectionView.performBatchUpdates({
                    self.itemNames[destinationIndexPath.section]!.remove(at: sourceIndexPath.row)
                    self.itemNames[destinationIndexPath.section]!.insert(item.dragItem.localObject as! String, at: destinationIndexPath.row)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                })
                //将项目动画化到视图层次结构中的任意位置
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            }
            break
        case .copy:
            //执行批量更新
            collectionView.performBatchUpdates({
                var indexPaths = [IndexPath]()
                for (index, item) in coordinator.items.enumerated() {
                    let indexPath = IndexPath(row: destinationIndexPath.row + index, section: destinationIndexPath.section)
                    self.itemNames[destinationIndexPath.section]!.insert(item.dragItem.localObject as! String, at: indexPath.row)
                    indexPaths.append(indexPath)
                }
                collectionView.insertItems(at: indexPaths)
            })
            break
        default:
            return
        }
    }
    ///处理拖动过程中
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard dragingIndexPath?.section == destinationIndexPath?.section else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        if session.localDragSession != nil {
            if collectionView.hasActiveDrag {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        } else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }
}
//MARK: - UICollectionViewDragDelegate
extension ViewController: UICollectionViewDragDelegate {
    ///处理首次拖动时，是否响应
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard indexPath.section != 1 else {
            return []
        }
        let item = self.itemNames[indexPath.section]![indexPath.row]
        let itemProvider = NSItemProvider(object: item as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        dragingIndexPath = indexPath
        return [dragItem]
    }
}

//MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
    ///向您的数据源对象询问指定部分中的项目数。
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (itemNames[section]?.count)!
    }
    ///向数据源对象询问集合视图中的部分数量。
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return itemNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: EditCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: EditCollectionViewCell.forCellReuseIdentifier, for: indexPath) as! EditCollectionViewCell
        cell.titleLabel.text = itemNames[indexPath.section]?[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderCollectionReusableView", for: indexPath) as! HeaderCollectionReusableView
        cell.titleLabel.text = itemHeaders[indexPath.section]
        return cell
    }
}
