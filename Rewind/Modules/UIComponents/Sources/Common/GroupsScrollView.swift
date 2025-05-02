import SwiftUI
import UIKit

// временно тут
public struct RewindGroup: Identifiable, Hashable {
    public let id: UUID = UUID()
    public let image: UIImage
    public let name: String
    
    public init(image: UIImage, name: String) {
        self.image = image
        self.name = name
    }
}

// MARK: - Constants

private enum Constants {
    static let cornerRadius: CGFloat = 45
    static let fontSize: CGFloat = 12
    static let titleTopPadding: CGFloat = 4
    static let defaultImageSize: CGFloat = 90
}

// MARK: - GroupsScrollView

public struct GroupsScrollView: UIViewRepresentable {
    private let groups: [RewindGroup]
    private let imageSize: CGFloat
    
    public init(groups: [RewindGroup], imageSize: CGFloat) {
        self.groups = groups
        self.imageSize = imageSize
    }
    
    public func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(width: imageSize, height: imageSize + 16)
        layout.itemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = .zero
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(Cell.self, forCellWithReuseIdentifier: Cell.reuseIdentifier)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        
        context.coordinator.configureDataSource(for: collectionView)
        
        return collectionView
    }
    
    public func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.update(groups: groups)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(imageSize: imageSize)
    }
}

// MARK: - Coordinator

public final class Coordinator {
    private var dataSource: UICollectionViewDiffableDataSource<Int, RewindGroup>?
    private let imageSize: CGFloat
    
    init(imageSize: CGFloat) {
        self.imageSize = imageSize
    }
    
    func configureDataSource(for collectionView: UICollectionView) {
        dataSource = UICollectionViewDiffableDataSource<Int, RewindGroup>(collectionView: collectionView) { collectionView, indexPath, group in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
            cell.configure(with: group, imageSize: self.imageSize)
            return cell
        }
    }
    
    func update(groups: [RewindGroup]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, RewindGroup>()
        snapshot.appendSections([0])
        snapshot.appendItems(groups, toSection: 0)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Cell

public final class Cell: UICollectionViewCell {
    static let reuseIdentifier = "Cell"
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private var widthConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with group: RewindGroup, imageSize: CGFloat) {
        imageView.image = group.image
        titleLabel.text = group.name
        
        widthConstraint?.constant = imageSize
    }
    
    private func setupViews() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.cornerRadius
        
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        let font = UIFont.systemFont(ofSize: Constants.fontSize, weight: .bold)
        titleLabel.font = UIFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: Constants.fontSize)
        titleLabel.textColor = UIComponentsAsset.textPrimary.color
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        widthConstraint = imageView.widthAnchor.constraint(equalToConstant: Constants.defaultImageSize)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            widthConstraint!,
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: Constants.titleTopPadding),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.8),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }
}
