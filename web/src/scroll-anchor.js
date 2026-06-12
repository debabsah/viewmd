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
