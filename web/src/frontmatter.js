import yaml from 'js-yaml'

const esc = (s) => String(s)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;')
  .replace(/>/g, '&gt;').replace(/"/g, '&quot;')

function fmt(value) {
  if (Array.isArray(value)) return value.map(fmt).join(', ')
  if (value && typeof value === 'object') {
    return Object.entries(value).map(([k, v]) => `${k}: ${fmt(v)}`).join('; ')
  }
  return String(value)
}

export function renderFrontmatterCard(src) {
  let data
  try {
    data = yaml.load(src)
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
