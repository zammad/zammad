// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  mockKnowledgeBaseFeedTokenRenewMutation,
  mockKnowledgeBaseFeedTokenRenewMutationError,
  waitForKnowledgeBaseFeedTokenRenewMutationCalls,
} from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseFeedTokenRenew.mocks.ts'
import {
  mockKnowledgeBaseFeedQuery,
  mockKnowledgeBaseFeedQueryError,
  waitForKnowledgeBaseFeedQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseFeed.mocks.ts'

import KnowledgeBaseFeedFlyout from '../KnowledgeBaseFeedFlyout.vue'

import type { RouteRecordRaw } from 'vue-router'

const knowledgeBasePath = '/api/v1/knowledge_bases/1/en-us/feed?token=abc'
const categoryPath = '/api/v1/knowledge_bases/1/categories/2/en-us/feed?token=abc'

const categoryId = 'gid://zammad/KnowledgeBase::Category/2'

// The browsed locale lives in the URL, so the flyout can only pick it up from a
//   route that carries it.
const routerRoutes: RouteRecordRaw[] = [
  {
    name: 'Dashboard',
    path: '/',
    component: { template: 'dashboard' },
  },
  {
    name: 'KnowledgeBaseBrowse',
    path: '/knowledge-base/locale/:localeCode',
    component: { template: 'knowledge base' },
  },
]

const renderFlyout = async (props = {}) => {
  const view = renderComponent(KnowledgeBaseFeedFlyout, {
    props,
    flyout: true,
    store: true,
    router: true,
    routerRoutes,
    form: true,
  })

  await view.router.replace('/knowledge-base/locale/en-us')

  return view
}

const renderWithFeed = async (props = {}) => {
  mockKnowledgeBaseFeedQuery({
    knowledgeBaseFeed: { knowledgeBasePath, categoryPath: null },
  })

  const view = await renderFlyout(props)

  await waitForKnowledgeBaseFeedQueryCalls()
  await waitForNextTick()

  return view
}

// The fields live inside one wrapper element on purpose: the loader transitions
//   its default slot, which renders only its first child, so two fields side by
//   side would silently lose the second one. Querying through the wrapper keeps
//   that structure asserted.
const feedUrls = (view: Awaited<ReturnType<typeof renderFlyout>>) =>
  within(view.getByTestId('knowledge-base-feed-urls'))

describe('KnowledgeBaseFeedFlyout', () => {
  beforeEach(() => {
    mockApplicationConfig({ http_type: 'https', fqdn: 'zammad.example.org' })
  })

  it('shows only the knowledge base feed at the knowledge base root', async () => {
    const view = await renderWithFeed()

    expect(feedUrls(view).getByLabelText('Knowledge base feed')).toHaveValue(
      `https://zammad.example.org${knowledgeBasePath}`,
    )
    expect(feedUrls(view).queryByLabelText('Category feed')).not.toBeInTheDocument()
  })

  it('additionally shows the category feed while browsing a category', async () => {
    mockKnowledgeBaseFeedQuery({
      knowledgeBaseFeed: { knowledgeBasePath, categoryPath },
    })

    const view = await renderFlyout({ categoryId })

    await waitForKnowledgeBaseFeedQueryCalls()
    await waitForNextTick()

    expect(feedUrls(view).getByLabelText('Category feed')).toHaveValue(
      `https://zammad.example.org${categoryPath}`,
    )
  })

  // Like the old interface: an installation still carrying the placeholder fqdn
  //   would otherwise hand out feed URLs on a host that does not exist.
  it('falls back to the browser origin while the fqdn is unconfigured', async () => {
    mockApplicationConfig({ http_type: 'https', fqdn: 'zammad.example.com' })

    const view = await renderWithFeed()

    expect(feedUrls(view).getByLabelText('Knowledge base feed')).toHaveValue(
      `${window.location.origin}${knowledgeBasePath}`,
    )
  })

  // Renewing invalidates the token elsewhere too (another tab, the old interface),
  //   so a cached path could be dead by the time it is copied.
  it('asks the server again every time it is opened', async () => {
    await renderWithFeed()

    const renewedPath = knowledgeBasePath.replace('abc', 'def')

    mockKnowledgeBaseFeedQuery({
      knowledgeBaseFeed: { knowledgeBasePath: renewedPath, categoryPath: null },
    })

    const view = await renderFlyout()

    await waitForKnowledgeBaseFeedQueryCalls()
    await waitForNextTick()

    // The first flyout is still mounted, so assert on the one just opened.
    const reopened = within(view.getAllByTestId('knowledge-base-feed-urls').at(-1)!)

    expect(reopened.getByLabelText('Knowledge base feed')).toHaveValue(
      `https://zammad.example.org${renewedPath}`,
    )
  })

  // The feeds deliver what is being browsed: the category the flyout was opened
  //   from, in the locale of the URL — not the header's upper-cased locale code.
  it('asks for the browsed category and locale', async () => {
    mockKnowledgeBaseFeedQuery({
      knowledgeBaseFeed: { knowledgeBasePath, categoryPath },
    })

    await renderFlyout({ categoryId })

    const calls = await waitForKnowledgeBaseFeedQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({ categoryId, locale: 'en-us' })
  })

  // The renewal answers with the new paths, so they replace the old ones in one
  //   step: no reload, no skeleton flashing in between, and no window in which the
  //   invalidated URLs are still copyable.
  it('renews the access token and shows the refreshed URLs', async () => {
    const view = await renderWithFeed({ categoryId })

    const renewedPath = knowledgeBasePath.replace('abc', 'def')

    mockKnowledgeBaseFeedTokenRenewMutation({
      knowledgeBaseFeedTokenRenew: {
        feed: { knowledgeBasePath: renewedPath, categoryPath: null },
      },
    })

    const queryCallsBefore = (await waitForKnowledgeBaseFeedQueryCalls()).length

    await view.events.click(view.getByRole('button', { name: 'Renew access token' }))

    const calls = await waitForKnowledgeBaseFeedTokenRenewMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({ categoryId, locale: 'en-us' })

    expect(feedUrls(view).getByLabelText('Knowledge base feed')).toHaveValue(
      `https://zammad.example.org${renewedPath}`,
    )

    expect(
      (await waitForKnowledgeBaseFeedQueryCalls()).length,
      'the paths are not fetched again',
    ).toBe(queryCallsBefore)
  })

  // A failed renewal may have gone through all the same (a lost response), so the
  //   paths on screen are of unknown state: they go away rather than stay copyable,
  //   and there is nothing left to act on.
  it('withdraws the paths when the renewal fails', async () => {
    const view = await renderWithFeed()

    mockKnowledgeBaseFeedTokenRenewMutationError('Some error', {
      type: GraphQLErrorTypes.NetworkError,
    })

    await view.events.click(view.getByRole('button', { name: 'Renew access token' }))

    await waitForKnowledgeBaseFeedTokenRenewMutationCalls()

    expect(await view.findByText('Content could not be loaded.')).toBeInTheDocument()
    expect(view.queryByTestId('knowledge-base-feed-urls')).not.toBeInTheDocument()
    expect(view.queryByRole('button', { name: 'Renew access token' })).not.toBeInTheDocument()
  })

  // Without paths there is nothing to renew, so the flyout has to say so rather than
  //   sit there with a dead button.
  it('reports paths that cannot be loaded at all', async () => {
    mockKnowledgeBaseFeedQueryError('Some error', { type: GraphQLErrorTypes.NetworkError })

    const view = await renderFlyout()

    await waitForKnowledgeBaseFeedQueryCalls()

    expect(await view.findByText('Content could not be loaded.')).toBeInTheDocument()
    expect(view.queryByTestId('knowledge-base-feed-urls')).not.toBeInTheDocument()

    expect(view.queryByRole('button', { name: 'Renew access token' })).not.toBeInTheDocument()
  })
})
