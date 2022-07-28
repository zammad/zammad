// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import linkify from 'linkify-html'

export const mergeArray = <T extends unknown[]>(a: T, b: T) => {
  return [...new Set([...a, ...b])]
}

export const waitForAnimationFrame = () => {
  return new Promise((resolve) => requestAnimationFrame(resolve))
}

export const textCleanup = (ascii: string) => {
  if (!ascii) return ''

  return ascii
    .trim()
    .replace(/(\r\n|\n\r)/g, '\n') // cleanup
    .replace(/\r/g, '\n') // cleanup
    .replace(/[ ]\n/g, '\n') // remove tailing spaces
    .replace(/\n{3,20}/g, '\n\n') // remove multiple empty lines
}

// taken from App.Utils.text2html for consistency
export const textToHtml = (text: string) => {
  text = textCleanup(text)
  text = linkify(text)
  text = text.replace(/(\n\r|\r\n|\r)/g, '\n')
  text = text.replace(/ {2}/g, ' &nbsp;')
  text = `<div>${text.replace(/\n/g, '</div><div>')}</div>`
  return text.replace(/<div><\/div>/g, '<div><br></div>')
}

export const humanizaFileSize = (size: number) => {
  if (size > 1024 * 1024) {
    return `${Math.round((size * 10) / (1024 * 1024)) / 10} MB`
  }
  if (size > 1024) {
    return `${Math.round(size / 1024)} KB`
  }
  return `${size} Bytes`
}
