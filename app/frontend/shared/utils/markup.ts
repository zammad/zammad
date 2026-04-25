// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { escape } from 'lodash-es'

// to be compatible with app/assets/javascripts/app/lib/app_post/i18n.coffee:267
export const markup = (source: string): string =>
  escape(source)
    .replace(/\|\|(.+?)\|\|/gm, '<i>$1</i>')
    .replace(/\|(.+?)\|/gm, '<b>$1</b>')
    .replace(/_(.+?)_/gm, '<u>$1</u>')
    .replace(/\/\/(.+?)\/\//gm, '<del>$1</del>')
    .replace(/§(.+?)§/gm, '<kbd>$1</kbd>')
    .replace(/¶/gm, '<br>')
    .replace(
      /\[(.+?)\]\((.+?)\)/gm,
      '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>',
    )

export const cleanupMarkup = (source: string): string =>
  source
    .replace(/\|\|(.+?)\|\|/gm, '$1')
    .replace(/\|(.+?)\|/gm, '$1')
    .replace(/_(.+?)_/gm, '$1')
    .replace(/\/\/(.+?)\/\//gm, '$1')
    .replace(/§(.+?)§/gm, '$1')
    .replace(/¶/gm, '')
    .replace(/\[(.+?)\]\((.+?)\)/gm, '$1')

export const normalizeImageSizingInHtml = (html: string) => {
  let processedHtml = html.replace(
    /<img([^>]*)>/g,
    (_, attrs) => `<img${attrs} class="object-contain">`,
  )

  // Update inline styles
  processedHtml = processedHtml.replace(/<img([^>]*)style="([^"]*)"/g, (_, beforeAttrs, style) => {
    let newStyle = style
    const width = style.match(/width:\s*([^;]+)/)?.[1]
    const height = style.match(/height:\s*([^;]+)/)?.[1]

    if (width) {
      newStyle = newStyle
        .replace(/width:\s*[^;]+/, 'width:100%')
        .replace(/height:\s*[^;]+/, 'height:100%')
        .concat(`;max-width:${width}`)
    }

    if (height) {
      newStyle = newStyle.replace(/height:\s*[^;]+/, 'height:100%').concat(`;max-height:${height}`)
    }

    // It is just the serialized attribute list;
    // the helper that creates it deliberately omits the trailing >.
    // The template later appends the closing > (or />), so class="object-contain"
    // is still inside the <img …> tag. If you inserted > before the class,
    // you’d end up with <img …> class="object-contain", which would sit outside the element.
    return `<img${beforeAttrs}style="${newStyle}"`
  })

  return processedHtml
}
