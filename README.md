# viewmd

A lightweight Markdown viewer and editor for macOS. Opens in a blink, renders beautifully, stays out of the way.

Reading a rendered Markdown file should not require launching an IDE. viewmd is a native app with one job: make .md files pleasant to read, with just enough editing for quick fixes.

## Features

- Native macOS app: instant launch, small footprint, follows system light/dark mode
- GitHub-flavored Markdown: tables, task lists, strikethrough, syntax-highlighted code
- Mermaid diagrams and KaTeX math rendered inline, fully offline
- YAML frontmatter shown as a tidy collapsible card
- Live reload: files re-render as they change on disk, scroll position preserved
- Never clobbers your edits: external changes show a banner when you have unsaved work
- Workspace mode: open a folder, browse its Markdown tree, switch files in tabs
- Toggle to source with Cmd+E, save with Cmd+S, full undo
- Reading comfort popover: theme, font, size, line width, spacing, code block style
- Eight bundled themes (Refined, Familiar, Paper, Dracula, Nord, Solarized, Catppuccin, One Dark) plus your own CSS
- CLI: `viewmd notes.md`, `viewmd docs/`, or bare `viewmd` for the current folder

## Build

Requirements: Xcode 15 or newer, Node 18 or newer, XcodeGen (`brew install xcodegen`).

```sh
make app    # build web pipeline + app
make run    # build and launch
make test   # JS golden tests + Swift suite
```

The built app lands in `.build/Build/Products/Release/viewmd.app`. Copy it to `/Applications`.

## Setup

Open Settings (Cmd+,) to install the `viewmd` CLI on your PATH and to make viewmd the default app for .md files.

## Custom themes

Drop a `.css` file into `~/Library/Application Support/viewmd/themes` and it appears in the theme picker. First line must be:

```css
/* viewmd-theme: My Theme; appearances: light,dark */
```

Define page colors under `[data-appearance="light"]` / `[data-appearance="dark"]` and code block colors under `[data-code="light"]` / `[data-code="dark"]`. See any bundled theme in `web/themes/` for the variable names.
