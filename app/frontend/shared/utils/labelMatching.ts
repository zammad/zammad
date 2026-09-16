// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { escapeRegExp } from 'lodash-es'

export interface LabelMatchFragments {
  before: string
  matched: string
  after: string
}

// Must stay non-global: `.test()` on a global regex carries `lastIndex` between calls.
const combiningMark = /[\u0300-\u036f]/
const combiningMarks = /[\u0300-\u036f]/g

/**
 * Strips combining marks, so a search keyword matches its accented counterpart and vice-versa.
 */
export const deaccent = (text: string) => text.normalize('NFD').replace(combiningMarks, '')

// Maps code-unit indices of `deaccent(text)` back to code-unit indices of `text`.
//   Removing combining marks shortens the string, so match offsets taken from the
//   deaccented text no longer line up with the original one (e.g. a label stored
//   in decomposed form like `Cafe\u0301 zammad`).
const deaccentIndexMap = (text: string): number[] => {
  const map: number[] = []
  let offset = 0

  for (const character of text) {
    for (const part of character.normalize('NFD')) {
      if (combiningMark.test(part)) continue
      for (let i = 0; i < part.length; i += 1) map.push(offset)
    }
    offset += character.length
  }

  map.push(text.length)
  return map
}

/**
 * Splits a label into the fragments before, inside and after the first occurrence of a keyword,
 * so a component can render each of them separately. Matching ignores case and combining marks,
 * while the returned fragments are cut out of the original text.
 */
export const splitLabelByMatch = (text: string, keyword?: string): LabelMatchFragments => {
  const searchTerm = keyword?.trim()

  if (!searchTerm) return { before: text, matched: '', after: '' }

  const match = new RegExp(escapeRegExp(deaccent(searchTerm)), 'i').exec(deaccent(text))

  if (!match?.[0]) return { before: text, matched: '', after: '' }

  const indexMap = deaccentIndexMap(text)
  const matchStart = indexMap[match.index]
  const matchEnd = indexMap[match.index + match[0].length]

  return {
    before: text.slice(0, matchStart),
    matched: text.slice(matchStart, matchEnd),
    after: text.slice(matchEnd),
  }
}
