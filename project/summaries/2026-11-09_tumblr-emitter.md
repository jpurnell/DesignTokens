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

## Merge into the 0.6.0 line (2026-11-09)

Branch `merge/tumblr-into-0.6.0` (merge of `feature/tumblr-emitter` into `feature/emitters-swiftui-0.6.0`, `--no-ff`; unpushed, untagged).
Conflicts were all prose plus `main.swift` (kept the Tumblr dispatch, then the 0.6.0 generator call). Adapted: stamp version reads
`DesignTokens.version`; golden `Generated/themes/swiss.tumblr.css` regenerated (stamp `swiss 0.5.0 t1 fnv1a64:0b29fca8ff936a4b` to
`swiss 0.6.0 t1 fnv1a64:e0b8ece8b01ecf01`, nothing else changed); `Generator.files()` includes it so the nothing-else-in-Generated test passes.
Still Swiss-only. Unverified: Linux; nothing rendered or pasted in Tumblr.
