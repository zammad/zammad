// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  buildSearchDeepLink,
  buildSearchRouteQuery,
} from '#desktop/pages/search/utils/searchRouteLink.ts'

describe('searchRouteLink', () => {
  it('builds route query with dot-path filter params', () => {
    const query = buildSearchRouteQuery({
      entity: 'Ticket',
      baseQuery: { sort: 'created_at' },
      filters: [
        {
          name: 'ticket.title',
          operator: 'matches',
          value: 'Alpha',
        },
      ],
    })

    expect(query).toEqual({
      sort: 'created_at',
      entity: 'Ticket',
      'filter.0.name': 'ticket.title',
      'filter.0.operator': 'matches',
      'filter.0.value': 'Alpha',
    })
  })

  it('builds deep link URL with encoded search term and dot-path filters', () => {
    const url = buildSearchDeepLink({
      searchTerm: 'alpha beta',
      entity: 'Ticket',
      filters: [
        {
          name: 'ticket.title',
          operator: 'matches',
          value: 'Alpha',
        },
      ],
    })

    expect(url).toBe(
      '/search/alpha%20beta?entity=Ticket&filter.0.name=ticket.title&filter.0.operator=matches&filter.0.value=Alpha',
    )
  })
})
