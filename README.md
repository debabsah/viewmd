# viewmd

**A fast, native Markdown viewer for macOS, built for the age of AI.**

AI tools now generate Markdown all day long: plans, specs, reports, READMEs, research notes, runbooks, often packed with tables, diagrams, and math. We read far more of it than we write. Yet looking at a rendered `.md` file still usually means launching a heavy editor or a whole IDE just to view it.

viewmd fixes that. Think of it as Preview for Markdown: open, read, done. It opens in a blink, renders beautifully, browses entire folders, themes the whole app to your taste, and refreshes the instant a file changes on disk. And it stays out of the way: native code, no Electron, fully offline, and light on memory.

<!-- Maintainer note: add a hero screenshot (a rendered doc with the sidebar and outline), a theme gallery, and a Quick Look shot here before publishing. -->

## Designed as a viewer, not an editor

In the AI era the job changed. Most of the time you are reviewing output, not typing prose. So viewmd is viewer-first: it shows the rendered document by default, edge to edge, the way it is meant to be read. Editing is still one keystroke away (toggle to source with Cmd+E for a quick fix and save), but reading comes first.

That is also why live reload is built in, not bolted on. When an AI agent or a build step rewrites a file, viewmd re-renders it automatically and keeps your scroll position, with a small indicator so you know it refreshed. You watch your documents change in real time instead of reopening them. And if you have unsaved edits when a file changes underneath you, viewmd shows a banner rather than overwriting your work.

## Features

**Reading**
- GitHub Flavored Markdown, rendered edge to edge
- Mermaid diagrams and KaTeX math, inline and fully offline
- Raw HTML rendered and sanitized, so README banners, tables, and `<details>` blocks display like they do on GitHub
- Frontmatter shown as a clean card
- Document outline: jump to any heading from the sidebar
- Reading statistics: word count and reading time, always in view

**Live and safe**
- Live reload: files re-render as they change on disk, scroll position preserved, with a watch indicator
- Never clobbers your edits: external changes raise a banner instead of overwriting unsaved work

**Workspace**
- A collapsible, resizable file tree for browsing a whole folder
- Tabs in the title bar, a persistent sidebar toggle, and Files / Outline panes
- Filter the tree (Cmd+P), find in the document (Cmd+F), and a home screen with recents
- Quick Look: press Space on a `.md` file in Finder to see it rendered, not as raw source

**Make it yours**
- Whole-shell theming: eight bundled themes restyle the entire app, not just the document
- Font packs (Theme default, Serif, Mono) and a custom font picker
- Your own CSS and a small set of power-user settings (see Customization)

**Share and integrate**
- Export to PDF, print, or copy as HTML or rich text
- Open from the command line: `viewmd notes.md`, `viewmd docs/`, or bare `viewmd` for the current folder
- Set viewmd as the default app for `.md` files

**Light editing**
- Toggle to source with Cmd+E, save with Cmd+S, full undo

## Why it stays lightweight

viewmd is native macOS code, not a web app in a wrapper. It launches instantly and sips memory, where Electron based viewers routinely use hundreds of megabytes for the same job. The Markdown engine (GitHub Flavored Markdown, Mermaid, KaTeX, syntax highlighting) is bundled and runs entirely offline, so rendering is fast and nothing depends on the network. The reading experience is the one place we spend the weight, and the rest of the app is kept deliberately small.

## Install

Prebuilt, notarized releases are on the way. For now, build from source.

Requirements: macOS 14 or newer, Xcode 15 or newer, Node 18 or newer, and XcodeGen (`brew install xcodegen`).

```sh
make app    # build the web pipeline and the app
make run    # build and launch
make test   # run the JavaScript and Swift test suites
```

The built app lands in `.build/Build/Products/Release/viewmd.app`. Copy it to `/Applications`.

## Getting started

Open a document any way you like:
- Double-click a `.md` file (after setting viewmd as the default handler in Settings)
- Drag a file or folder onto the window
- Run `viewmd path/to/file.md` or `viewmd path/to/folder` from the terminal
- Use File > Open or File > Open Folder

Open Settings (Cmd+,) to install the `viewmd` command line tool and to make viewmd the default app for `.md` files.

## Customization

Open the Aa panel (Theme & display) from the sidebar to switch themes, appearance, fonts, reading width, and code block style. The whole window restyles, not just the document.

Custom themes: drop a `.css` file into `~/Library/Application Support/viewmd/themes` and it appears in the theme picker. The first line must be:

```css
/* viewmd-theme: My Theme; appearances: light,dark */
```

Define page colors under `[data-appearance="light"]` and `[data-appearance="dark"]`, and code block colors under `[data-code="light"]` and `[data-code="dark"]`. See any bundled theme in `web/themes/` for the variable names.

Two optional files live in `~/Library/Application Support/viewmd/`, both seeded with examples on first launch:
- `user.css`: any CSS here is applied on top of the active theme, so your rules win. Edits apply on the next render.
- `settings.json`: a small set of power-user keys, for example a default open directory and the large-file threshold.

## Keyboard shortcuts

| Action | Shortcut |
|---|---|
| Open file | Cmd+O |
| Open folder | Cmd+Shift+O |
| Filter files | Cmd+P |
| Find in document | Cmd+F |
| Toggle sidebar | Cmd+B |
| Show outline | Cmd+Ctrl+O |
| Toggle edit mode | Cmd+E |
| Save | Cmd+S |
| Close tab | Cmd+W |
| Zoom in / out / reset | Cmd++ / Cmd+- / Cmd+0 |
| Settings | Cmd+, |

## Privacy

viewmd renders everything on your machine, offline. It does not phone home and collects no analytics. Your files never leave your computer.

## Contributing

Issues and pull requests are welcome. Build and test instructions are above. viewmd is intentionally focused on being the best Markdown reader on macOS, so changes that widen the reading experience or keep the app lean are the easiest to land.

## License

viewmd will be released as open source. The license is being finalized.
