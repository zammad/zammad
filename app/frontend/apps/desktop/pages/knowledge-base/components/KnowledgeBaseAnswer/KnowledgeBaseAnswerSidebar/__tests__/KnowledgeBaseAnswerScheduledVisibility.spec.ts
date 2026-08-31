// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import {
  EnumKnowledgeBaseSchedulableVisibility,
  EnumKnowledgeBaseVisibility,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { KnowledgeBaseAnswerVisibilityScheduleRemoveDocument } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerVisibilityScheduleRemove.api.ts'
import {
  mockKnowledgeBaseAnswerVisibilityScheduleRemoveMutation,
  waitForKnowledgeBaseAnswerVisibilityScheduleRemoveMutationCalls,
} from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerVisibilityScheduleRemove.mocks.ts'

import KnowledgeBaseAnswerScheduledVisibility from '../KnowledgeBaseAnswerScheduledVisibility.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../../types.ts'

// Removing one asks first, so every example that clicks the button has to answer that prompt.
const mockWaitForConfirmation = vi.hoisted(() => vi.fn())

vi.mock('#shared/composables/useConfirmation.ts', () => ({
  useConfirmation: () => ({ waitForConfirmation: mockWaitForConfirmation }),
}))

beforeEach(() => {
  mockWaitForConfirmation.mockReset()
  mockWaitForConfirmation.mockResolvedValue(true)
})

const hour = 60 * 60 * 1000
const day = 24 * hour

// Dates relative to now, rather than fixed ones: the section renders them relatively, so what the
//   labels read is the distance to the moment the test runs. The extra hour keeps each of them
//   clear of the boundary the formatter floors at - exactly two days from now would come out as
//   "in 1 day" by the time the assertion runs.
const inDays = (days: number) => new Date(Date.now() + days * day + hour).toISOString()

type Schedule = {
  visibility: EnumKnowledgeBaseSchedulableVisibility
  scheduledAt: string
}

const answer = (visibilitySchedules: Schedule[]): KnowledgeBaseAnswerHeader =>
  ({
    __typename: 'KnowledgeBaseAnswer',
    id: convertToGraphQLId('KnowledgeBase::Answer', 1),
    title: 'Some Answer',
    visibility: EnumKnowledgeBaseVisibility.Draft,
    visibilitySchedules: visibilitySchedules.map((schedule) => ({
      __typename: 'KnowledgeBaseAnswerVisibilitySchedule',
      ...schedule,
    })),
    translationId: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
    translationMissing: false,
    internalAt: null,
    publishedAt: null,
    archivedAt: null,
    editedAt: null,
    editedBy: null,
    navigation: null,
    content: null,
    category: {
      __typename: 'KnowledgeBaseCategory',
      id: convertToGraphQLId('KnowledgeBase::Category', 1),
      breadcrumb: [],
    },
    tags: [],
    attachments: [],
    policy: { __typename: 'PolicyDefault', update: true, destroy: true },
  }) as unknown as KnowledgeBaseAnswerHeader

const renderSection = (visibilitySchedules: Schedule[], editable = false) =>
  renderComponent(KnowledgeBaseAnswerScheduledVisibility, {
    props: { answer: answer(visibilitySchedules), editable },
    store: true,
    router: true,
  })

const internalInTwoDays = {
  visibility: EnumKnowledgeBaseSchedulableVisibility.Internal,
  scheduledAt: inDays(2),
}

const publishedInAWeek = {
  visibility: EnumKnowledgeBaseSchedulableVisibility.Published,
  scheduledAt: inDays(8),
}

const archivedInAMonth = {
  visibility: EnumKnowledgeBaseSchedulableVisibility.Archived,
  scheduledAt: inDays(31),
}

describe('KnowledgeBaseAnswerScheduledVisibility', () => {
  it('lists every change the answer is going to make', () => {
    const view = renderSection([internalInTwoDays, publishedInAWeek])

    expect(view.getAllByRole('listitem')).toHaveLength(2)
    expect(view.getByText('Internal')).toBeInTheDocument()
    expect(view.getByText('Published')).toBeInTheDocument()
  })

  // What the design shows beside the state: when it happens, not the date it happens on.
  it('says when each of them happens', () => {
    const view = renderSection([internalInTwoDays, publishedInAWeek])

    expect(view.getByText('in 2 days')).toBeInTheDocument()
    expect(view.getByText('in 1 week')).toBeInTheDocument()
  })

  // The order the backend hands them over in is the order they take effect, so the section keeps it
  //   rather than sorting again.
  it('keeps the order they take effect in', () => {
    const view = renderSection([internalInTwoDays, publishedInAWeek])

    const items = view.getAllByRole('listitem')

    expect(items[0]).toHaveTextContent('Internal')
    expect(items[1]).toHaveTextContent('Published')
  })

  // The state's own colour makes the pills scannable, the way it does in the answer list.
  it('tints a state that has a colour of its own', () => {
    const view = renderSection([internalInTwoDays, publishedInAWeek])

    expect(view.getByText('Internal')).toHaveClass('text-blue-800!')
    expect(view.getByText('Published')).toHaveClass('text-green-400!')
  })

  // `archived`'s own colour is a dim neutral - it says "inactive" on a small icon in the answer
  //   list, and is too faint for a line of text here. So this one keeps the default label colour.
  it('leaves an archival in the default text colour', () => {
    const view = renderSection([archivedInAMonth])

    // Nothing at all rather than a different tint: the label inherits CommonLabel's own colour.
    expect(view.getByText('Archived').className).toBe('')
  })

  it('states that nothing is scheduled', () => {
    const view = renderSection([])

    expect(view.getByText('No visibility changes scheduled yet.')).toBeInTheDocument()
    expect(view.queryByRole('list')).not.toBeInTheDocument()
  })

  it.each([
    ['with a schedule', [internalInTwoDays]],
    ['without one', []],
  ])('keeps the section label %s', (_, schedules) => {
    const view = renderSection(schedules as Schedule[])

    expect(view.getByText('Scheduled visibility')).toBeInTheDocument()
  })

  describe('when it is not editable', () => {
    it('offers no way to remove a change', () => {
      const view = renderSection([internalInTwoDays])

      expect(
        view.queryByRole('button', { name: 'Remove this scheduled visibility change' }),
      ).not.toBeInTheDocument()
    })

    it('offers no way to schedule one either', () => {
      const view = renderSection([internalInTwoDays])

      expect(
        view.queryByRole('button', { name: 'Schedule visibility change' }),
      ).not.toBeInTheDocument()
    })
  })

  // Written onto the answer the moment the editor clicks, like the tag and the link sections - not
  //   submitted with the edit form.
  describe('when it is editable', () => {
    // Whether the flyout it opens asks the right things is
    //   KnowledgeBaseAnswerVisibilityScheduleFlyout's own spec; here it is the button that matters,
    //   with and without entries above it.
    it.each([
      ['with a schedule', [internalInTwoDays]],
      ['without one', []],
    ])('offers a button to schedule one %s', (_, schedules) => {
      const view = renderSection(schedules as Schedule[], true)

      expect(view.getByRole('button', { name: 'Schedule visibility change' })).not.toHaveAttribute(
        'aria-disabled',
        'true',
      )
    })

    it('removes a change once it is confirmed', async () => {
      mockKnowledgeBaseAnswerVisibilityScheduleRemoveMutation({
        knowledgeBaseAnswerVisibilityScheduleRemove: {
          answer: {
            id: convertToGraphQLId('KnowledgeBase::Answer', 1),
            visibilitySchedules: [publishedInAWeek],
          },
          errors: null,
        },
      })

      const view = renderSection([internalInTwoDays, publishedInAWeek], true)

      await view.events.click(
        view.getAllByRole('button', { name: 'Remove this scheduled visibility change' })[0],
      )

      const calls = await waitForKnowledgeBaseAnswerVisibilityScheduleRemoveMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        answerId: convertToGraphQLId('KnowledgeBase::Answer', 1),
        visibility: EnumKnowledgeBaseSchedulableVisibility.Internal,
      })

      const { notify } = useNotifications()

      expect(notify).toHaveBeenCalledWith({
        id: 'knowledge-base-answer-visibility-schedule-removed',
        message: 'Scheduled visibility change removed successfully.',
        type: NotificationTypes.Success,
      })
    })

    // There is no undo: the date lives on the answer, so putting the change back means picking a
    //   new one. Which state the prompt is about matters, since the pills sit close together.
    it('names the state it is about in the prompt', async () => {
      const view = renderSection([internalInTwoDays], true)

      await view.events.click(
        view.getByRole('button', { name: 'Remove this scheduled visibility change' }),
      )

      expect(mockWaitForConfirmation).toHaveBeenCalledWith(
        'Do you really want to remove the scheduled change to %s?',
        expect.objectContaining({ textPlaceholder: ['Internal'] }),
      )
    })

    it('keeps the change when the prompt is declined', async () => {
      mockWaitForConfirmation.mockResolvedValue(false)
      mockKnowledgeBaseAnswerVisibilityScheduleRemoveMutation({
        knowledgeBaseAnswerVisibilityScheduleRemove: { answer: null, errors: null },
      })

      const view = renderSection([internalInTwoDays], true)

      await view.events.click(
        view.getByRole('button', { name: 'Remove this scheduled visibility change' }),
      )
      await waitForNextTick()

      expect(getGraphQLMockCalls(KnowledgeBaseAnswerVisibilityScheduleRemoveDocument)).toEqual([])
      expect(view.getByText('Internal')).toBeInTheDocument()
    })
  })
})
