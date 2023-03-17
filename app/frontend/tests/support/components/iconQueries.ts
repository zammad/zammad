// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  buildQueries,
  queryAllByAttribute,
  getQueriesForElement,
  type Matcher,
  type BoundFunctions,
} from '@testing-library/vue'

export const queryAllByIconName = (
  container: HTMLElement,
  matcher: Matcher,
) => {
  let id = matcher
  if (typeof matcher === 'string') {
    id = `#icon-${matcher}`
  }
  return queryAllByAttribute(`href`, container, id).map(
    (el) => el.parentElement as HTMLElement,
  )
}

export const [
  queryByIconName,
  getAllByIconName,
  getByIconName,
  findAllByIconName,
  findByIconName,
] = buildQueries(
  queryAllByIconName,
  (_, matcher) => `Several icons with the "${matcher}" matcher were found`,
  (_, matcher) => `No icons with the "${matcher}" search were found`,
)

export default function buildIconsQueries(container: HTMLElement) {
  const queryFns = {
    queryByIconName,
    getAllByIconName,
    getByIconName,
    findAllByIconName,
    findByIconName,
    queryAllByIconName,
  } as const

  return getQueriesForElement(container, queryFns as any) as BoundFunctions<
    typeof queryFns
  >
}
