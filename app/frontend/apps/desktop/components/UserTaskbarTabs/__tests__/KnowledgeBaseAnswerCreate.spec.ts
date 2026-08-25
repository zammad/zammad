// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumKnowledgeBaseVisibility, EnumTaskbarEntity } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseAnswerCreate from '../KnowledgeBase/KnowledgeBaseAnswerCreate.vue'
import knowledgeBaseAnswerCreatePlugin from '../plugins/knowledgeBaseAnswerCreate.ts'

import type { UserTaskbarTab } from '../types.ts'

import '#tests/graphql/builders/mocks.ts'

const TAB_ID = 'e4d21b30-6f6a-4ea3-9cd0-2c0e40d0d13c'

const taskbarTab = (entity: Record<string, unknown> | null = null): UserTaskbarTab => ({
  type: EnumTaskbarEntity.KnowledgeBaseAnswerCreate,
  tabEntityKey: `KnowledgeBaseAnswerCreateScreen-${TAB_ID}`,
  taskbarTabId: convertToGraphQLId('Taskbar', 1),
  order: 1,
  entity: entity as never,
})

const renderTab = (props = {}) =>
  renderComponent(KnowledgeBaseAnswerCreate, {
    props: {
      taskbarTab: taskbarTab(),
      taskbarTabLink: `/knowledge-base/locale/en-us/answer/create/${TAB_ID}`,
      ...props,
    },
    router: true,
    store: true,
  })

describe('KnowledgeBaseAnswerCreate taskbar tab', () => {
  it('falls back to a static label for a draft without a title', () => {
    const view = renderTab()

    expect(view.getByRole('link', { name: 'New knowledge base answer' })).toBeInTheDocument()
  })

  it('renders the stored title of the draft', () => {
    const view = renderTab({
      taskbarTab: taskbarTab({
        __typename: 'UserTaskbarItemEntityKnowledgeBaseAnswerCreate',
        uid: TAB_ID,
        title: 'Stored draft title',
        locale: 'en-us',
      }),
    })

    expect(view.getByText('Stored draft title')).toBeInTheDocument()
  })

  // The same status icon a stored answer carries, so a draft is recognizable in the tab list.
  it('shows the status icon of the stored visibility', () => {
    const view = renderTab({
      taskbarTab: taskbarTab({
        __typename: 'UserTaskbarItemEntityKnowledgeBaseAnswerCreate',
        uid: TAB_ID,
        title: 'Stored draft title',
        locale: 'en-us',
        visibility: EnumKnowledgeBaseVisibility.Published,
      }),
    })

    expect(view.getByIconName('kb-published')).toBeInTheDocument()
  })

  it('prefers the visibility picked in the form', () => {
    const view = renderTab({
      taskbarTab: taskbarTab({
        __typename: 'UserTaskbarItemEntityKnowledgeBaseAnswerCreate',
        uid: TAB_ID,
        title: 'Stored draft title',
        locale: 'en-us',
        visibility: EnumKnowledgeBaseVisibility.Published,
      }),
      context: { formValues: { visibility: EnumKnowledgeBaseVisibility.Internal } },
    })

    expect(view.getByIconName('kb-internal')).toBeInTheDocument()
  })

  // The state's colour is what makes the list scannable; the active tab needs white on its blue.
  it('colours the icon by the state while the tab is not the active one', () => {
    const view = renderTab({
      taskbarTab: taskbarTab({
        __typename: 'UserTaskbarItemEntityKnowledgeBaseAnswerCreate',
        uid: TAB_ID,
        title: 'Stored draft title',
        locale: 'en-us',
        visibility: EnumKnowledgeBaseVisibility.Published,
      }),
    })

    expect(view.getByIconName('kb-published')).toHaveClass('text-green-400!')
  })

  // A tab that has never been through a form updater round trip has nothing stored yet.
  it('falls back to the state a new answer would be created in', () => {
    const view = renderTab()

    expect(view.getByIconName('kb-draft')).toBeInTheDocument()
  })

  // What is being typed wins over what was stored on the last round trip.
  it('prefers the title from the live form', () => {
    const view = renderTab({
      taskbarTab: taskbarTab({
        __typename: 'UserTaskbarItemEntityKnowledgeBaseAnswerCreate',
        uid: TAB_ID,
        title: 'Stored draft title',
        locale: 'en-us',
      }),
      context: { formValues: { title: 'Being typed' } },
    })

    expect(view.getByText('Being typed')).toBeInTheDocument()
    expect(view.queryByText('Stored draft title')).not.toBeInTheDocument()
  })
})

describe('knowledgeBaseAnswerCreate taskbar tab plugin', () => {
  const route = {
    params: { tabId: TAB_ID, localeCode: 'en-us' },
    query: { categoryId: '42' },
  } as never

  // The key has to match the backend branch that resolves the tab out of the taskbar state.
  it('builds the entity tab key from the tab id', () => {
    expect(knowledgeBaseAnswerCreatePlugin.buildEntityTabKey(route)).toBe(
      `KnowledgeBaseAnswerCreateScreen-${TAB_ID}`,
    )
  })

  // Written once, when the tab is created, and never updated afterwards (the store only ever
  //   sends `state`) - so only what cannot change belongs in here. The category can: it is a form
  //   field, and the auto-save keeps its live value in the draft state.
  it('stores the locale of the draft with the tab', () => {
    expect(knowledgeBaseAnswerCreatePlugin.buildTaskbarTabParams?.(route)).toEqual({
      id: TAB_ID,
      locale: 'en-us',
    })
  })

  it('rebuilds the link from the stored locale and tab id', () => {
    expect(
      knowledgeBaseAnswerCreatePlugin.buildTaskbarTabLink?.({
        uid: TAB_ID,
        locale: 'en-us',
      } as never),
    ).toBe(`/knowledge-base/locale/en-us/answer/create/${TAB_ID}`)
  })

  // Without a locale there is no valid create URL, so the tab renders without a link rather
  //   than pointing at a broken one.
  it('builds no link without a locale', () => {
    expect(
      knowledgeBaseAnswerCreatePlugin.buildTaskbarTabLink?.({ uid: TAB_ID } as never),
    ).toBeUndefined()
  })
})
