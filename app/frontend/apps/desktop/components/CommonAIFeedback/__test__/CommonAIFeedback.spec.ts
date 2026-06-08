// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

import { renderComponent } from '#tests/support/components/index.ts'

import { waitForAiAnalyticsUsageMutationCalls } from '#shared/graphql/mutations/aiAnalyticsUsage.mocks.ts'

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

    const fieldNode = getNode('feedback-comment')

    const commentField = await wrapper.findByPlaceholderText(
      'Thanks for the feedback. Please explain what went wrong?',
    )

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
})
