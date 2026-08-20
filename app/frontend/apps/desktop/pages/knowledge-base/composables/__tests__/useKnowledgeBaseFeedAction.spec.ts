// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  mockKnowledgeBaseQuery,
  waitForKnowledgeBaseQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'

import { useKnowledgeBaseFeedAction } from '../useKnowledgeBaseFeedAction.ts'

const HostComponent = defineComponent({
  setup() {
    const { feedActions } = useKnowledgeBaseFeedAction(ref(undefined))

    return { feedActions }
  },
  template: '<ul><li v-for="action in feedActions" :key="action.key">{{ action.label }}</li></ul>',
})

const renderFeedAction = async (options: { showFeedIcon: boolean; permissions: string[] }) => {
  mockPermissions(options.permissions)
  mockKnowledgeBaseQuery({ knowledgeBase: { showFeedIcon: options.showFeedIcon } })

  const view = renderComponent(HostComponent, { store: true, router: true, flyout: true })

  await waitForKnowledgeBaseQueryCalls()

  return view
}

describe('useKnowledgeBaseFeedAction', () => {
  it('offers the feed action to a knowledge base reader', async () => {
    const view = await renderFeedAction({
      showFeedIcon: true,
      permissions: ['knowledge_base.reader'],
    })

    expect(await view.findByText('Set up RSS feed')).toBeInTheDocument()
  })

  // Like the old interface, the feeds follow the knowledge base's feed setting.
  it('offers nothing when the knowledge base has its feeds turned off', async () => {
    const view = await renderFeedAction({
      showFeedIcon: false,
      permissions: ['knowledge_base.editor'],
    })

    expect(view.queryByText('Set up RSS feed')).not.toBeInTheDocument()
  })

  // The feeds carry internal content, so they are never offered to a visitor of a
  //   publicly available knowledge base.
  it('offers nothing without a knowledge base permission', async () => {
    const view = await renderFeedAction({ showFeedIcon: true, permissions: ['ticket.agent'] })

    expect(view.queryByText('Set up RSS feed')).not.toBeInTheDocument()
  })
})
