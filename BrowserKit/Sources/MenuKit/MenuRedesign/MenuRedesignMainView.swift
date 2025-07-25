// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import ComponentLibrary

public final class MenuRedesignMainView: UIView,
                                         ThemeApplicable {
    private struct UX {
        static let headerTopMargin: CGFloat = 24
        static let horizontalMargin: CGFloat = 16
        static let closeButtonSize: CGFloat = 30
        static let headerTopMarginWithButton: CGFloat = 8
    }

    public var closeButtonCallback: (() -> Void)?
    public var onCalculatedHeight: ((CGFloat) -> Void)?

    // MARK: - UI Elements
    private var tableView: MenuRedesignTableView = .build()
    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
    }
    public var headerBanner: HeaderBanner = .build()

    public var siteProtectionHeader: MenuSiteProtectionsHeader = .build()

    private var viewConstraints: [NSLayoutConstraint] = []

    // MARK: - Properties
    private var isMenuDefaultBrowserBanner = false

    // MARK: - UI Setup
    private func setupView(with data: [MenuSection], isHeaderBanner: Bool = true) {
        self.removeConstraints(viewConstraints)
        viewConstraints.removeAll()
        self.addSubview(tableView)
        if let section = data.first(where: { $0.isHomepage }), section.isHomepage {
            self.siteProtectionHeader.removeFromSuperview()
            self.addSubview(closeButton)
            viewConstraints.append(contentsOf: [
                closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: UX.headerTopMargin),
                closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -UX.horizontalMargin),
                closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
                closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),
            ])

            if isHeaderBanner && isMenuDefaultBrowserBanner {
                self.addSubview(headerBanner)
                viewConstraints.append(contentsOf: [
                    headerBanner.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: UX.headerTopMargin),
                    headerBanner.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    headerBanner.trailingAnchor.constraint(equalTo: self.trailingAnchor),

                    tableView.topAnchor.constraint(equalTo: headerBanner.bottomAnchor,
                                                   constant: UX.headerTopMarginWithButton),
                    tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                    tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
                ])
            } else {
                headerBanner.removeFromSuperview()
                viewConstraints.append(contentsOf: [
                    tableView.topAnchor.constraint(equalTo: closeButton.bottomAnchor,
                                                   constant: UX.headerTopMarginWithButton),
                    tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                    tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
                ])
            }
        } else if !data.isEmpty {
            self.closeButton.removeFromSuperview()
            self.addSubview(siteProtectionHeader)
            viewConstraints.append(contentsOf: [
                siteProtectionHeader.topAnchor.constraint(equalTo: self.topAnchor, constant: UX.headerTopMargin),
                siteProtectionHeader.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                siteProtectionHeader.trailingAnchor.constraint(equalTo: self.trailingAnchor),

                tableView.topAnchor.constraint(equalTo: siteProtectionHeader.bottomAnchor,
                                               constant: UX.headerTopMarginWithButton),
                tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
        }
        NSLayoutConstraint.activate(viewConstraints)
    }

    public func setupAccessibilityIdentifiers(menuA11yId: String,
                                              menuA11yLabel: String,
                                              closeButtonA11yLabel: String,
                                              closeButtonA11yIdentifier: String,
                                              siteProtectionHeaderIdentifier: String) {
        let closeButtonViewModel = CloseButtonViewModel(a11yLabel: closeButtonA11yLabel,
                                                        a11yIdentifier: closeButtonA11yIdentifier)
        closeButton.configure(viewModel: closeButtonViewModel)
        headerBanner.setupAccessibility(closeButtonA11yLabel: closeButtonA11yLabel,
                                        closeButtonA11yId: closeButtonA11yIdentifier)
        siteProtectionHeader.setupAccessibility(closeButtonA11yLabel: closeButtonA11yLabel,
                                                closeButtonA11yId: closeButtonA11yIdentifier)
        siteProtectionHeader.accessibilityIdentifier = siteProtectionHeaderIdentifier
    }

    public func setupDetails(title: String, subtitle: String, image: UIImage?, isBannerEnabled: Bool) {
        headerBanner.setupDetails(title: title, subtitle: subtitle, image: image)
        isMenuDefaultBrowserBanner = isBannerEnabled
    }

    // MARK: - Interface
    public func reloadDataView(with data: [MenuSection]) {
        setupView(with: data)
        tableView.reloadTableView(with: data)
        handleBannerCallback(with: data)
        updateMenuHeight(for: data)
    }

    private func updateMenuHeight(for data: [MenuSection]) {
        // To avoid a glitch when expand the menu, we should not handle this action under DispatchQueue.main.async
        if let expandedSection = data.first(where: { $0.isExpanded ?? false }),
           let isExpanded = expandedSection.isExpanded,
           isExpanded {
            let height = tableView.tableViewContentSize + UX.headerTopMargin
            onCalculatedHeight?(height + siteProtectionHeader.frame.height)
            layoutIfNeeded()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let height = tableView.tableViewContentSize + UX.headerTopMargin
                if let section = data.first(where: { $0.isHomepage }), section.isHomepage {
                    self.setHeightForHomepageMenu(height: height)
                } else {
                    onCalculatedHeight?(height + siteProtectionHeader.frame.height)
                }
                layoutIfNeeded()
            }
        }
    }

    private func setHeightForHomepageMenu(height: CGFloat) {
        if isMenuDefaultBrowserBanner {
            let headerBannerHeight = headerBanner.frame.height
            self.onCalculatedHeight?(height +
                                     UX.closeButtonSize +
                                     UX.headerTopMarginWithButton +
                                     headerBannerHeight +
                                     UX.headerTopMargin)
        } else {
            self.onCalculatedHeight?(height + UX.closeButtonSize + UX.headerTopMarginWithButton)
        }
    }

    private func handleBannerCallback(with data: [MenuSection]) {
        headerBanner.closeButtonCallback = { [weak self] in
            self?.setupView(with: data, isHeaderBanner: false)
        }
    }

    // MARK: - Callbacks
    @objc
    private func closeTapped() {
        closeButtonCallback?()
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        backgroundColor = .clear
        tableView.applyTheme(theme: theme)
        siteProtectionHeader.applyTheme(theme: theme)
        headerBanner.applyTheme(theme: theme)
    }
}
