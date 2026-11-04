// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

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
})
