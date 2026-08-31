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

import { KnowledgeBaseAnswerVisibilityScheduleAddDocument } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerVisibilityScheduleAdd.api.ts'
import {
  mockKnowledgeBaseAnswerVisibilityScheduleAddMutation,
  waitForKnowledgeBaseAnswerVisibilityScheduleAddMutationCalls,
} from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseAnswerVisibilityScheduleAdd.mocks.ts'

import KnowledgeBaseAnswerVisibilityScheduleFlyout from '../KnowledgeBaseAnswerVisibilityScheduleFlyout.vue'

const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 1)

const renderFlyout = () =>
  renderComponent(KnowledgeBaseAnswerVisibilityScheduleFlyout, {
    props: { answerId: ANSWER_ID },
    form: true,
    flyout: true,
    router: true,
    store: true,
  })

const answerPayload = (scheduledAt: string) => ({
  knowledgeBaseAnswerVisibilityScheduleAdd: {
    answer: {
      id: ANSWER_ID,
      visibilitySchedules: [
        { visibility: EnumKnowledgeBaseSchedulableVisibility.Published, scheduledAt },
      ],
    },
    errors: null,
  },
})

describe('KnowledgeBaseAnswerVisibilityScheduleFlyout', () => {
  it('asks for a state and a date', async () => {
    const view = renderFlyout()

    expect(
      view.getByRole('heading', { name: 'Add visibility schedule', level: 2 }),
    ).toBeInTheDocument()
    expect(await view.findByRole('radio', { name: /Internal/ })).toBeInTheDocument()
    expect(view.getByLabelText('Schedule for')).toBeInTheDocument()
  })

  // A state is stored as the date it is reached at, and `draft` is what no date at all means -
  //   there is nothing to put in the future for it, which is why the mutation's enum leaves it out.
  it('offers every state but draft', async () => {
    const view = renderFlyout()

    expect(await view.findByRole('radio', { name: /Internal/ })).toBeInTheDocument()
    expect(view.getByRole('radio', { name: /Public/ })).toBeInTheDocument()
    expect(view.getByRole('radio', { name: /Archived/ })).toBeInTheDocument()
    expect(view.queryByRole('radio', { name: /Draft/ })).not.toBeInTheDocument()
  })

  // The same descriptions the answer's own visibility field shows, since both read them off
  //   answerVisibilityOptions.
  it('describes what each state means', async () => {
    const view = renderFlyout()

    expect(await view.findByText('Visible to readers & editors')).toBeInTheDocument()
    expect(view.getByText('Visible to everyone')).toBeInTheDocument()
    expect(view.getByText('Archive this answer')).toBeInTheDocument()
  })

  it('schedules the picked state for the given date', async () => {
    const scheduledAt = '2027-01-10T14:00:00Z'

    mockKnowledgeBaseAnswerVisibilityScheduleAddMutation(answerPayload(scheduledAt))

    const view = renderFlyout()

    await view.events.click(await view.findByRole('radio', { name: /Public/ }))
    await view.events.type(view.getByLabelText('Schedule for'), '2027-01-10 14:00')

    await view.events.click(view.getByRole('button', { name: 'Add schedule' }))

    const calls = await waitForKnowledgeBaseAnswerVisibilityScheduleAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      answerId: ANSWER_ID,
      visibility: EnumKnowledgeBaseVisibility.Published,
      // The picker's own output, which the tests run in UTC.
      scheduledAt: expect.stringContaining('2027-01-10T14:00'),
    })

    const { notify } = useNotifications()

    expect(notify).toHaveBeenCalledWith({
      id: 'knowledge-base-answer-visibility-schedule-added',
      message: 'Visibility change scheduled successfully.',
      type: NotificationTypes.Success,
    })
  })

  // Both fields are required, so an empty form must not reach the mutation - the service would only
  //   refuse it a round trip later.
  it('submits nothing without a state and a date', async () => {
    const view = renderFlyout()

    await view.events.click(await view.findByRole('button', { name: 'Add schedule' }))

    const { notify } = useNotifications()

    expect(notify).not.toHaveBeenCalled()
  })

  // `futureOnly` only limits what the picker offers - a date typed into the text input sails past
  //   it, and the service would then refuse it. The rule is what actually holds, and it puts the
  //   complaint on the field rather than at the top of the flyout.
  it('refuses a date that is not in the future', async () => {
    const view = renderFlyout()

    await view.events.click(await view.findByRole('radio', { name: /Public/ }))
    await view.events.type(view.getByLabelText('Schedule for'), '2020-01-10 14:00')

    await view.events.click(view.getByRole('button', { name: 'Add schedule' }))
    await waitForNextTick()

    expect(
      view.getByText('This field must have a value that is in the future.'),
    ).toBeInTheDocument()
    expect(getGraphQLMockCalls(KnowledgeBaseAnswerVisibilityScheduleAddDocument)).toEqual([])
  })

  // Whatever the service refuses has to be readable - the state has already been reached, or the
  //   changes would not run in the order they take effect. Which is why the handler is given no
  //   `errorNotificationMessage` to bury it under.
  describe('when the backend refuses the schedule', () => {
    const submit = async (view: ReturnType<typeof renderFlyout>) => {
      await view.events.click(await view.findByRole('radio', { name: /Archived/ }))
      await view.events.type(view.getByLabelText('Schedule for'), '2027-01-10 14:00')
      await view.events.click(view.getByRole('button', { name: 'Add schedule' }))
      await waitForKnowledgeBaseAnswerVisibilityScheduleAddMutationCalls()
      await waitForNextTick()
    }

    it('shows what it said', async () => {
      const message =
        'The answer has already reached this visibility state, so a change to it cannot be scheduled.'

      mockKnowledgeBaseAnswerVisibilityScheduleAddMutation({
        knowledgeBaseAnswerVisibilityScheduleAdd: {
          answer: null,
          errors: [{ __typename: 'UserError', message, field: null }],
        },
      })

      const view = renderFlyout()
      await submit(view)

      expect(view.getByText(message)).toBeInTheDocument()
    })

    // The refusals name the argument that has to change, and the fields are called after those - so
    //   the ordering rule lands on the date the editor picked. Which is the point of the service
    //   owning it: CanBePublished reports the same conflict on `archived_at`, the pending archival
    //   they did not touch.
    it('puts a refusal about the date on the date field', async () => {
      const message =
        'Visibility changes take effect in the order internal, published, archived, and can only be scheduled in that order.'

      mockKnowledgeBaseAnswerVisibilityScheduleAddMutation({
        knowledgeBaseAnswerVisibilityScheduleAdd: {
          answer: null,
          errors: [{ __typename: 'UserError', message, field: 'scheduledAt' }],
        },
      })

      const view = renderFlyout()
      await submit(view)

      expect(view.getByLabelText('Schedule for')).toHaveAccessibleDescription(
        expect.stringContaining(message),
      )
    })

    it('puts a refusal about the state on the state field', async () => {
      const message =
        'The answer has already reached this visibility state, so a change to it cannot be scheduled.'

      mockKnowledgeBaseAnswerVisibilityScheduleAddMutation({
        knowledgeBaseAnswerVisibilityScheduleAdd: {
          answer: null,
          errors: [{ __typename: 'UserError', message, field: 'visibility' }],
        },
      })

      const view = renderFlyout()
      await submit(view)

      expect(view.getByText(message)).toBeInTheDocument()
    })

    // A model validation can still name something this form has no field for - a title clash on the
    //   answer, say. Form.vue promotes such an error to the form itself rather than dropping it.
    it('shows one that names something the form has no field for', async () => {
      const message = 'This field has already been taken'

      mockKnowledgeBaseAnswerVisibilityScheduleAddMutation({
        knowledgeBaseAnswerVisibilityScheduleAdd: {
          answer: null,
          errors: [{ __typename: 'UserError', message, field: 'translations.title' }],
        },
      })

      const view = renderFlyout()
      await submit(view)

      expect(view.getByText(message)).toBeInTheDocument()
    })

    it('keeps the flyout open so the date can be corrected', async () => {
      mockKnowledgeBaseAnswerVisibilityScheduleAddMutation({
        knowledgeBaseAnswerVisibilityScheduleAdd: {
          answer: null,
          errors: [{ __typename: 'UserError', message: 'Nope.', field: null }],
        },
      })

      const view = renderFlyout()
      await submit(view)

      expect(
        view.getByRole('heading', { name: 'Add visibility schedule', level: 2 }),
      ).toBeInTheDocument()
      expect(view.getByLabelText('Schedule for')).toHaveValue('2027-01-10 14:00')
    })
  })
})
