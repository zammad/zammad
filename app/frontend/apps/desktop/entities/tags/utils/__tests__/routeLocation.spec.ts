// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { tagSearchRoute } from '../routeLocation.ts'

describe('tagSearchRoute', () => {
  it('targets the search with the tag as a filter term', () => {
    expect(tagSearchRoute('vip')).toEqual({
      name: 'Search',
      params: { searchTerm: 'tags:"vip"' },
      query: { entity: 'Ticket' }, // TODO: Update once tag search is available
    })
  })

  // Without the quotes the search would split the tag into separate terms.
  it('keeps a multi-word tag as a single term', () => {
    expect(tagSearchRoute('second level').params?.searchTerm).toBe('tags:"second level"')
  })
})
