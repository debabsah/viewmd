import yaml from 'js-yaml'

// no ' escape needed: all generated attributes are double-quoted
const esc = (s) => String(s)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;')
  .replace(/>/g, '&gt;').replace(/"/g, '&quot;')

function fmt(value, seen = new WeakSet()) {
  if (Array.isArray(value)) return value.map(v => fmt(v, seen)).join(', ')
  if (value && typeof value === 'object') {
    if (seen.has(value)) return '[circular]'
    seen.add(value)
    return Object.entries(value).map(([k, v]) => `${k}: ${fmt(v, seen)}`).join('; ')
  }
  return String(value)
}

export function renderFrontmatterCard(src) {
  let data
  try {
    data = yaml.load(src, { schema: yaml.CORE_SCHEMA })
  } catch {
    data = null
  }
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return `<details class="vmd-frontmatter"><summary>metadata</summary>` +
      `<pre class="vmd-frontmatter-raw">${esc(src)}</pre></details>`
  }
  const rows = Object.entries(data)
    .map(([k, v]) => `<tr><th>${esc(k)}</th><td>${esc(fmt(v))}</td></tr>`)
    .join('')
  return `<details class="vmd-frontmatter"><summary>metadata</summary>` +
    `<table>${rows}</table></details>`
}
