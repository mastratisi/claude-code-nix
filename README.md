# claude-code-nix

Nix flake for [Claude Code](https://www.anthropic.com/claude-code), following Anthropic's release feed.

The package installs the prebuilt native binary from `downloads.claude.ai` (fallback: Anthropic's
Google Cloud Storage bucket) and wraps it with `procps`, `ripgrep` and, on Linux, `bubblewrap` and
`socat` on `PATH`. Nothing is compiled. Binaries are patched with `autoPatchelfHook` on Linux.

## Use

```
nix run github:mastratisi/claude-code-nix -- --version
```

In a flake-based NixOS config:

```nix
inputs.claude-code-nix.url = "github:mastratisi/claude-code-nix";
# ...
nixpkgs.overlays = [ claude-code-nix.overlays.default ];
environment.systemPackages = [ pkgs.claude-code ];
```

Systems: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin. Unfree: set
`nixpkgs.config.allowUnfree`.

## How it stays current

- `update.sh` reads `https://downloads.claude.ai/claude-code-releases/latest`, fetches that
  version's `manifest.json` and writes `release.json`: the version and, per platform, the sha256
  Anthropic publishes in the manifest. The script does not hash anything it downloaded.
- `.github/workflows/update.yml` runs it every six hours, builds, checks `claude --version`,
  commits `release.json` directly to `main` and tags the commit `v<version>`. There is no pull
  request and no third-party action beyond checkout and the Nix installer.
- `package.nix` only reads `release.json`; it has no version of its own.

The manifest also carries a signature (`manifest.json.sig`) that this flake does not verify.

Update by hand: `nix develop -c ./update.sh && nix build`.
