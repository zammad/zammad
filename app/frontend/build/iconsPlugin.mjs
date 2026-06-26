// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { readFile } from 'node:fs/promises'
import { basename } from 'node:path'

import { optimize } from 'svgo'

/**
 * Wrap an optimized <svg> string as a sprite <symbol>, preserving geometry.
 * @param {string} svg
 * @param {string} name
 * @returns {string}
 */
const svgToSymbol = (svg, name) => {
  const open = svg.match(/<svg\b[^>]*>/)
  if (!open) throw new Error(`No <svg> root found for icon "${name}"`)

  const geometry = ['viewBox'] // ignore width/height, as they are not needed for <symbol> and can break scaling
    .map((attr) => open[0].match(new RegExp(`\\s${attr}="[^"]*"`)))
    .filter(Boolean)
    .map((match) => match[0])
    .join('')

  const inner = svg.slice(open.index + open[0].length).replace(/<\/svg>\s*$/, '')

  return `<symbol id="icon-${name}"${geometry}>${inner}</symbol>`
}

export default () => ({
  name: 'zammad-plugin-svgo',
  enforce: 'pre',
  /**
   * @param {string} id
   * @returns {Promise<{code: string} | undefined>}
   */
  async load(id) {
    if (!id.endsWith('.svg?symbol')) return undefined

    const filepath = id.replace(/\?.*$/, '')
    // Re-run this hook when the source SVG changes (HMR / watch mode).
    this.addWatchFile(filepath)

    const name = basename(filepath, '.svg')
    const content = await readFile(filepath, 'utf-8')

    let data
    try {
      // prefixIds runs after preset-default so it prefixes the ids that
      // cleanupIds minified (a -> icon-<name>_a). All symbols are merged into
      // a single DOM sprite (see injectIcons.ts), so per-symbol prefixes are
      // what keep gradient/clipPath ids collision-free.
      ;({ data } = optimize(content, {
        path: filepath,
        plugins: [
          { name: 'preset-default' },
          { name: 'prefixIds', params: { prefix: `icon-${name}`, delim: '_' } },
        ],
      }))
    } catch (error) {
      throw new Error(`Failed to optimize SVG "${filepath}": ${error.message}`)
    }

    // JSON.stringify avoids breaking the module if SVG content contains
    // backticks, ${ or backslashes.
    return { code: `export default ${JSON.stringify(svgToSymbol(data, name))}` }
  },
})
