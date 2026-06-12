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
})

test('dollar amounts in prose are not eaten as math', () => {
  const html = render('costs $5 and $10 total')
  assert.match(html, /costs \$5 and \$10 total/)
})
