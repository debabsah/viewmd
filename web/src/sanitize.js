import DOMPurify from 'dompurify'

// markdown-it runs with html:true so GitHub-style raw HTML (banners, <details>,
// <img>, tables, <sub>/<sup>) renders. That HTML is untrusted (agent/README
// output), so every rendered string is passed through DOMPurify before it
// touches the DOM. DOMPurify's defaults keep the HTML, SVG, and MathML element
// sets that KaTeX and the Mermaid placeholder need, while stripping <script>,
// on* event handlers, javascript: URLs, and other XSS vectors.
//
// In the WKWebView a window exists, so the default import is already bound and
// `DOMPurify.sanitize` works directly.
export function sanitize(html) {
  return DOMPurify.sanitize(html, { ADD_ATTR: ['target'] })
}
