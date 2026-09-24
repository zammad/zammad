// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { AiAnalyticsUsageDocument } from '#shared/graphql/mutations/aiAnalyticsUsage.api.ts'
import {
  mockAiAnalyticsUsageMutationError,
  waitForAiAnalyticsUsageMutationCalls,
} from '#shared/graphql/mutations/aiAnalyticsUsage.mocks.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import CommonAIFeedback from '#desktop/components/CommonAIFeedback/CommonAIFeedback.vue'

const renderCommonAIFeedback = (props: InstanceType<typeof CommonAIFeedback>['$props']) =>
  renderComponent(CommonAIFeedback, {
    props,
    form: true,
  })

const RUN_ID = 'test-run-id'

describe('CommonAIFeedback', () => {
  it('supports label prop', () => {
    const wrapper = renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID } },
      label: 'AI tools rock',
    })

    expect(wrapper.getByRole('heading', { level: 3 })).toHaveTextContent('AI tools rock')
  })

  it('sends initial usage on mount', async () => {
    renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID } },
    })

    const usageMutation = await waitForAiAnalyticsUsageMutationCalls()

    expect(usageMutation.at(-1)?.variables).toEqual({
      aiAnalyticsRunId: 'test-run-id',
      input: { rating: null },
    })
  })

  it('sends no initial usage on mount with noUsageTracking prop', async () => {
    renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID } },
      noUsageTracking: true,
    })

    await waitForNextTick()

    expect(getGraphQLMockCalls(AiAnalyticsUsageDocument)).toHaveLength(0)
  })

  it('handles positive feedback', async () => {
    const wrapper = renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID } },
    })

    await waitForAiAnalyticsUsageMutationCalls()

    await wrapper.events.click(wrapper.getByLabelText('Positive feedback'))

    const usageMutation = await waitForAiAnalyticsUsageMutationCalls()

    expect(wrapper.emitted('rated')).toHaveLength(1)

    expect(usageMutation.at(-1)?.variables).toEqual({
      aiAnalyticsRunId: 'test-run-id',
      input: { rating: true },
    })

    expect(wrapper.getByText('Thank you for your feedback.')).toBeInTheDocument()
  })

  it('handles negative feedback and shows comment field', async () => {
    const wrapper = renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID } },
    })

    await waitForAiAnalyticsUsageMutationCalls()

    await wrapper.events.click(wrapper.getByLabelText('Negative feedback'))

    const usageMutation = await waitForAiAnalyticsUsageMutationCalls()

    expect(usageMutation.at(-1)?.variables).toEqual({
      aiAnalyticsRunId: 'test-run-id',
      input: { rating: false },
    })

    expect(
      wrapper.getByPlaceholderText('Thanks for the feedback. Please explain what went wrong?'),
    ).toBeInTheDocument()
  })

  it('submits a comment after negative feedback', async () => {
    const wrapper = renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID } },
    })

    await waitForAiAnalyticsUsageMutationCalls()

    await wrapper.events.click(wrapper.getByLabelText('Negative feedback'))

    await waitForAiAnalyticsUsageMutationCalls()

    expect(wrapper.emitted('rated')).toHaveLength(1)

    const commentField = await wrapper.findByPlaceholderText(
      'Thanks for the feedback. Please explain what went wrong?',
    )

    const fieldNode = getNode(commentField.id)

    expect(commentField).toHaveFocus()

    await wrapper.events.type(commentField, 'Never trust AI')

    // There is an issue for the formkit input
    // We really need to wait first that the value resolved before asserting the value,
    // otherwise it will be always undefined and the test is flaky
    await fieldNode?.settled

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit comment' }))

    const usageMutation = await waitForAiAnalyticsUsageMutationCalls()

    expect(wrapper.getByRole('button', { name: 'Regenerate' })).toBeInTheDocument()

    expect(usageMutation.at(-1)?.variables).toEqual({
      aiAnalyticsRunId: RUN_ID,
      input: { comment: 'Never trust AI' },
    })
  })

  it('cancels comment submission', async () => {
    const wrapper = renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID } },
    })

    await waitForAiAnalyticsUsageMutationCalls()

    await wrapper.events.click(wrapper.getByLabelText('Negative feedback'))

    await waitForAiAnalyticsUsageMutationCalls()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'No comment' }))

    expect(wrapper.getByText('Thank you for your feedback.')).toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Regenerate' })).toBeInTheDocument()
  })

  it('shows the feedback as given when a comment was provided meanwhile in another view', async () => {
    const wrapper = renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID }, usage: { userHasProvidedFeedback: false } },
    })

    await wrapper.events.click(wrapper.getByLabelText('Negative feedback'))

    await waitForAiAnalyticsUsageMutationCalls()

    mockAiAnalyticsUsageMutationError('You have already provided feedback, thank you.', {
      type: GraphQLErrorTypes.AiFeedbackAlreadyProvided,
    })

    const commentField = await wrapper.findByPlaceholderText(
      'Thanks for the feedback. Please explain what went wrong?',
    )

    const fieldNode = getNode(commentField.id)

    await wrapper.events.type(commentField, 'Never trust AI')

    await fieldNode?.settled

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit comment' }))

    const usageMutation = await waitForAiAnalyticsUsageMutationCalls()

    expect(usageMutation.at(-1)?.variables).toEqual({
      aiAnalyticsRunId: RUN_ID,
      input: { comment: 'Never trust AI' },
    })

    expect(await wrapper.findByText('Thank you for your feedback.')).toBeInTheDocument()
    expect(
      wrapper.queryByPlaceholderText('Thanks for the feedback. Please explain what went wrong?'),
    ).not.toBeInTheDocument()
    expect(useNotifications().notifications.value).toHaveLength(0)
  })

  describe('when feedback was provided already in another view', () => {
    beforeEach(() => {
      mockAiAnalyticsUsageMutationError('You have already provided feedback, thank you.', {
        type: GraphQLErrorTypes.AiFeedbackAlreadyProvided,
      })
    })

    const renderWithTrackedUsage = () =>
      renderCommonAIFeedback({
        analyticsMeta: { run: { id: RUN_ID }, usage: { userHasProvidedFeedback: false } },
      })

    it('shows the feedback as given after a positive rating', async () => {
      const wrapper = renderWithTrackedUsage()

      await wrapper.events.click(wrapper.getByLabelText('Positive feedback'))

      await waitForAiAnalyticsUsageMutationCalls()

      expect(await wrapper.findByText('Thank you for your feedback.')).toBeInTheDocument()
      expect(wrapper.queryByLabelText('Positive feedback')).not.toBeInTheDocument()
      expect(wrapper.emitted('rated')).toHaveLength(1)
      expect(useNotifications().notifications.value).toHaveLength(0)
    })

    it('shows the feedback as given instead of the comment field after a negative rating', async () => {
      const wrapper = renderWithTrackedUsage()

      await wrapper.events.click(wrapper.getByLabelText('Negative feedback'))

      await waitForAiAnalyticsUsageMutationCalls()

      expect(await wrapper.findByText('Thank you for your feedback.')).toBeInTheDocument()
      expect(
        wrapper.queryByPlaceholderText('Thanks for the feedback. Please explain what went wrong?'),
      ).not.toBeInTheDocument()
      expect(wrapper.queryByLabelText('Negative feedback')).not.toBeInTheDocument()
      expect(wrapper.emitted('rated')).toHaveLength(1)
      expect(useNotifications().notifications.value).toHaveLength(0)
    })
  })

  it('emits regenerate event', async () => {
    const wrapper = renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID } },
    })

    await waitForAiAnalyticsUsageMutationCalls()

    await wrapper.events.click(wrapper.getByLabelText('Regenerate'))

    expect(wrapper.emitted('regenerate')).toHaveLength(1)
  })

  it('hides regenerate button with noRegeneration prop', async () => {
    const wrapper = renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID } },
      noRegeneration: true,
    })

    await waitForAiAnalyticsUsageMutationCalls()

    expect(wrapper.queryByRole('button', { name: 'Regenerate' })).not.toBeInTheDocument()
  })

  it('shows regenerate button when userHasProvidedFeedback is true', async () => {
    const wrapper = renderCommonAIFeedback({
      analyticsMeta: {
        run: { id: RUN_ID },
        usage: {
          userHasProvidedFeedback: true,
        },
      },
    })

    expect(wrapper.getByRole('button', { name: 'Regenerate' })).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Positive feedback' })).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Negative feedback' })).not.toBeInTheDocument()
  })

  it('renders nothing for a result rated earlier that cannot be regenerated', () => {
    const wrapper = renderCommonAIFeedback({
      analyticsMeta: { run: { id: RUN_ID }, usage: { userHasProvidedFeedback: true } },
      noRegeneration: true,
      noUsageTracking: true,
    })

    expect(wrapper.container).toBeEmptyDOMElement()
  })

  it('keeps the comment field when the rating sets the feedback flag', async () => {
    const props = {
      analyticsMeta: { run: { id: RUN_ID } },
      noRegeneration: true,
      noUsageTracking: true,
    }

    const wrapper = renderCommonAIFeedback(props)

    await wrapper.events.click(wrapper.getByLabelText('Negative feedback'))
    await waitForAiAnalyticsUsageMutationCalls()

    await wrapper.rerender({
      ...props,
      analyticsMeta: { run: { id: RUN_ID }, usage: { userHasProvidedFeedback: true } },
    })

    expect(
      wrapper.getByPlaceholderText('Thanks for the feedback. Please explain what went wrong?'),
    ).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'No comment' }))

    expect(wrapper.getByText('Thank you for your feedback.')).toBeInTheDocument()
  })

  it('gives every comment field its own id', async () => {
    const props = { analyticsMeta: { run: { id: RUN_ID } }, noUsageTracking: true }
    const placeholder = 'Thanks for the feedback. Please explain what went wrong?'

    renderCommonAIFeedback(props)
    const wrapper = renderCommonAIFeedback(props)

    const [firstButton, secondButton] = wrapper.getAllByLabelText('Negative feedback')
    await wrapper.events.click(firstButton)
    await wrapper.events.click(secondButton)

    const [firstField, secondField] = await wrapper.findAllByPlaceholderText(placeholder)

    expect(firstField.id).not.toBe(secondField.id)
  })
})
