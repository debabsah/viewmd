import { test } from 'node:test'
import assert from 'node:assert/strict'
import { createPipeline } from '../src/pipeline.js'

const render = (text) => createPipeline().render(text).html

test('mermaid fence becomes a placeholder, not a highlighted code block', () => {
  const html = render('```mermaid\ngraph TD; A-->B\n```')
  assert.match(html, /<pre class="vmd-mermaid">graph TD; A--&gt;B/)
  assert.doesNotMatch(html, /hljs/)
})

test('inline math renders KaTeX markup', () => {
  assert.match(render('Euler: $e^{i\\pi} + 1 = 0$'), /class="katex"/)
})

test('block math renders display-mode KaTeX', () => {
  assert.match(render('$$\\int_0^1 x\\,dx$$'), /katex-display/)
})

test('invalid math does not throw and still produces output', () => {
  const html = render('broken: $\\frac{$ end')
  assert.ok(html.includes('broken:'))
  assert.match(html, /katex-error|katex/)
})

test('dollar amounts in prose are not eaten as math', () => {
  const html = render('costs $5 and $10 total')
  assert.match(html, /costs \$5 and \$10 total/)
})

test('mermaid fence with extra info words is still intercepted', () => {
  const html = render('```mermaid extra-words\ngraph TD; A-->B\n```')
  assert.match(html, /vmd-mermaid/)
})

test('MERMAID (uppercase) fence is intercepted', () => {
  const html = render('```MERMAID\ngraph TD; A-->B\n```')
  assert.match(html, /vmd-mermaid/)
})

test('mermaid body with </pre> close-tag is escaped, not injected', () => {
  const html = render('```mermaid\n</pre><script>alert(1)</script>\n```')
  assert.doesNotMatch(html, /<script>/)
  assert.match(html, /&lt;\/pre&gt;/)
})
