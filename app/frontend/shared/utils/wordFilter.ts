// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// TODO: add test for this
// (C) sbrin - https://github.com/sbrin
// https://gist.github.com/sbrin/6801034
export const wordFilter = (editor: Element) => {
  let content = editor.innerHTML

  // Word comments like conditional comments etc
  content = content.replace(/<!--[\s\S]+?-->/gi, '')

  // Remove comments, scripts (e.g., msoShowComment), XML tag, VML content,
  // MS Office namespaced tags, and a few other tags
  content = content.replace(
    // eslint-disable-next-line security/detect-unsafe-regex
    /<(!|script[^>]*>.*?<\/script(?=[>\s])|\/?(\?xml(:\w+)?|img|meta|link|style|\w:\w+)(?=[\s/>]))[^>]*>/gi,
    '',
  )

  // Convert <s> into <strike> for line-though
  content = content.replace(/<(\/?)s>/gi, '<$1strike>')

  // Replace nbsp entites to char since it's easier to handle
  // content = content.replace(/&nbsp;/gi, "\u00a0");
  content = content.replace(/&nbsp;/gi, ' ')

  // Convert <span style="mso-spacerun:yes">___</span> to string of alternating
  // breaking/non-breaking spaces of same length
  content = content.replace(
    /<span\s+style\s*=\s*"\s*mso-spacerun\s*:\s*yes\s*;?\s*"\s*>([\s\u00a0]*)<\/span>/gi,
    (str, spaces) => {
      return spaces.length > 0
        ? spaces
            .replace(/./, ' ')
            .slice(Math.floor(spaces.length / 2))
            .split('')
            .join('\u00a0')
        : ''
    },
  )

  editor.innerHTML = content

  // Parse out list indent level for lists
  editor.querySelectorAll('p').forEach((p) => {
    const style = p.getAttribute('style')
    if (!style) return
    const matches = /mso-list:\w+ \w+([0-9]+)/.exec(style)
    if (matches) {
      p.dataset._listLevel = parseInt(matches[1], 10).toString()
    }
  })

  // Parse Lists
  let lastLevel = 0
  let parent: null | Element = null

  // eslint-disable-next-line sonarjs/cognitive-complexity
  editor.querySelectorAll('p').forEach((p) => {
    const curLevel = Number(p.dataset._listLevel || -1)
    if (curLevel < 0) {
      lastLevel = 0
      return
    }
    const text = p.textContent || ''
    let listTag = '<ul></ul>'
    if (/^\s*\w+\./.test(text)) {
      const matches = /([0-9])\./.exec(text)
      if (matches) {
        const start = parseInt(matches[1], 10)
        listTag = start > 1 ? `<ol start="${start}"></ol>` : '<ol></ol>'
      } else {
        listTag = '<ol></ol>'
      }
    }
    if (curLevel > lastLevel) {
      const el = document.createElement('div')
      el.innerHTML = listTag
      const li = el.firstChild as HTMLLIElement
      if (lastLevel === 0) {
        p.before(li)
        parent = p.previousElementSibling
      } else {
        p.append(li)
        parent = p.lastElementChild
      }
    }
    if (curLevel < lastLevel) {
      for (let i = 0; i < lastLevel - curLevel; i += 1) {
        parent = parent?.parentElement || null
      }
    }
    p.querySelector('span')?.remove()
    parent?.append(`<li>${p.innerHTML}</li>`)
    p.remove()
    lastLevel = curLevel
  })

  const removeAttr = (selector: string, attribute: string) => {
    editor.querySelectorAll(selector).forEach((element) => {
      element.removeAttribute(attribute)
    })
  }
  const remove = (selector: string) => {
    editor.querySelectorAll(selector).forEach((element) => element.remove())
  }

  // style and align is handled by utils.coffee it self, don't clean it here
  removeAttr('[style]', 'style')
  removeAttr('[align]', 'align')
  editor.querySelectorAll('span').forEach((element) => {
    element.replaceWith(...Array.from(element.childNodes))
  })
  remove('span:empty')
  removeAttr("[class^='Mso']", 'class')
  remove('p:empty')
  return editor
}
