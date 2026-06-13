import MarkdownIt from 'markdown-it'
import taskLists from 'markdown-it-task-lists'
import frontMatter from 'markdown-it-front-matter'
import hljs from 'highlight.js/lib/common'
import katex from '@vscode/markdown-it-katex'
import { renderFrontmatterCard } from './frontmatter.js'

function highlight(code, lang) {
  if (lang && hljs.getLanguage(lang)) {
    try {
      const value = hljs.highlight(code, { language: lang, ignoreIllegals: true }).value
      return `<pre><code class="hljs language-${lang}">${value}</code></pre>`
    } catch {
      // fall through to default escaping
    }
  }
  return '' // markdown-it escapes and wraps the block itself
}

export function createPipeline() {
  const state = { frontmatter: null }

  const md = new MarkdownIt({
    html: true,         // render raw HTML (banners, <details>, <img>, tables…)
    linkify: true,      // the renderer sanitizes the output with DOMPurify
    highlight
  })
  md.use(taskLists, { enabled: false }) // render checkboxes, keep them inert
  md.use(frontMatter, (fm) => { state.frontmatter = fm })
  md.use(katex.default?.default ?? katex.default ?? katex, { throwOnError: false, errorColor: '#cc0000' })

  const defaultFence = md.renderer.rules.fence
  md.renderer.rules.fence = (tokens, idx, options, env, self) => {
    const token = tokens[idx]
    if (token.info.trim().split(/\s+/)[0].toLowerCase() === 'mermaid') {
      return `<pre class="vmd-mermaid">${md.utils.escapeHtml(token.content)}</pre>\n`
    }
    return defaultFence(tokens, idx, options, env, self)
  }

  return {
    render(text) {
      state.frontmatter = null
      const body = md.render(text)
      const card = state.frontmatter ? renderFrontmatterCard(state.frontmatter) : ''
      return { html: card + body, frontmatterSource: state.frontmatter }
    }
  }
}
