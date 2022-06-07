// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import {
  buildQueries,
  queryAllByAttribute,
  getQueriesForElement,
  type Matcher,
  type BoundFunctions,
} from '@testing-library/vue'

export const queryAllIconsByName = (
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
  queryIconByName,
  getAllIconsByName,
  getIconByName,
  findAllIconsByName,
  findIconByName,
] = buildQueries(
  queryAllIconsByName,
  (_, matcher) => `Several icons with the "${matcher}" matcher were found`,
  (_, matcher) => `No icons with the "${matcher}" search were found`,
)

export default function buildIconsQueries(container: HTMLElement) {
  const queryFns = {
    queryIconByName,
    getAllIconsByName,
    getIconByName,
    findAllIconsByName,
    findIconByName,
    queryAllIconsByName,
  } as const

  return getQueriesForElement(container, queryFns as any) as BoundFunctions<
    typeof queryFns
  >
}
