# Next steps

Remaining work from the September 2026 review, after items 1–10 were applied.
Ordered by value, not effort. Each item says why it matters and what "done"
looks like, so it can be picked up cold.

## Done so far

Items 1–5 (urgent) and 6–10 (follow-up) are applied:

| # | Change |
|---|--------|
| 1 | CI actions moved to Node 24 majors; workflow token scoped to `contents: read`; concurrency group added |
| 2 | kitty theme include path fixed (`kitty/tokyo_theme/…`) — the theme had never loaded |
| 3 | zsh history configured (`HISTFILE`, `SAVEHIST=50000`, `SHARE_HISTORY`, credential filter) |
| 4 | `ControlPath` added — `ControlMaster`/`ControlPersist` were inert without it |
| 5 | `make clean` fixed (`-delete` implies `-depth`, which made `-prune` a no-op) |
| 6 | Personal profile split into `personal.common.sh` + `personal.zsh` + `personal.bash`; greeter guarded to interactive TTYs |
| 7 | `condarc` de-templated to `${HOME}`; `${WORK}` paths moved to `CONDA_ENVS_PATH`/`CONDA_PKGS_DIRS` |
| 8 | `pre-commit` adopted as the single lint source; CI collapsed 9 jobs → 5; install smoke test added |
| 9 | `make check-strict` — a missing linter is now a hard failure instead of a silent pass |
| 10 | README reconciled with reality; PR template relocated; `filter.lfs.required` dropped |

---

## 11. Speed up `compinit` with the daily-cache pattern

**Why.** `compinit` is typically the single largest contributor to zsh startup.
Current interactive startup measures ~0.65 s. `compinit` currently re-verifies
the completion dump on every shell.

**Do.** In `shell/zshrc` section 3, replace the unconditional `compinit` with
the standard once-a-day check:

```zsh
autoload -Uz compinit
_zcompdump="$XDG_CACHE_HOME/zsh/.zcompdump"
if [[ -n $_zcompdump(#qNmh+24) ]]; then
	compinit -d "$_zcompdump"      # dump older than 24h — full check
else
	compinit -C -d "$_zcompdump"   # fresh — skip the security check
fi
unset _zcompdump
```

**Done when.** `zsh -i -c exit` is measurably faster on a warm cache and
completions still work for a newly installed tool after a day.

Reference: <https://gist.github.com/ctechols/ca1035271ad134841284>

## 12. Reconsider the plugin manager

**Why.** Zinit is maintained, but benchmarks poorly on load time next to
antidote/sheldon/zimfw. This repo loads exactly five plugins, so the machinery
in `shell/plugins/loader.zsh` + `shell/plugins/zinit.zsh` (about 100 lines,
plus a deferred-load hook) is doing more work than the problem needs.

**Do.** Evaluate replacing both files with the ~20-line `zsh_unplugged`
pattern — clone plugins into `$XDG_DATA_HOME/zsh/plugins`, source them in
order, keep `zsh-syntax-highlighting` last. No dependency, no turbo mode, no
deferred-compinit dance.

**Done when.** The same five plugins work, `loader.zsh`/`zinit.zsh` are gone,
and startup is no slower.

References: <https://github.com/mattmc3/zsh_unplugged> ·
<https://github.com/rossmacarthur/zsh-plugin-manager-benchmark>

## 13. Add Dependabot for GitHub Actions

**Why.** The Node 20 removal was announced roughly a year before it would have
broken this repo's CI. Nothing surfaced it. The vendored `kitty/tokyo_theme`
submodule ships a `dependabot.yml`; this repo does not.

**Do.** Create `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: monthly
  - package-ecosystem: pip
    directory: "/"
    schedule:
      interval: monthly
```

Consider also adding the `pre-commit` ecosystem once Dependabot's support for
it is enabled on the repo, or use `pre-commit autoupdate` on a schedule.

**Done when.** A PR appears the next time an action publishes a major version.

## 14. Modernise `git/gitconfig`

**Why.** Several cheap, high-value settings are missing.

**Do.** Add:

```ini
[rerere]
	enabled = true          # remember conflict resolutions
[column]
	ui = auto               # multi-column branch/tag listings
[branch]
	sort = -committerdate   # most recent branches first
[transfer]
	fsckObjects = true      # reject malformed objects on fetch
[core]
	excludesFile = ~/.config/git/ignore
```

Also reconsider `core.pager = less -FRX`: `-X` disables the alternate screen,
which leaves pager output in the scrollback and breaks mouse scrolling in some
terminals. `-FR` alone is usually the better default.

**Done when.** `git config --list --show-origin` reflects the new keys and
nothing in daily use regresses.

## 15. Lock down kitty remote control

**Why.** `kitty/kitty.conf` currently sets `allow_remote_control yes` with
`listen_on unix:@kitty`. That abstract socket is reachable by **any** process
running as your user — any of them can drive the terminal, read window
contents, and run commands. The config's own comment flags this.

**Do.** Either:

```conf
allow_remote_control password
remote_control_password "my-passphrase" get-colors set-colors
```

or scope the socket to the session:

```conf
allow_remote_control socket-only
listen_on unix:${XDG_RUNTIME_DIR}/kitty-{kitty_pid}
```

**Done when.** `kitty @ ls` from an unrelated shell no longer succeeds without
authorisation, while your own kitten workflows still work.

---

## Larger, optional directions

### 16. `${WORK}` handling is now correct but untested

Item 7 moved the cluster conda paths out of `condarc` into environment
variables, because conda leaves an *unset* `${WORK}` as literal text and
resolves it against `$PWD`. This was verified against conda 26.1.1 locally
with `WORK` both set and unset, but **not on a real cluster**.

Next time you log into `cca` or `glui`, confirm:

```sh
echo "$CONDA_ENVS_PATH"
conda config --show envs_dirs pkgs_dirs
```

The `$WORK` entries should appear first and be fully expanded. Note the
separators differ: `CONDA_ENVS_PATH` splits on `:`, `CONDA_PKGS_DIRS` on `,`.

### 17. Decide the fate of the second installer

There are three installation scripts — `install.sh`, `stow.sh`, and
`build-stow-tree.sh` — totalling roughly 450 lines, and the Stow path is
unused (the tree has never been committed and is now explicitly gitignored).
`install.sh` is what actually runs on every machine.

Either delete the Stow path outright, or commit to it and drop `install.sh`.
Keeping both means every structural change has to be made twice.

If per-machine variation keeps growing, [chezmoi](https://www.chezmoi.io/) is
the tool built for exactly the problems this repo hand-rolls — Go templates for
host-specific values, first-class `age`/`gpg` encryption, and `run_onchange_`
bootstrap scripts. Migration is real work; only worth it at a third machine
class or a macOS host.

### 18. `neovim/` is a vendored copy, not a submodule

`neovim/` is 90 files copied from [rafi/vim-config](https://github.com/rafi/vim-config).
No installer links it, no lint job covers it, and it is excluded from
`.pre-commit-config.yaml`. It will drift from upstream and nothing will notice.

Make it a submodule (as `kitty/tokyo_theme` already is) and have `install.sh`
link it to `$XDG_CONFIG_HOME/nvim`, or delete it.

### 19. `python-envs/` is unreferenced

Six conda environment specs that nothing installs, tests, or locks. Either wire
them into a `make envs` target with `conda-lock` for reproducibility, or move
the pure-Python ones to `uv` + `pyproject.toml`.

### 20. `shfmt` is deliberately not enforced

Running `shfmt -i 0 -ci` over the repo produces a ~470-line diff: it collapses
the deliberate column alignment in `build-stow-tree.sh`'s `link_into` table and
expands one-line `|| { …; }` guards. That was judged a net loss in readability,
so `shfmt` is **not** in `.pre-commit-config.yaml`.

`make fmt-shell` still runs it on demand. If you ever want it enforced, do the
reformat as a single isolated commit so it doesn't contaminate a real change.

### 21. `_link_tools` uses the wrong mechanism

`shell/zprofile` section 8 aliases every script in `tools/bash` and
`tools/scripts`. Two problems: aliases defined in `.zprofile` only exist in
*login* shells, so they are missing from non-login interactive shells; and the
aliases silently shadow any same-named command on `PATH`.

Replace with a `bin/` directory of symlinks added to `PATH` — commands then
work everywhere, including in scripts and from `xargs`.
