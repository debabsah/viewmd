import MarkdownIt from 'markdown-it'
import taskLists from 'markdown-it-task-lists'
import frontMatter from 'markdown-it-front-matter'
import hljs from 'highlight.js/lib/common'
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
    html: false,        // raw HTML stays escaped — agent output is untrusted
    linkify: true,
    highlight
  })
  md.use(taskLists, { enabled: false }) // render checkboxes, keep them inert
  md.use(frontMatter, (fm) => { state.frontmatter = fm })

  return {
    render(text) {
      state.frontmatter = null
      const body = md.render(text)
      const card = state.frontmatter ? renderFrontmatterCard(state.frontmatter) : ''
      return { html: card + body, frontmatterSource: state.frontmatter }
    }
  }
}
