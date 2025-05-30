// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Storage
import WebKit
import XCTest

@testable import Client

class SponsoredContentFilterUtilityTests: XCTestCase {
    private static let sponsoredStandardURL = "www.test.com/?parameter&mfadid=adm"
    private let normalURL = "www.test.com/?parameter&parameter"
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    private var profile: MockProfile!
    override func setUp() {
        super.setUp()
        profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        profile = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    // MARK: - Sites

    func testNoNormalSitesFilter() {
        let subject = SponsoredContentFilterUtility()
        let sites = createSites(normalSitesCount: 5, sponsoredSitesCount: 0)
        XCTAssertEqual(sites.count, 5)
        let result = subject.filterSponsoredSites(from: sites)
        XCTAssertEqual(result.count, 5, "No sites were removed")
    }

    func testSponsoredSitesFilter() {
        let subject = SponsoredContentFilterUtility()
        let sites = createSites(normalSitesCount: 0, sponsoredSitesCount: 5)
        XCTAssertEqual(sites.count, 5)
        let result = subject.filterSponsoredSites(from: sites)
        XCTAssertEqual(result.count, 0, "All sponsored sites were removed")
    }

    func testSponsoredSitesFilterMixed() {
        let subject = SponsoredContentFilterUtility()
        let sites = createSites(normalSitesCount: 4, sponsoredSitesCount: 2)
        XCTAssertEqual(sites.count, 6)
        let result = subject.filterSponsoredSites(from: sites)
        XCTAssertEqual(result.count, 4, "All sponsored sites were removed")
    }

    // MARK: - Tabs

    func testNoNormalTabsFilter() {
        let subject = SponsoredContentFilterUtility()
        let tabs = createTabs(normalTabsCount: 5,
                              emptyURLTabsCount: 0,
                              sponsoredTabsCount: 0)
        XCTAssertEqual(tabs.count, 5)
        let result = subject.filterSponsoredTabs(from: tabs)
        XCTAssertEqual(result.count, 5, "No tabs were removed")
    }

    func testNoEmptyURLsTabsFilter() {
        let subject = SponsoredContentFilterUtility()
        let tabs = createTabs(normalTabsCount: 0,
                              emptyURLTabsCount: 5,
                              sponsoredTabsCount: 0)
        XCTAssertEqual(tabs.count, 5)
        let result = subject.filterSponsoredTabs(from: tabs)
        XCTAssertEqual(result.count, 5, "No tabs were removed")
    }

    func testSponsoredTabsFilter() {
        let subject = SponsoredContentFilterUtility()
        let tabs = createTabs(normalTabsCount: 0,
                              emptyURLTabsCount: 0,
                              sponsoredTabsCount: 5)
        XCTAssertEqual(tabs.count, 5)
        let result = subject.filterSponsoredTabs(from: tabs)
        XCTAssertEqual(result.count, 0, "All sponsored tabs were removed")
    }

    func testSponsoredTabsFilterMixed() {
        let subject = SponsoredContentFilterUtility()
        let tabs = createTabs(normalTabsCount: 4,
                              emptyURLTabsCount: 3,
                              sponsoredTabsCount: 2)
        XCTAssertEqual(tabs.count, 9)
        let result = subject.filterSponsoredTabs(from: tabs)
        XCTAssertEqual(result.count, 7, "All sponsored tabs were removed")
    }
}

// MARK: - Helpers
extension SponsoredContentFilterUtilityTests {
    func createSites(normalSitesCount: Int,
                     sponsoredSitesCount: Int) -> [Site] {
        var sites = [Site]()
        (0..<normalSitesCount).forEach { index in
            let site = Site.createBasicSite(url: normalURL,
                                            title: "")
            sites.append(site)
        }

        (0..<sponsoredSitesCount).forEach { index in
            let site = Site.createBasicSite(url: SponsoredContentFilterUtilityTests.sponsoredStandardURL,
                                            title: "")
            sites.append(site)
        }

        return sites
    }

    func createTabs(normalTabsCount: Int,
                    emptyURLTabsCount: Int,
                    sponsoredTabsCount: Int) -> [Tab] {
        var tabs = [Tab]()
        (0..<normalTabsCount).forEach { index in
            let tab = Tab(profile: profile, windowUUID: windowUUID)
            tab.url = URL(string: normalURL)
            tabs.append(tab)
        }

        (0..<emptyURLTabsCount).forEach { index in
            let tab = Tab(profile: profile, windowUUID: windowUUID)
            tabs.append(tab)
        }

        (0..<sponsoredTabsCount).forEach { index in
            let tab = Tab(profile: profile, windowUUID: windowUUID)
            tab.url = URL(string: SponsoredContentFilterUtilityTests.sponsoredStandardURL)
            tabs.append(tab)
        }

        return tabs
    }
}
