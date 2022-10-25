// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import {
  mockPublicLinks,
  mockPublicLinksSubscription,
} from '@shared/entities/public-links/__tests__/mocks/mockPublicLinks'
import type { PublicLinksQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import { getAllByRole } from '@testing-library/vue'
import { visitView } from '@tests/support/components/visitView'
import { waitUntilApisResolved } from '@tests/support/utils'

describe('testing login public links', () => {
  it('renders a single link to desktop app, when no public links are available', async () => {
    const publicLinkQuery = mockPublicLinks([])
    mockPublicLinksSubscription()

    const view = await visitView('/login')

    await waitUntilApisResolved(publicLinkQuery)

    const navigation = view.getByRole('navigation')
    const links = getAllByRole(navigation, 'link')

    expect(links).toHaveLength(1)
    expect(links[0]).toHaveAttribute('href', '/#login')
    expect(links[0]).not.toHaveAttribute('target', '_blank')
  })

  it('renders all public links correctly', async () => {
    const publicLinks: ConfidentTake<PublicLinksQuery, 'publicLinks'> = [
      {
        __typename: 'PublicLink',
        id: '1',
        link: 'https://localhost/link-1',
        description: 'some-description',
        title: 'Link 1',
        newTab: false,
      },
      {
        __typename: 'PublicLink',
        id: '2',
        link: 'https://localhost/link-2',
        title: 'Link 2',
        description: null,
        newTab: true,
      },
    ]
    const publicLinkQuery = mockPublicLinks(publicLinks)
    mockPublicLinksSubscription()

    const view = await visitView('/login')

    await waitUntilApisResolved(publicLinkQuery)

    const navigation = view.getByRole('navigation')
    const links = getAllByRole(navigation, 'link')

    expect(links).toHaveLength(publicLinks.length + 1)
    expect(links[0]).toHaveAttribute('href', '/#login')

    expect(links[1]).toHaveAttribute('href', publicLinks[0].link)
    expect(links[1]).toHaveAttribute('title', publicLinks[0].description)
    expect(links[1]).toHaveTextContent(publicLinks[0].title)
    expect(links[1]).not.toHaveAttribute('target', '_blank')

    expect(links[2]).toHaveAttribute('href', publicLinks[1].link)
    expect(links[2]).toHaveTextContent(publicLinks[1].title)
    expect(links[2]).toHaveAttribute('target', '_blank')
  })

  it('rerenders links, when subscription is triggered', async () => {
    const publicLinkQuery = mockPublicLinks([])
    const subcription = mockPublicLinksSubscription()

    const view = await visitView('/login')
    await waitUntilApisResolved(publicLinkQuery)

    const navigation = view.getByRole('navigation')

    expect(getAllByRole(navigation, 'link')).toHaveLength(1)

    await subcription.next({
      data: {
        publicLinkUpdates: {
          __typename: 'PublicLinkUpdatesPayload',
          publicLinks: [
            {
              __typename: 'PublicLink',
              id: '1',
              link: 'https://localhost/link-1',
              description: 'some-description',
              title: 'Link 1',
              newTab: false,
            },
          ],
        },
      },
    })

    const newLinks = getAllByRole(navigation, 'link')

    expect(newLinks).toHaveLength(2)
    expect(newLinks[0]).toHaveAttribute('href', '/#login')
    expect(newLinks[1]).toHaveAttribute('href', 'https://localhost/link-1')
  })
})
