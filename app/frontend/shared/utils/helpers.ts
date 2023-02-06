// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import linkifyStr from 'linkify-string'

export { htmlCleanup } from './htmlCleanup'

type Falsy = false | 0 | '' | null | undefined
type IsTruthy<T> = T extends Falsy ? never : T

export const truthy = <T>(value: Maybe<T>): value is IsTruthy<T> => {
  return !!value
}

export const edgesToArray = <T>(
  object?: Maybe<{ edges?: { node: T }[] }>,
): T[] => {
  return object?.edges?.map((edge) => edge.node) || []
}

export const normalizeEdges = <T>(
  object?: Maybe<{ edges?: { node: T }[]; totalCount?: number }>,
): { array: T[]; totalCount: number } => {
  const array = edgesToArray(object)
  return {
    array,
    totalCount: object?.totalCount ?? array.length,
  }
}

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
  text = linkifyStr(text)
  text = text.replace(/(\n\r|\r\n|\r)/g, '\n')
  text = text.replace(/ {2}/g, ' &nbsp;')
  text = `<div>${text.replace(/\n/g, '</div><div>')}</div>`
  return text.replace(/<div><\/div>/g, '<div><br></div>')
}

export const humanizeFileSize = (size: number) => {
  if (size > 1024 * 1024) {
    return `${Math.round((size * 10) / (1024 * 1024)) / 10} MB`
  }
  if (size > 1024) {
    return `${Math.round(size / 1024)} KB`
  }
  return `${size} Bytes`
}
