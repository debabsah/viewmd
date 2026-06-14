import mermaid from 'mermaid'
import { createPipeline } from './pipeline.js'
import { sanitize } from './sanitize.js'
import { localImageURL } from './image-src.js'
import { computeAnchor, computeScrollTop, keyedHeadings, scrollTopForKey } from './scroll-anchor.js'

const pipeline = createPipeline()
let mermaidSeq = 0
let renderGen = 0

const docEl = () => document.getElementById('vmd-doc')
// text-node escaping only (& and <) — NOT safe for attribute contexts
const escText = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')

function post(message) {
  window.webkit?.messageHandlers?.viewmd?.postMessage(message)
}

function localizeImages() {
  for (const img of docEl().querySelectorAll('img')) {
    const url = localImageURL(img.getAttribute('src') || '')
    if (url) img.setAttribute('src', url)
  }
}

function collectHeadings() {
  const raw = Array.from(docEl().querySelectorAll('h1,h2,h3,h4,h5,h6')).map((el) => ({
    text: el.textContent.trim(),
    top: el.offsetTop,
    level: Number(el.tagName[1])
  }))
  return keyedHeadings(raw)
}

async function renderMermaidBlocks() {
  const dark = document.documentElement.dataset.code === 'dark'
  mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', theme: dark ? 'dark' : 'default' })
  for (const node of Array.from(document.querySelectorAll('pre.vmd-mermaid'))) {
    const src = node.textContent
    try {
      const { svg } = await mermaid.render(`vmd-mermaid-${mermaidSeq++}`, src)
      const fig = document.createElement('figure')
      fig.className = 'vmd-diagram'
      fig.innerHTML = svg
      node.replaceWith(fig)
    } catch (err) {
      const fall = document.createElement('div')
      fall.className = 'vmd-block-error'
      fall.innerHTML =
        `<p class="vmd-error-note">mermaid: ${escText(err?.message ?? err)}</p>` +
        `<pre>${escText(src)}</pre>`
      node.replaceWith(fall)
    }
  }
}

function applyAppearance(p) {
  const root = document.documentElement
  if (p.themeCSS !== undefined) document.getElementById('vmd-theme').textContent = p.themeCSS
  if (p.appearance) root.dataset.appearance = p.appearance        // "light" | "dark"
  const mode = p.codeBlocks ?? 'auto'                              // "auto" | "light" | "dark"
  root.dataset.code = mode === 'auto' ? root.dataset.appearance : mode
  const c = p.comfort ?? {}
  const set = (k, v) => v == null ? root.style.removeProperty(k) : root.style.setProperty(k, v)
  set('--vmd-font-body', c.fontFamily)
  set('--vmd-font-size', c.fontSize && `${c.fontSize}px`)
  set('--vmd-measure', c.lineWidth && `${c.lineWidth}px`)
  set('--vmd-leading', c.lineSpacing)
}

window.viewmd = {
  // payload: { text, appearance, codeBlocks, comfort, themeCSS, scroll }
  // scroll: { mode: "anchor" } preserves position across re-render (disk reload);
  // scroll: { mode: "absolute", top: N } restores a remembered position (tab switch);
  // omitted → scroll to top (fresh open).
  async render(payload) {
    const gen = ++renderGen
    const scroller = document.scrollingElement
    const anchor = payload.scroll?.mode === 'anchor'
      ? computeAnchor(collectHeadings(), scroller.scrollTop)
      : null
    applyAppearance(payload)
    const { html } = pipeline.render(payload.text ?? '')
    docEl().innerHTML = sanitize(html)   // strip scripts/handlers before display
    localizeImages()                     // route local image paths to the native handler
    await renderMermaidBlocks()
    if (gen !== renderGen) return   // a newer render superseded this pass
    if (anchor) scroller.scrollTop = computeScrollTop(collectHeadings(), anchor)
    else if (payload.scroll?.mode === 'absolute') scroller.scrollTop = payload.scroll.top
    else scroller.scrollTop = 0
    post({ type: 'headings', items: collectHeadings().map((h) => ({ key: h.key, level: h.level, text: h.text })) })
    post({ type: 'rendered' })
  },
  applyAppearance,
  scrollTop: () => document.scrollingElement.scrollTop,
  scrollToHeading(key) {
    const top = scrollTopForKey(collectHeadings(), key)
    document.scrollingElement.scrollTo({ top, behavior: 'smooth' })
  }
}

document.addEventListener('click', (e) => {
  const a = e.target.closest('a[href]')
  if (!a) return
  const href = a.getAttribute('href')
  if (href.startsWith('#')) return                      // in-page anchors: default
  e.preventDefault()
  if (/^https?:\/\//.test(href)) post({ type: 'openExternal', href })
  else post({ type: 'openRelative', href })             // e.g. ./other-doc.md
})

post({ type: 'ready' })
