import { test } from 'node:test'
import assert from 'node:assert/strict'
import { localImageURL } from '../src/image-src.js'

test('rewrites a relative path to the vmdimg scheme', () => {
  assert.equal(localImageURL('img/a.png'), 'vmdimg://local/?src=img%2Fa.png')
})

test('rewrites an absolute path', () => {
  assert.equal(localImageURL('/Users/x/a.png'), 'vmdimg://local/?src=%2FUsers%2Fx%2Fa.png')
})

test('strips a file:// prefix', () => {
  assert.equal(localImageURL('file:///Users/x/a.png'), 'vmdimg://local/?src=%2FUsers%2Fx%2Fa.png')
})

test('leaves remote, data, and blob urls untouched', () => {
  assert.equal(localImageURL('https://x/a.png'), null)
  assert.equal(localImageURL('http://x/a.png'), null)
  assert.equal(localImageURL('data:image/png;base64,AAAA'), null)
  assert.equal(localImageURL('blob:abc'), null)
})

test('leaves empty and already-rewritten src untouched', () => {
  assert.equal(localImageURL(''), null)
  assert.equal(localImageURL('vmdimg://local/?src=a.png'), null)
})
