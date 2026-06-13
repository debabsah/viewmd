import { test } from 'node:test'
import assert from 'node:assert/strict'
import { JSDOM } from 'jsdom'
import createDOMPurify from 'dompurify'

// render.js calls DOMPurify in the WKWebView; here we drive it with a jsdom
// window and assert the guarantees render.js relies on.
const DOMPurify = createDOMPurify(new JSDOM('').window)
const clean = (html) => DOMPurify.sanitize(html, { ADD_ATTR: ['target'] })

test('strips script tags', () => {
  assert.ok(!clean('<p>hi</p><script>alert(1)</script>').includes('<script'))
})

test('strips inline event handlers', () => {
  assert.ok(!clean('<img src=x onerror="alert(1)">').toLowerCase().includes('onerror'))
})

test('strips javascript: urls', () => {
  assert.ok(!clean('<a href="javascript:alert(1)">x</a>').toLowerCase().includes('javascript:'))
})

test('keeps a raw pre block (the ascii banner case)', () => {
  const out = clean('<pre>  _   _\n |_| |_|</pre>')
  assert.match(out, /<pre>/)
})

test('keeps img, details, sub/sup, and tables', () => {
  assert.match(clean('<img src="https://x/y.png">'), /<img/)
  assert.match(clean('<details><summary>s</summary>b</details>'), /<details>/)
  assert.match(clean('<sub>a</sub><sup>b</sup>'), /<sub>/)
  assert.match(clean('<table><tr><td>a</td></tr></table>'), /<td>/)
})

test('keeps the Mermaid placeholder element and its class', () => {
  assert.match(clean('<pre class="vmd-mermaid">graph TD; A--&gt;B</pre>'), /class="vmd-mermaid"/)
})

test('keeps KaTeX span and MathML markup', () => {
  const katex = '<span class="katex"><math><semantics><mrow><mi>x</mi></mrow></semantics></math></span>'
  const out = clean(katex)
  assert.match(out, /class="katex"/)
  assert.match(out, /<mi>x<\/mi>/)
})
