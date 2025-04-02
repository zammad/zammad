// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import linkifyStr from 'linkify-string'
import { isEqual } from 'lodash-es'

export { htmlCleanup } from './htmlCleanup.ts'

type Falsy = false | 0 | '' | null | undefined
type IsTruthy<T> = T extends Falsy ? never : T

export const truthy = <T>(value: Maybe<T>): value is IsTruthy<T> => {
  return !!value
}

export const edgesToArray = <T>(
  object?: Maybe<{ edges?: Maybe<{ node: T }[]> }>,
): T[] => {
  return object?.edges?.map((edge) => edge.node) || []
}

export const normalizeEdges = <T>(
  object?: Maybe<{ edges?: { node: T }[]; totalCount?: number }>,
): { array: T[]; totalCount: number } => {
  const array = edgesToArray<T>(object)
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

export const textTruncate = (text: string, length = 100) => {
  if (!text) return text

  text = text.replace(/<([^>]+)>/g, '')

  if (text.length < length) return text

  return `${text.substring(0, length)}…`
}

export const debouncedQuery = <A extends unknown[], R>(
  fn: (...args: A) => Promise<R>,
  defaultValue: R,
  delay = 400,
) => {
  let timeout: number | undefined
  let lastResolve: (() => void) | null = null
  let lastResult = defaultValue
  return (...args: A): Promise<R> => {
    if (timeout) {
      lastResolve?.()
      clearTimeout(timeout)
    }
    return new Promise<R>((resolve, reject) => {
      lastResolve = () => resolve(lastResult)
      timeout = window.setTimeout(() => {
        fn(...args).then((result) => {
          lastResult = result
          resolve(result)
        }, reject)
      }, delay)
    })
  }
}

export const createDeferred = <T>() => {
  let resolve: (value: T | PromiseLike<T>) => void
  let reject: (reason?: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  return { resolve: resolve!, reject: reject!, promise }
}

export const waitForElement = async (
  query: string,
  tries = 60,
): Promise<Element | null> => {
  if (tries === 0) return null
  const element = document.querySelector(query)
  if (element) return element
  await new Promise((resolve) => requestAnimationFrame(resolve))
  return waitForElement(query, tries - 1)
}

/**
 * **Note:** @Generic T supports comparing arrays, array buffers, booleans,
 * date objects, error objects, maps, numbers, `Object` objects, regexes,
 * sets, strings, symbols, and typed arrays.
 * `Object` objects are compared
 * by their own, not inherited, enumerable properties.
 * Functions and DOM
 * nodes are **not** supported.
 * */
export const findChangedIndex = <T>(oldArray: T[], newArray: T[]) =>
  oldArray.findIndex((item, index) => !isEqual(item, newArray[index]))
