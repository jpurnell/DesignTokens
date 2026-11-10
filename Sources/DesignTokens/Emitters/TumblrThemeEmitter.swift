import Foundation

/// Why ``TumblrThemeParameters`` refused a value.
public enum TumblrThemeError: Error, Sendable, Equatable, CustomStringConvertible {
    /// A parameter is not acceptable: its name and why.
    case invalid(parameter: String, reason: String)

    /// `parameter: reason`.
    public var description: String {
        switch self {
        case .invalid(let parameter, let reason): "\(parameter): \(reason)"
        }
    }
}

/// A parent site linked at the end of the Tumblr theme's navigation.
public struct TumblrParentSite: Sendable, Hashable {
    /// The address: `https://`, `http://` or a path starting with `/`.
    public let url: String
    /// The link text, plain text.
    public let label: String

    /// Creates a parent-site link, unchecked: ``TumblrThemeParameters/init(wordmark:wordmarkURL:parentSite:relMeURL:analyticsID:)`` checks it.
    public init(url: String, label: String) {
        self.url = url
        self.label = label
    }
}

/// The per-blog values of the Tumblr full theme: everything that identifies a blog or its owner, so none of it lives in the package.
///
/// Every value is optional and has a safe default: a document made with ``placeholders`` is a complete, working theme with no analytics, no
/// parent-site link and the blog's own `{Title}` as the wordmark. A value is checked on creation and refused with ``TumblrThemeError``
/// if it could break out of an attribute, an element or a Tumblr tag.
public struct TumblrThemeParameters: Sendable, Hashable {
    /// The wordmark text in the header, or `nil` for Tumblr's own `{Title}`. Plain text: `&`, `<`, `>` and `"` are escaped, and a brace is refused.
    public let wordmark: String?
    /// Where the wordmark links: `"/"` by default; an `http(s)://` URL or a path starting with `/`.
    public let wordmarkURL: String
    /// A parent site linked at the end of the navigation, as a URL and a label; `nil` for none.
    public let parentSite: TumblrParentSite?
    /// A `rel="me"` profile URL (an IndieWeb or micro.blog identity link); `nil` for none.
    public let relMeURL: String?
    /// A Google Tag Manager container id (`GTM-` and 4 to 12 capital letters or digits); `nil` for no analytics snippet at all.
    public let analyticsID: String?

    /// Creates parameters.
    ///
    /// - Throws: ``TumblrThemeError/invalid(parameter:reason:)`` naming the parameter.
    public init(wordmark: String? = nil, wordmarkURL: String = "/", parentSite: TumblrParentSite? = nil,
                relMeURL: String? = nil, analyticsID: String? = nil) throws {
        if let wordmark { try Self.checkText(wordmark, "wordmark") }
        try Self.checkURL(wordmarkURL, "wordmarkURL")
        if let parentSite {
            try Self.checkURL(parentSite.url, "parentSite.url")
            try Self.checkText(parentSite.label, "parentSite.label")
        }
        if let relMeURL { try Self.checkURL(relMeURL, "relMeURL") }
        if let analyticsID { try Self.checkAnalytics(analyticsID) }
        self.wordmark = wordmark
        self.wordmarkURL = wordmarkURL
        self.parentSite = parentSite
        self.relMeURL = relMeURL
        self.analyticsID = analyticsID
    }

    /// The defaults: `{Title}` as the wordmark, links to `/`, nothing else. Cannot fail.
    public static let placeholders = TumblrThemeParameters()

    private init() {
        wordmark = nil
        wordmarkURL = "/"
        parentSite = nil
        relMeURL = nil
        analyticsID = nil
    }

    private static func checkText(_ text: String, _ name: String) throws {
        guard !text.isEmpty else { throw TumblrThemeError.invalid(parameter: name, reason: "empty") }
        guard !text.contains(where: { $0 == "{" || $0 == "}" }) else {
            throw TumblrThemeError.invalid(parameter: name, reason: "a brace would be read as a Tumblr tag")
        }
        guard !text.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else {
            throw TumblrThemeError.invalid(parameter: name, reason: "control characters (a newline, for one)")
        }
    }

    private static func checkURL(_ url: String, _ name: String) throws {
        guard url.hasPrefix("https://") || url.hasPrefix("http://") || url.hasPrefix("/") else {
            throw TumblrThemeError.invalid(parameter: name, reason: "must start with https://, http:// or /")
        }
        let forbidden: Set<Character> = ["\"", "'", "<", ">", "{", "}", "\\", "`"]
        guard !url.contains(where: { $0.isWhitespace || forbidden.contains($0) || $0.isNewline }) else {
            throw TumblrThemeError.invalid(parameter: name, reason: "whitespace, quotes, angle brackets, braces and backslashes are not allowed")
        }
    }

    private static func checkAnalytics(_ id: String) throws {
        let body = id.dropFirst(4)
        let ok = id.hasPrefix("GTM-") && (4...12).contains(body.count)
            && body.allSatisfy { $0.isASCII && ($0.isUppercase || $0.isNumber) }
        guard ok else {
            throw TumblrThemeError.invalid(parameter: "analyticsID", reason: "must be GTM- followed by 4 to 12 capital letters or digits")
        }
    }
}

/// Emits one ``Theme`` as a complete Tumblr theme document: the HTML a person pastes into Tumblr's *Edit HTML*, with the generated
/// block (``TumblrEmitter``) inside its single `<style>` element.
///
/// The block alone is not a theme: Tumblr needs a whole document, and a block pasted into an empty editor gives a blank page. This
/// document has the markup the block's selectors depend on (`.header .nav .post .newday .datetime .day .my .type .row .k .caption
/// .video .short_quote .medium_quote .long_quote .pager`), every Tumblr tag block the blog uses (posts of each type, pagination,
/// search, notes, permalink pages), and the small script that builds photo carousels and sizes videos.
///
/// What belongs to a blog, not to the theme, is a ``TumblrThemeParameters`` value: the wordmark, the parent-site link, a `rel="me"`
/// link and a Google Tag Manager id. With ``TumblrThemeParameters/placeholders`` the document contains none of them: the wordmark is
/// Tumblr's `{Title}` and there is no analytics snippet. Fill them with
/// `design-tokens tumblr --full --wordmark TEXT --gtm GTM-XXXX --parent-url URL --parent-label TEXT --rel-me URL`.
///
/// The stamp (``BlogStamp``) is in the style element, where ``BlogChecker`` reads it, so `check-blog` works on a page made from this
/// document. The document's own markup has no stamp: ``documentRevision`` records a change to it in the header comment.
/// The markup was taken from the owner's working theme; it has not been opened in Tumblr's editor or rendered by this package.
public enum TumblrThemeEmitter {
    /// The revision of the document markup (`TumblrDocument`, internal). Bump it when the markup changes; it is written in the header comment.
    public static let documentRevision = 1

    /// The complete document, ending in a newline.
    ///
    /// - Throws: An encoding error if the theme cannot be encoded.
    public static func emit(_ theme: Theme, parameters: TumblrThemeParameters = .placeholders) throws -> String {
        let block = try TumblrEmitter.emit(theme)
        let stamp = try TumblrEmitter.stamp(for: theme)
        let name = theme.name.replacingOccurrences(of: "--", with: "- -")
        var out = TumblrDocument.doctypeAndHead
        out += "\t\t<!-- Generated by design-tokens. Do not edit. Full Tumblr theme: \(theme.id) (\(name)) | DesignTokens \(stamp.version) | document revision \(documentRevision) | \(stamp.hash) -->\n"
        if let id = parameters.analyticsID { out += tagManagerHead(id) }
        out += TumblrDocument.titleAndFeeds
        if let rel = parameters.relMeURL { out += "\t\t<link href=\"\(rel)\" rel=\"me\" />\n" }
        out += "<style>\n" + block + "</style>\n"
        out += TumblrDocument.scriptAndViewport
        out += "\t\t<meta name=\"color-scheme\" content=\"\(colourScheme(theme.appearances))\"/>\n"
        out += TumblrDocument.descriptionAndEndOfHead
        out += "\t<body>\n"
        if let id = parameters.analyticsID { out += tagManagerBody(id) }
        out += TumblrDocument.wrapperOpen
        let mark = parameters.wordmark.map(escape) ?? "{Title}"
        out += "\t\t\t\t\t<a href=\"\(parameters.wordmarkURL)\"><h1>\(mark)</h1></a>\n"
        out += TumblrDocument.statusAndDescription
        var nav = "<a href=\"/\">Home</a><a href=\"/archive\">Archive</a><a href=\"{RSS}\">RSS</a>"
        if let parent = parameters.parentSite { nav += "<a href=\"\(parent.url)\">\(escape(parent.label))</a>" }
        out += "\t\t\t\t\t<div class=\"nav\">\(nav)</div>\n\t\t\t\t</div>\n"
        out += TumblrDocument.main
        out += TumblrDocument.tail
        return out
    }

    private static func colourScheme(_ support: AppearanceSupport) -> String {
        switch support {
        case .both: "light dark"
        case .lightOnly: "light"
        case .fixedDark: "dark"
        }
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func tagManagerHead(_ id: String) -> String {
        """
        \t<!-- Google Tag Manager -->
        <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
        new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
        j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
        'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
        })(window,document,'script','dataLayer','\(id)');</script>
        <!-- End Google Tag Manager -->

        """
    }

    private static func tagManagerBody(_ id: String) -> String {
        """
        \t<!-- Google Tag Manager (noscript) -->
        <noscript><iframe src="https://www.googletagmanager.com/ns.html?id=\(id)"
        height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
        <!-- End Google Tag Manager (noscript) -->

        """
    }
}
