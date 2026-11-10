#if canImport(SwiftUI) && (canImport(AppKit) || canImport(UIKit))
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

/// The size ordering of the UI roles, measured from the platform's own text styles (`NSFont` on a Mac, `UIFont` elsewhere) at the
/// default size, so it fails if a mapping puts a section heading level with a value. Runs under `swift test` (macOS) and
/// `xcodebuild test` (an iOS Simulator).
@Suite("UI role hierarchy")
struct UIRoleHierarchyTests {
    private func size(_ role: UIRole) throws -> CGFloat {
        try #require(UITextSpec(role, theme: .swiss).pointSize, "\(role) resolves to a size on this platform")
    }

    @Test("display > title > section > card title >= heading >= body > caption >= label, in measured points")
    func ordering() throws {
        let display = try size(.display), title = try size(.title), section = try size(.section)
        let card = try size(.cardTitle), heading = try size(.heading), body = try size(.body)
        let caption = try size(.caption), label = try size(.label)
        #expect(display > title, "display \(display) over title \(title)")
        #expect(title > section, "title \(title) over section \(section)")
        #expect(section > card, "section \(section) over card title \(card)")
        #expect(card >= heading, "card title \(card) not under heading \(heading)")
        #expect(heading >= body, "heading \(heading) not under body \(body)")
        #expect(body > caption, "body \(body) over caption \(caption)")
        #expect(caption >= label, "caption \(caption) not under label \(label)")
    }

    @Test("a section heading is not the size of a value: at least three points above the body (a phone's is 20 over 17), and the title as far above it")
    func sectionHasProminence() throws {
        #expect(try size(.section) - size(.body) >= 3)
        #expect(try size(.title) - size(.section) >= 3, "the page title stays clearly the largest of the hierarchy")
    }

    #if os(macOS)
    @Test("at Mac window size: section 17 to 20, card title no larger, label and caption 10, body 13")
    func ownerNumbersOnAMac() throws {
        let section = try size(.section)
        #expect(section >= 17 && section <= 20)
        #expect(try size(.cardTitle) <= section)
        #expect(try size(.label).isEqual(to: 10))
        #expect(try size(.caption).isEqual(to: 10))
        #expect(try size(.body).isEqual(to: 13))
        #expect(try size(.title) > section + 4)
    }
    #else
    @Test("on a phone at default size the hierarchy is 28 / 20 / 17 / 17 for title, section, card title and heading")
    func phoneHierarchy() throws {
        #expect(try size(.title).isEqual(to: 28))
        #expect(try size(.section).isEqual(to: 20))
        #expect(try size(.cardTitle).isEqual(to: 17))
        #expect(try size(.heading).isEqual(to: 17))
    }
    #endif
}
#endif
