// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import { mockAiAssistanceTextToolsListQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/aiAssistanceTextTools/aiAssistanceTextToolsList.mocks.ts'
import { mockAiAssistanceTextToolsRunMutation } from '#shared/graphql/mutations/aiAssistanceTextToolsRun.mocks.ts'
import { getAiTextToolUpdatesSubscriptionHandler } from '#shared/graphql/subscriptions/aiTextToolUpdates.mocks.ts'

import { findEditor, mountEditor } from './browser-utils.ts'

describe('Testing AI text tools', () => {
  it('inserts a text', async () => {
    mockAiAssistanceTextToolsListQuery({
      aiAssistanceTextToolsList: [{ name: 'Text Tool 1', active: true }],
    })
    const run = mockAiAssistanceTextToolsRunMutation({
      aiAssistanceTextToolsRun: { output: 'Some new text returned.' },
    })

    await mountEditor(
      {},
      {
        config: { ai_assistance_text_tools: true, ai_provider: true },
        permissions: ['ticket.agent'],
      },
    )

    const editor = await findEditor()
    await userEvent.type(editor, 'Some text which should be checked.')
    await userEvent.keyboard('{ControlOrMeta>}a{/ControlOrMeta}')

    await page.getByLabelText('AI writing assistant tools').click()
    await page.getByRole('button', { name: 'Text Tool 1' }).click()

    await expect.element(editor).toHaveTextContent('Some new text returned.')

    const [call] = await run.waitForCalls()
    expect(call.variables.input).toBe('Some text which should be checked.')

    expect(getAiTextToolUpdatesSubscriptionHandler()).toBeDefined()
  })

  // Held back, so an aborted signal fails a run instead of answering it.
  const mockRunHoldingBackTheFirst = () => {
    let runCount = 0

    return mockAiAssistanceTextToolsRunMutation(async () => {
      runCount += 1
      if (runCount === 1) await new Promise(() => {})

      return { aiAssistanceTextToolsRun: { output: 'Text of the second run.' } }
    })
  }

  const mountTextToolsEditor = async () => {
    mockAiAssistanceTextToolsListQuery({
      aiAssistanceTextToolsList: [{ name: 'Text Tool 1', active: true }],
    })

    await mountEditor(
      {},
      {
        config: { ai_assistance_text_tools: true, ai_provider: true },
        permissions: ['ticket.agent'],
      },
    )

    const editor = await findEditor()
    await userEvent.type(editor, 'Some text which should be checked.')

    return editor
  }

  const runTextTool = async () => {
    await userEvent.keyboard('{ControlOrMeta>}a{/ControlOrMeta}')
    await page.getByLabelText('AI writing assistant tools').click()
    await page.getByRole('button', { name: 'Text Tool 1' }).click()
  }

  it('cancels a run quietly and runs again with a request of its own', async () => {
    const { notifications, clearAllNotifications } = useNotifications()
    clearAllNotifications()

    const run = mockRunHoldingBackTheFirst()
    const editor = await mountTextToolsEditor()

    await runTextTool()
    await run.waitForCalls()

    await page.getByRole('button', { name: 'Cancel' }).click()
    await expect.element(page.getByText('Generating text…')).not.toBeInTheDocument()

    await runTextTool()

    await expect.element(editor).toHaveTextContent('Text of the second run.')
    expect(notifications.value).toHaveLength(0)
  })

  it('aborts a run when the text is changed meanwhile', async () => {
    const { notifications, clearAllNotifications } = useNotifications()
    clearAllNotifications()

    const run = mockRunHoldingBackTheFirst()
    const editor = await mountTextToolsEditor()

    await runTextTool()
    await run.waitForCalls()

    await getNode('editor')!.input('<p>Text changed from outside.</p>')
    await expect.element(page.getByText('Generating text…')).not.toBeInTheDocument()

    await expect.element(editor).toHaveTextContent('Text changed from outside.')
    expect(notifications.value.map(({ message }) => message)).toEqual([
      'The text was modified. Your request has been aborted to prevent overwriting.',
    ])
  })
})
