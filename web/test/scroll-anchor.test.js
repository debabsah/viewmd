import { test } from 'node:test'
import assert from 'node:assert/strict'
import { computeAnchor, computeScrollTop } from '../src/scroll-anchor.js'

// headings: [{ key, top }] sorted by top, as extracted from the DOM
const headings = [
  { key: 'Intro#0', top: 100 },
  { key: 'Design#0', top: 500 },
  { key: 'Design#1', top: 900 }   // duplicate heading text, second occurrence
]

test('anchor is the nearest heading above the scroll position', () => {
  assert.deepEqual(computeAnchor(headings, 620), { key: 'Design#0', delta: 120 })
})

test('scrolled above the first heading anchors to absolute offset', () => {
  assert.deepEqual(computeAnchor(headings, 40), { key: null, delta: 40 })
})

test('duplicate heading texts resolve by occurrence', () => {
  assert.deepEqual(computeAnchor(headings, 950), { key: 'Design#1', delta: 50 })
})

test('restore finds the heading at its new position', () => {
  const moved = [{ key: 'Intro#0', top: 100 }, { key: 'Design#0', top: 800 }]
  assert.equal(computeScrollTop(moved, { key: 'Design#0', delta: 120 }), 920)
})

test('restore with null key returns absolute offset', () => {
  assert.equal(computeScrollTop(headings, { key: null, delta: 40 }), 40)
})

test('restore when the heading vanished falls back to delta', () => {
  assert.equal(computeScrollTop(headings, { key: 'Gone#0', delta: 75 }), 75)
})

test('restore with no anchor returns 0', () => {
  assert.equal(computeScrollTop(headings, null), 0)
})
