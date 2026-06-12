import { test } from 'node:test'
import assert from 'node:assert/strict'
import { createPipeline } from '../src/pipeline.js'
import { renderFrontmatterCard } from '../src/frontmatter.js'

test('frontmatter renders as collapsible card, not body text', () => {
  const { html } = createPipeline().render(
    '---\ntitle: Spec\ntags:\n  - alpha\n  - beta\n---\n# Hi'
  )
  assert.match(html, /<details class="vmd-frontmatter">/)
  assert.match(html, /<th>title<\/th>/)
  assert.match(html, /<td>Spec<\/td>/)
  assert.match(html, /<td>alpha, beta<\/td>/)
  assert.match(html, /<h1>Hi<\/h1>/)
  // the YAML must not leak into the rendered body
  assert.doesNotMatch(html, /<p>title: Spec/)
})

test('nested objects flatten to key: value pairs', () => {
  const html = renderFrontmatterCard('meta:\n  owner: deb\n  version: 2')
  assert.match(html, /owner: deb; version: 2/)
})

test('values are HTML-escaped', () => {
  const html = renderFrontmatterCard('title: <b>bold</b>')
  assert.match(html, /&lt;b&gt;bold&lt;\/b&gt;/)
  assert.doesNotMatch(html, /<b>bold/)
})

test('malformed YAML falls back to raw escaped block', () => {
  const html = renderFrontmatterCard('{ this is : not yaml ::')
  assert.match(html, /vmd-frontmatter-raw/)
})

test('document without frontmatter gets no card', () => {
  const { html } = createPipeline().render('# Hi')
  assert.doesNotMatch(html, /vmd-frontmatter/)
})

test('date values are displayed, not silently dropped', () => {
  const html = renderFrontmatterCard('published: 2024-01-15')
  assert.match(html, /2024/)
  assert.doesNotMatch(html, /<td><\/td>/)
})

test('circular YAML aliases do not crash the renderer', () => {
  const html = renderFrontmatterCard('a: &a\n  b: *a')
  assert.match(html, /circular/)
})
