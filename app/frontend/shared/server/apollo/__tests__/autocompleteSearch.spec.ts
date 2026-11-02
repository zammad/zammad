// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import gql from 'graphql-tag'

import createCache from '../cache.ts'

describe('autocomplete search cache', () => {
  it.each([
    ['autocompleteSearchTag', 'AutocompleteSearchEntry'],
    [
      'autocompleteSearchKnowledgeBaseCategoryIcon',
      'AutocompleteSearchKnowledgeBaseCategoryIconEntry',
    ],
  ])('replaces the complete %s result without changing another search', (field, typename) => {
    const inputType = `${field[0].toUpperCase()}${field.slice(1)}Input`
    const query = gql`
      query autocompleteCache($input: ${inputType}!) {
        ${field}(input: $input) {
          value
          label
        }
      }
    `
    const cache = createCache()
    const variables = { input: { query: 'first', limit: 25 } }
    const otherVariables = { input: { query: 'second', limit: 25 } }
    const retainedOption = { __typename: typename, value: 'retained', label: 'Original' }
    const removedOption = { __typename: typename, value: 'removed', label: 'Removed' }
    const otherOption = { __typename: typename, value: 'other', label: 'Other search' }

    cache.writeQuery({ query, variables, data: { [field]: [retainedOption, removedOption] } })
    cache.writeQuery({ query, variables: otherVariables, data: { [field]: [otherOption] } })

    const refreshedOption = { ...retainedOption, label: 'Refreshed' }
    cache.writeQuery({ query, variables, data: { [field]: [refreshedOption] } })

    expect(cache.readQuery({ query, variables })).toEqual({ [field]: [refreshedOption] })
    expect(cache.readQuery({ query, variables: otherVariables })).toEqual({
      [field]: [otherOption],
    })

    cache.writeQuery({ query, variables, data: { [field]: [] } })

    expect(cache.readQuery({ query, variables })).toEqual({ [field]: [] })
    expect(cache.readQuery({ query, variables: otherVariables })).toEqual({
      [field]: [otherOption],
    })
  })
})
