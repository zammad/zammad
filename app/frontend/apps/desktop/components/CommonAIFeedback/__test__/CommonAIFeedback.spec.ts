// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

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

    await wrapper.events.click(wrapper.getByLabelText('Positive Feedback'))

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

    await wrapper.events.click(wrapper.getByLabelText('Negative Feedback'))

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

    await wrapper.events.click(wrapper.getByLabelText('Negative Feedback'))

    await waitForAiAnalyticsUsageMutationCalls()

    expect(wrapper.emitted('rated')).toHaveLength(1)

    await wrapper.events.type(
      wrapper.getByPlaceholderText('Thanks for the feedback. Please explain what went wrong?'),
      'Never trust AI',
    )

    await waitFor(() => expect(wrapper.getByRole('textbox')).toHaveValue('Never trust AI'))

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Submit Comment' }))

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

    await wrapper.events.click(wrapper.getByLabelText('Negative Feedback'))

    await waitForAiAnalyticsUsageMutationCalls()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'No Comment' }))

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
    expect(wrapper.queryByRole('button', { name: 'Positive Feedback' })).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Negative Feedback' })).not.toBeInTheDocument()
  })
})
