import SwiftUI
import Base
import UIKit
import Domain

// MARK: - Constants

private enum Constants {
    static let cornerRadius: CGFloat = 45
    static let fontSize: CGFloat = 12
    static let titleTopPadding: CGFloat = 4
    static let defaultImageSize: CGFloat = 90
}

// MARK: - GroupsScrollView

public struct GroupsScrollView: UIViewRepresentable {
    private let selectedGroupID: Int?
    private let groups: [Domain.Group]
    private let imageSize: CGFloat
    private let onGroupSelected: ((Domain.Group) -> Void)?

    public init(
        selectedGroupID: Int?,
        groups: [Domain.Group],
        imageSize: CGFloat,
        onGroupSelected: ((Domain.Group) -> Void)?
    ) {
        self.selectedGroupID = selectedGroupID
        self.groups = groups
        self.imageSize = imageSize
        self.onGroupSelected = onGroupSelected
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
        collectionView.delegate = context.coordinator

        context.coordinator.configureDataSource(for: collectionView)

        return collectionView
    }

    public func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.update(groups: groups, selectedGroupID: selectedGroupID)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            imageSize: imageSize,
            selectedGroupID: selectedGroupID,
            onGroupSelected: onGroupSelected
        )
    }
}

// MARK: - Coordinator

public final class Coordinator: NSObject, UICollectionViewDelegate {
    private var dataSource: UICollectionViewDiffableDataSource<Int, Domain.Group>?
    private let imageSize: CGFloat
    private var selectedGroupID: Int?
    private let onGroupSelected: ((Domain.Group) -> Void)?

    init(imageSize: CGFloat, selectedGroupID: Int?, onGroupSelected: ((Domain.Group) -> Void)?) {
        self.imageSize = imageSize
        self.selectedGroupID = selectedGroupID
        self.onGroupSelected = onGroupSelected
    }

    // swiftlint:disable force_cast
    func configureDataSource(for collectionView: UICollectionView) {
        dataSource = UICollectionViewDiffableDataSource<Int, Domain.Group>(collectionView: collectionView) {
            collectionView, indexPath, group in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Cell.reuseIdentifier,
                for: indexPath
            ) as! Cell
            cell.configure(
                with: group,
                imageSize: self.imageSize,
                isSelected: group.id == self.selectedGroupID
            )
            return cell
        }
    }
    // swiftlint:enable force_cast

    func update(groups: [Domain.Group], selectedGroupID: Int?) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Domain.Group>()
        snapshot.appendSections([0])
        snapshot.appendItems(groups, toSection: 0)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let group = dataSource?.itemIdentifier(for: indexPath) else { return }

        if selectedGroupID != group.id {
            selectedGroupID = group.id

            onGroupSelected?(group)

            collectionView.visibleCells.forEach { cell in
                if let cell = cell as? Cell, let indexPath = collectionView.indexPath(for: cell) {
                    if let group = dataSource?.itemIdentifier(for: indexPath) {
                        cell.configure(
                            with: group,
                            imageSize: imageSize,
                            isSelected: group.id == selectedGroupID
                        )
                    }
                }
            }
        }
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

    func configure(
        with group: Domain.Group,
        imageSize: CGFloat,
        isSelected: Bool
    ) {
        titleLabel.text = group.name
        widthConstraint?.constant = imageSize
        imageView.image = DomainAsset.groupPlaceholder.image

        Task {
            let image = await ImageProvider.loadOrGetImage(for: group.imageURL, .group)
            await MainActor.run {
                self.imageView.image = image
            }
        }

        if isSelected {
            imageView.layer.borderColor = UIComponentsAsset.pinkPrimary.color.cgColor
            imageView.layer.borderWidth = 3
            titleLabel.textColor = UIComponentsAsset.pinkPrimary.color
        } else {
            imageView.layer.borderWidth = 0
            titleLabel.textColor = UIComponentsAsset.textPrimary.color
        }
    }

    private func setupViews() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.cornerRadius

        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        let font = UIFont.systemFont(ofSize: Constants.fontSize, weight: .bold)
        titleLabel.font = UIFont(
            descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor,
            size: Constants.fontSize
        )
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
