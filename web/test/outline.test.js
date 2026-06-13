import { test } from 'node:test'
import assert from 'node:assert/strict'
import { keyedHeadings, scrollTopForKey } from '../src/scroll-anchor.js'

test('keyedHeadings assigns text#occurrence keys and preserves level/text/top', () => {
  const out = keyedHeadings([
    { text: 'Intro', level: 1, top: 0 },
    { text: 'Design', level: 2, top: 100 },
    { text: 'Design', level: 2, top: 300 }   // duplicate text -> second occurrence
  ])
  assert.deepEqual(out.map((h) => h.key), ['Intro#0', 'Design#0', 'Design#1'])
  assert.equal(out[1].level, 2)
  assert.equal(out[2].text, 'Design')
  assert.equal(out[0].top, 0)
})

test('scrollTopForKey resolves a known key to its offset', () => {
  const headings = [
    { key: 'Intro#0', top: 0 },
    { key: 'Design#0', top: 420 }
  ]
  assert.equal(scrollTopForKey(headings, 'Design#0'), 420)
})

test('scrollTopForKey returns 0 for an unknown key', () => {
  assert.equal(scrollTopForKey([{ key: 'A#0', top: 50 }], 'Missing#0'), 0)
})
