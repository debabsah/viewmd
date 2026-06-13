# viewmd

A lightweight Markdown viewer and editor for macOS. Opens in a blink, renders beautifully, stays out of the way.

Reading a rendered Markdown file should not require launching an IDE. viewmd is a native app with one job: make .md files pleasant to read, with just enough editing for quick fixes.

## Features

- Native macOS app: instant launch, small footprint, follows system light/dark mode
- Notion-style shell: tabs in the titlebar, a collapsible and resizable file tree, edge-hover peek
- Whole-shell theming: eight bundled themes (Refined, Familiar, Paper, Dracula, Nord, Solarized, Catppuccin, One Dark) restyle the entire app, not just the document, plus your own CSS
- Font packs (Theme default, Serif, Mono) and a custom font picker, independent of themes
- The Aa panel: theme grid, appearance, fonts, size, width, spacing, code block style in one place
- GitHub-flavored Markdown with Mermaid diagrams and KaTeX math, fully offline
- Live reload: files re-render as they change on disk, scroll position preserved, with a live indicator
- Never clobbers your edits: external changes show a banner when you have unsaved work
- Toggle to source with Cmd+E, save with Cmd+S, full undo
- Welcome screen with recents, filter the tree with Cmd+P, find with Cmd+F
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
