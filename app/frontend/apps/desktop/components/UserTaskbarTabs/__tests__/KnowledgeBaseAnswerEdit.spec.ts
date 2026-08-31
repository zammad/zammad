// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumKnowledgeBaseVisibility, EnumTaskbarEntity } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseAnswerEdit from '../KnowledgeBase/KnowledgeBaseAnswerEdit.vue'
import knowledgeBaseAnswerEditPlugin from '../plugins/knowledgeBaseAnswerEdit.ts'

import type { UserTaskbarTab } from '../types.ts'

import '#tests/graphql/builders/mocks.ts'

const ANSWER_INTERNAL_ID = '42'
const LOCALE_CODE = 'en-us'

const taskbarTab = (entity: Record<string, unknown> | null = null): UserTaskbarTab => ({
  type: EnumTaskbarEntity.KnowledgeBaseAnswerEdit,
  tabEntityKey: `KnowledgeBase__Answer-${ANSWER_INTERNAL_ID}-${LOCALE_CODE}`,
  taskbarTabId: convertToGraphQLId('Taskbar', 1),
  order: 1,
  entity: entity as never,
})

const renderTab = (props = {}) =>
  renderComponent(KnowledgeBaseAnswerEdit, {
    props: {
      taskbarTab: taskbarTab(),
      taskbarTabLink: `/knowledge-base/locale/${LOCALE_CODE}/answer/${ANSWER_INTERNAL_ID}/edit`,
      ...props,
    },
    router: true,
    store: true,
  })

describe('KnowledgeBaseAnswerEdit taskbar tab', () => {
  it('falls back to a static label before the stored answer or the form has resolved', () => {
    const view = renderTab()

    expect(view.getByRole('link', { name: 'Knowledge base answer' })).toBeInTheDocument()
  })

  it('renders the stored title of the answer', () => {
    const view = renderTab({
      taskbarTab: taskbarTab({
        __typename: 'KnowledgeBaseAnswer',
        id: convertToGraphQLId('KnowledgeBase::Answer', ANSWER_INTERNAL_ID),
        title: 'Stored answer title',
        visibility: EnumKnowledgeBaseVisibility.Internal,
      }),
    })

    expect(view.getByText('Stored answer title')).toBeInTheDocument()
  })

  // The same status icon the reader and the create draft show, so a tab in edit is recognizable.
  it('shows the status icon of the stored visibility', () => {
    const view = renderTab({
      taskbarTab: taskbarTab({
        __typename: 'KnowledgeBaseAnswer',
        id: convertToGraphQLId('KnowledgeBase::Answer', ANSWER_INTERNAL_ID),
        title: 'Stored answer title',
        visibility: EnumKnowledgeBaseVisibility.Published,
      }),
    })

    expect(view.getByIconName('kb-published')).toBeInTheDocument()
  })

  // The label stays on the stored answer while the form is being changed - the tab belongs to the
  //   answer, not to the draft. The status icon does follow the form: the state is picked in it,
  //   and the icon is what says which one is about to be saved.
  it('keeps the stored title but follows the visibility picked in the form', () => {
    const view = renderTab({
      taskbarTab: taskbarTab({
        __typename: 'KnowledgeBaseAnswer',
        id: convertToGraphQLId('KnowledgeBase::Answer', ANSWER_INTERNAL_ID),
        title: 'Stored answer title',
        visibility: EnumKnowledgeBaseVisibility.Published,
      }),
      context: {
        formValues: { title: 'Being typed', visibility: EnumKnowledgeBaseVisibility.Internal },
      },
    })

    expect(view.getByText('Stored answer title')).toBeInTheDocument()
    expect(view.queryByText('Being typed')).not.toBeInTheDocument()
    expect(view.getByIconName('kb-internal')).toBeInTheDocument()
  })
})

describe('knowledgeBaseAnswerEdit taskbar tab plugin', () => {
  const route = {
    params: { answerInternalId: ANSWER_INTERNAL_ID, localeCode: LOCALE_CODE },
  } as never

  // Must match Taskbar.entity_key(answer, locale) byte for byte - the backend resolves the tab's
  //   entity from exactly this key.
  it('builds the entity tab key from the answer id and the locale', () => {
    expect(knowledgeBaseAnswerEditPlugin.buildEntityTabKey(route)).toBe(
      `KnowledgeBase__Answer-${ANSWER_INTERNAL_ID}-${LOCALE_CODE}`,
    )
  })

  it('stores the answer id and the locale with the tab', () => {
    expect(knowledgeBaseAnswerEditPlugin.buildTaskbarTabParams?.(route)).toEqual({
      answer_id: ANSWER_INTERNAL_ID,
      locale: LOCALE_CODE,
    })
  })

  // KnowledgeBaseAnswer carries no `internalId`, so the link is always rebuilt from the key -
  //   even once the entity has loaded - rather than preferring an id off the entity.
  it('rebuilds the link from the key alone', () => {
    expect(
      knowledgeBaseAnswerEditPlugin.buildTaskbarTabLink?.(
        undefined,
        `KnowledgeBase__Answer-${ANSWER_INTERNAL_ID}-${LOCALE_CODE}`,
      ),
    ).toBe(`/knowledge-base/locale/${LOCALE_CODE}/answer/${ANSWER_INTERNAL_ID}/edit`)
  })

  // The locale qualifier itself contains a '-' (e.g. 'de-de'), so a naive split on the first dash
  //   alone would cut it in half; every segment past the id has to be rejoined.
  it('rebuilds the link when the locale qualifier itself contains a dash', () => {
    expect(
      knowledgeBaseAnswerEditPlugin.buildTaskbarTabLink?.(
        undefined,
        `KnowledgeBase__Answer-${ANSWER_INTERNAL_ID}-de-de`,
      ),
    ).toBe(`/knowledge-base/locale/de-de/answer/${ANSWER_INTERNAL_ID}/edit`)
  })

  // Without a key there is no valid edit URL, so the tab renders without a link rather than
  //   pointing at a broken one.
  it('builds no link without an entity key', () => {
    expect(
      knowledgeBaseAnswerEditPlugin.buildTaskbarTabLink?.(undefined, undefined),
    ).toBeUndefined()
  })
})
