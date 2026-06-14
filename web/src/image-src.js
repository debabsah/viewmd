// Rewrite a Markdown image `src` to viewmd's local-image scheme so the native
// handler can serve it from the open document's folder. Remote, data, blob, and
// already-rewritten URLs are left alone (returns null). A leading file:// is
// stripped so absolute file URLs resolve too.
export function localImageURL(src) {
  if (!src || /^(https?:|data:|blob:|vmdimg:)/i.test(src)) return null
  const path = src.replace(/^file:\/\//, '')
  return 'vmdimg://local/?src=' + encodeURIComponent(path)
}
