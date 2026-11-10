#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

@Suite("UI-register type roles")
struct UITextTests {
    @Test("each role is set in the Dynamic Type style the design system names")
    func textStyleMapping() {
        var expected: [UIRole: Font.TextStyle] = [.label: .caption2, .caption: .footnote, .body: .body,
                                                  .heading: .headline, .title: .title, .display: .largeTitle]
        expected[.section] = .title2   // a Mac's 17 pt; a phone's is title3 (20 pt), see UIRoleHierarchyTests
        expected[.cardTitle] = .title3
        for role in UIRole.allCases {
            #expect(UITextSpec(role, theme: .swiss).textStyle == expected[role], "\(role)")
        }
        #expect(expected.count == UIRole.allCases.count)
    }

    @Test("the two roles added in 0.11.0 read the theme: the section the heading's weight, the card title the title's")
    func newRolesFromTheme() {
        #expect(UITextSpec(.section, theme: .swiss).weight == .bold)
        #expect(UITextSpec(.cardTitle, theme: .swiss).weight == .heavy)
        var theme = Theme.swiss
        theme.structure.type.heading.weight = 500
        theme.structure.type.heading.family = .mono
        #expect(UITextSpec(.section, theme: theme).weight == .medium)
        #expect(UITextSpec(.section, theme: theme).design == .monospaced)
        #expect(UITextSpec(.cardTitle, theme: theme).weight == .heavy, "the card title follows the title role, not the heading")
    }

    @Test("the label role is capitals, semibold, tracked 0.08 em of its 11 pt, in secondary ink")
    func labelRole() {
        let spec = UITextSpec(.label, theme: .swiss)
        #expect(spec.isUppercase)
        #expect(spec.weight == .semibold)
        #expect(near(spec.tracking, 0.08 * 11))
        #expect(spec.usesSecondaryInk)
        #expect(!spec.isHeader)
    }

    @Test("weights are the theme's: caption and body 400, heading 700, title 800")
    func weights() {
        #expect(UITextSpec(.caption, theme: .swiss).weight == .regular)
        #expect(UITextSpec(.body, theme: .swiss).weight == .regular)
        #expect(UITextSpec(.heading, theme: .swiss).weight == .bold)
        #expect(UITextSpec(.title, theme: .swiss).weight == .heavy)
    }

    @Test("negative tracking is not applied: the system tracks Dynamic Type text itself")
    func negativeTrackingDropped() {
        for role in [UIRole.heading, .section, .cardTitle, .title, .display] {
            #expect(UITextSpec(role, theme: .swiss).tracking.isZero, "\(role)")
        }
    }

    @Test("heading, card title, section and title are headers; label and caption are secondary ink, the rest ink")
    func flags() {
        for role in UIRole.allCases {
            let spec = UITextSpec(role, theme: .swiss)
            #expect(spec.isHeader == [.heading, .cardTitle, .section, .title].contains(role), "\(role)")
            #expect(spec.usesSecondaryInk == (role == .label || role == .caption), "\(role)")
            #expect(!spec.isUppercase || role == .label, "\(role)")
        }
    }

    @Test("the spec follows the theme: a theme that sets the body in a mono face and heavier yields that design and weight")
    func drivenByTheme() {
        var theme = Theme.swiss
        theme.structure.type.body.family = .mono
        theme.structure.type.body.weight = 900
        theme.structure.type.label.tracking = 0.2
        let body = UITextSpec(.body, theme: theme)
        #expect(body.design == .monospaced)
        #expect(body.weight == .black)
        #expect(near(UITextSpec(.label, theme: theme).tracking, 0.2 * 11))
    }

    @Test("every role resolves in every built-in theme")
    func allThemes() {
        for theme in Theme.all {
            for role in UIRole.allCases { _ = UITextSpec(role, theme: theme) }
            #expect(UITextSpec(.label, theme: theme).isUppercase == theme.structure.type.label.uppercase, "\(theme.id)")
        }
    }
}
#endif
