export function computeAnchor(headings, scrollTop) {
  let last = null
  for (const h of headings) {
    if (h.top <= scrollTop) last = h
    else break
  }
  return last
    ? { key: last.key, delta: scrollTop - last.top }
    : { key: null, delta: scrollTop }
}

export function computeScrollTop(headings, anchor) {
  if (!anchor) return 0
  if (anchor.key === null) return anchor.delta
  const h = headings.find((x) => x.key === anchor.key)
  return h ? h.top + anchor.delta : anchor.delta
}

// Assign stable keys to headings by (text, occurrence). Pure and DOM-free so
// the outline panel's key logic is testable without a browser. Extra fields
// (top, level, text) pass through untouched.
export function keyedHeadings(raw) {
  const counts = Object.create(null)
  return raw.map((h) => {
    const n = counts[h.text] = (counts[h.text] ?? -1) + 1
    return { ...h, key: `${h.text}#${n}` }
  })
}

// Resolve a heading key to its scroll offset (delta 0). Backs scrollToHeading.
export function scrollTopForKey(headings, key) {
  return computeScrollTop(headings, { key, delta: 0 })
}
