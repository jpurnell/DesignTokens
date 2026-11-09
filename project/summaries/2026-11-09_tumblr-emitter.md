# Session summary 2026-11-09: Tumblr block emitter and check-blog

Branch `feature/tumblr-emitter` (from tag 0.5.0), unreleased, unpushed. Worked in a separate worktree
(`DesignTokens-tumblr`) while `feature/emitters-swiftui-0.6.0` work went on in the main checkout.

- `TumblrEmitter` produces `Generated/themes/swiss.tumblr.css`: generated colour/structure variables for light, contrast,
  dark and dark contrast, plus a fixed Tumblr template ported from `~/Desktop/tumblr-swiss.html`, with a stamp.
- `check-blog`: comparison in `BlogChecker` (fully unit-tested against a fake `BlogFetching`); `ChromeBlogFetcher` is the
  real fetcher and needs local Chrome.
- Chrome experiment (2026-11-09): curl gets 403 and a challenge page; headless Chrome returns the real blog on `/` and
  `/page/2`, exits 2 after a complete dump, and the live DOM holds the Swiss draft's CSS with no stamp (unstamped).

Open: paste the block into a Tumblr preview and render it; the computed-value drift check; Linux unbuilt; the version
constant `TumblrEmitter.packageVersion` must be bumped with the release.
