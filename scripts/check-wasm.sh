#!/usr/bin/env bash
# Builds the DesignTokens core for WebAssembly (wasm32-unknown-wasip1) and checks two things:
#
#   1. The CSS it emits for four themes is byte-identical to the committed Generated/themes/<id>.css, run under
#      Node's WASI. The committed files are the oracle; nothing here knows what the CSS should say.
#   2. The binary stays small: with the debug and name sections stripped, at most BUDGET_GZIP_MB gzipped. Full
#      Foundation links the ICU data tables and costs about 19 MB gzipped; FoundationEssentials alone is about 4 MB.
#      The budget fails the check if anything in the core starts needing full Foundation again.
#
# The probe is a scratch package outside the repository that depends on this one by path, so nothing is added to
# Package.swift. Needs: a Swift toolchain from swift.org with the WebAssembly SDK installed (see below), node, python3.
#
#   swiftly install 6.4.3 && swift sdk install <URL of swift-6.4.3-RELEASE_wasm.artifactbundle.tar.gz> --checksum <sum>
#
# Environment: SWIFT (default `swiftly run swift` with TOOLCHAIN selected), WASM_SDK (default swift-6.4.3-RELEASE_wasm),
# TOOLCHAIN (default 6.4.3), BUDGET_GZIP_MB (default 6), THEMES (default "platinum system7 openstep swiss").
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TOOLCHAIN="${TOOLCHAIN:-6.4.3}"
WASM_SDK="${WASM_SDK:-swift-6.4.3-RELEASE_wasm}"
BUDGET_GZIP_MB="${BUDGET_GZIP_MB:-6}"
THEMES="${THEMES:-platinum system7 openstep swiss}"

if [ -n "${SWIFT:-}" ]; then
    swift_cmd=($SWIFT)
elif command -v swiftly >/dev/null 2>&1; then
    swift_cmd=(swiftly run swift)
    selector=("+$TOOLCHAIN")
else
    swift_cmd=(swift)
fi
selector=("${selector[@]:-}")
for tool in node python3 gzip; do
    command -v "$tool" >/dev/null 2>&1 || { echo "check-wasm: $tool is required" >&2; exit 2; }
done

work="$(mktemp -d "${TMPDIR:-/tmp}/check-wasm.XXXXXX")"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/Sources/wasm-probe"

cat > "$work/Package.swift" <<EOF
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "wasm-probe",
    dependencies: [.package(path: "$REPO")],
    targets: [.executableTarget(name: "wasm-probe", dependencies: [.product(name: "DesignTokens", package: "$(basename "$REPO")")])]
)
EOF

# The probe imports FoundationEssentials only, and writes with print: importing Foundation here would link ICU itself.
cat > "$work/Sources/wasm-probe/main.swift" <<'EOF'
import DesignTokens
import FoundationEssentials
#if canImport(WASILibc)
import WASILibc
#endif

let id = CommandLine.arguments.dropFirst().first ?? "platinum"
guard let theme = Theme.all.first(where: { $0.id == id }) else {
    print("unknown theme \(id)")
    exit(1)
}
do {
    print(try ThemeCSSEmitter.emit(theme), terminator: "")
} catch {
    print("\(error)")
    exit(2)
}
EOF

cat > "$work/run.mjs" <<'EOF'
import { WASI } from 'node:wasi';
import { readFile } from 'node:fs/promises';
const wasi = new WASI({ version: 'preview1', args: ['wasm-probe', process.argv[3]], env: {}, preopens: {} });
const mod = await WebAssembly.compile(await readFile(process.argv[2]));
wasi.start(await WebAssembly.instantiate(mod, wasi.getImportObject()));
EOF

echo "check-wasm: building the core for WebAssembly (${WASM_SDK}, toolchain ${TOOLCHAIN})"
(cd "$work" && "${swift_cmd[@]}" build --swift-sdk "$WASM_SDK" --product wasm-probe -c release ${selector[@]+"${selector[@]}"} >"$work/build.log" 2>&1) || {
    tail -40 "$work/build.log" >&2
    echo "check-wasm: FAILED, the core does not build for WebAssembly" >&2
    exit 1
}
wasm="$(find -L "$work/.build" -name wasm-probe.wasm -path '*release*' | head -1)"
[ -n "$wasm" ] || { echo "check-wasm: no wasm-probe.wasm found" >&2; exit 1; }

status=0
for id in $THEMES; do
    committed="$REPO/Generated/themes/$id.css"
    if node --no-warnings "$work/run.mjs" "$wasm" "$id" > "$work/$id.css" 2>"$work/$id.err" && cmp -s "$work/$id.css" "$committed"; then
        echo "check-wasm: $id byte-identical ($(wc -c < "$committed" | tr -d ' ') bytes)"
    else
        echo "check-wasm: $id DIFFERS from $committed" >&2
        status=1
    fi
done

python3 -I - "$wasm" "$work/stripped.wasm" "$BUDGET_GZIP_MB" <<'EOF' || status=1
import gzip, sys
src, dst, budget = sys.argv[1], sys.argv[2], float(sys.argv[3])
def leb(b, i):
    r = s = 0
    while True:
        x = b[i]; i += 1; r |= (x & 0x7f) << s; s += 7
        if x < 0x80: return r, i
b = open(src, 'rb').read(); i = 8; out = bytearray(b[:8])
while i < len(b):
    start = i; sid = b[i]; i += 1; n, i = leb(b, i)
    if sid != 0: out += b[start:i + n]   # custom sections (debug info, names) are dropped
    i += n
open(dst, 'wb').write(out)
gz = len(gzip.compress(bytes(out), 9)) / 1e6
print(f"check-wasm: {len(b)/1e6:.1f} MB raw, {len(out)/1e6:.1f} MB stripped, {gz:.2f} MB gzipped (budget {budget:g})")
sys.exit(0 if gz <= budget else 1)
EOF
if command -v brotli >/dev/null 2>&1; then
    echo "check-wasm: $(brotli -q 9 -c "$work/stripped.wasm" | wc -c | awk '{printf "%.2f", $1/1e6}') MB brotli (q9)"
fi
if [ "$status" -ne 0 ]; then echo "check-wasm: FAILED" >&2; exit 1; fi
echo "check-wasm: OK"
