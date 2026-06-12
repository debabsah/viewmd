import { build } from 'esbuild'
import { cpSync, copyFileSync, mkdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, resolve } from 'node:path'

// resolve against this file's directory so the script works from any cwd
const root = dirname(fileURLToPath(import.meta.url))
const r = (...p) => resolve(root, ...p)

mkdirSync(r('dist'), { recursive: true })

await build({
  entryPoints: [r('src/render.js')],
  bundle: true,
  minify: true,
  format: 'iife',
  outfile: r('dist/render.js'),
  logLevel: 'info'
})

copyFileSync(r('template.html'), r('dist/template.html'))
cpSync(r('themes'), r('dist/themes'), { recursive: true })
copyFileSync(r('themes/base.css'), r('dist/base.css'))
mkdirSync(r('dist/katex'), { recursive: true })
copyFileSync(r('node_modules/katex/dist/katex.min.css'), r('dist/katex/katex.min.css'))
cpSync(r('node_modules/katex/dist/fonts'), r('dist/katex/fonts'), { recursive: true })
copyFileSync(r('dev/preview.html'), r('dist/preview.html'))
