import { test } from 'node:test'
import assert from 'node:assert/strict'
import { createPipeline } from '../src/pipeline.js'

const render = (text) => createPipeline().render(text).html

test('renders GFM table', () => {
  const html = render('| a | b |\n|---|---|\n| 1 | 2 |')
  assert.match(html, /<table>/)
  assert.match(html, /<td>1<\/td>/)
})

test('renders task list with checkboxes', () => {
  const html = render('- [x] done\n- [ ] todo')
  assert.match(html, /type="checkbox"/)
  assert.match(html, /checked/)
})

test('renders strikethrough', () => {
  assert.match(render('~~gone~~'), /<s>gone<\/s>/)
})

test('autolinks bare URLs', () => {
  assert.match(render('see https://example.com'), /<a href="https:\/\/example.com">/)
})

test('highlights fenced code for known language', () => {
  const html = render('```swift\nlet x = 1\n```')
  assert.match(html, /class="hljs language-swift"/)
  assert.match(html, /hljs-keyword/)
})

test('unknown language falls back to escaped plain block', () => {
  const html = render('```nosuchlang\n<b>&\n```')
  assert.match(html, /&lt;b&gt;&amp;/)
  assert.doesNotMatch(html, /<b>&/)
})

test('raw HTML in markdown is escaped, not executed', () => {
  const html = render('<script>alert(1)</script>')
  assert.doesNotMatch(html, /<script>/)
})

test('heading and inline code render', () => {
  const html = render('# Title\n\nuse `npm test` here')
  assert.match(html, /<h1>Title<\/h1>/)
  assert.match(html, /<code>npm test<\/code>/)
})

test('hostile fence info string cannot break out of the class attribute', () => {
  const html = render('```js"><img src=x onerror=alert(1)>\nx\n```')
  assert.doesNotMatch(html, /<img/)
})

test('pipeline instance does not leak frontmatter across renders', () => {
  const p = createPipeline()
  p.render('---\ntitle: First\n---\nbody')
  const second = p.render('plain body')
  assert.equal(second.frontmatterSource, null)
  assert.doesNotMatch(second.html, /vmd-frontmatter/)
})
