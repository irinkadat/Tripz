//
//  HomeViewController.swift
//  Tripzi
//
//  Created by Irinka Datoshvili on 28.06.24.
//

import UIKit
import Combine
import SwiftUI

class HomeViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var categoriesCollectionView: UICollectionView!
    private var viewModel = SearchViewModel()
    private let customSearchBar = CustomSearchBar()
    
    private var categories: [SearchCategory] = [
        SearchCategory(name: "Hotel", icon: (UIImage(named: "hotel") ?? UIImage(named: "pic"))!),
        SearchCategory(name: "food", icon: UIImage(named: "burger") ?? UIImage(named: "pic")!),
        SearchCategory(name: "Stores", icon: UIImage(named: "store") ?? UIImage(named: "pic")!),
        SearchCategory(name: "Bar", icon: (UIImage(named: "vodka") ?? UIImage(named: "pic"))!),
        SearchCategory(name: "Coffee", icon: UIImage(named: "cup") ?? UIImage(named: "pic")!),
        SearchCategory(name: "Museums", icon: UIImage(named: "museum") ?? UIImage(named: "pic")!),
        SearchCategory(name: "Night Clubs", icon: UIImage(named: "fire") ?? UIImage(named: "pic")!),
        SearchCategory(name: "music", icon: UIImage(named: "music") ?? UIImage(named: "pic")!)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCustomSearchBar()
        setupCategoriesCollectionView()
        setupCollectionView()
        addSearchBarTapGesture()
        
        viewModel.fetchDefaultListings()
        print(viewModel.listings.count)
        
        viewModel.$listings.sink { [weak self] listings in
            print("Listings updated: \(listings.count)")
            self?.collectionView.reloadData()
        }.store(in: &cancellables)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleSearchNotification(_:)), name: .searchPerformed, object: nil)
    }
    
    private func setupCustomSearchBar() {
        customSearchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customSearchBar)
        
        NSLayoutConstraint.activate([
            customSearchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            customSearchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customSearchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            customSearchBar.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    private func setupCategoriesCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        
        categoriesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        categoriesCollectionView.backgroundColor = .white
        categoriesCollectionView.dataSource = self
        categoriesCollectionView.delegate = self
        categoriesCollectionView.showsHorizontalScrollIndicator = false
        categoriesCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseIdentifier)
        
        view.addSubview(categoriesCollectionView)
        categoriesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            categoriesCollectionView.topAnchor.constraint(equalTo: customSearchBar.bottomAnchor, constant: 20),
            categoriesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            categoriesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoriesCollectionView.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 20
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: "CustomCell")
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: categoriesCollectionView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func addSearchBarTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSearchBar))
        customSearchBar.addGestureRecognizer(tapGesture)
    }
    
    @objc private func didTapSearchBar() {
        let searchVC = SearchViewController()
        searchVC.delegate = self
        searchVC.modalPresentationStyle = .fullScreen
        present(searchVC, animated: true, completion: nil)
    }
    
    @objc private func handleSearchNotification(_ notification: Notification) {
        if let results = notification.userInfo?["results"] as? [Listing] {
            updateListings(with: results)
        }
    }
    
    private func updateListings(with results: [Listing]) {
        viewModel.listings = results
        collectionView.reloadData()
    }
    
    private var cancellables = Set<AnyCancellable>()
}

extension HomeViewController: SearchViewControllerDelegate {
    func didPerformSearch(results: [Listing]) {
        updateListings(with: results)
    }
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoriesCollectionView {
            return categories.count
        } else {
            let itemCount = viewModel.listings.count
            return itemCount
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoriesCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as! CategoryCell
            let category = categories[indexPath.row]
            cell.configure(with: category)
            return cell
        } else {
            let listing = viewModel.listings[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCollectionViewCell
            print("Configuring cell for listing: \(listing.name)") // Debug output
            cell.configure(with: listing) { [weak self] in
                let destinationDetailsVC = DestinationDetailsVC()
                destinationDetailsVC.listing = listing
                self?.navigationController?.pushViewController(destinationDetailsVC, animated: true)
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoriesCollectionView {
            let category = categories[indexPath.row].name
            viewModel.fetchListings(for: category)
        } else {
            let selectedListing = viewModel.listings[indexPath.row]
            viewModel.destinationDetails(for: selectedListing.id) { [weak self] detailedListing in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    let destinationDetailsVC = DestinationDetailsVC()
                    destinationDetailsVC.listing = detailedListing
                    self.navigationController?.pushViewController(destinationDetailsVC, animated: true)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoriesCollectionView {
            return CGSize(width: 60, height: 70)
        } else {
            return CGSize(width: view.frame.width, height: 450)
        }
    }
}

#Preview {
    HomeViewController()
}
