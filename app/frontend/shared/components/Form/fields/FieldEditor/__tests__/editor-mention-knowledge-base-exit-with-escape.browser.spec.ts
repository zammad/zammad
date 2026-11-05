// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockKnowledgeBaseAnswerSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/knowledgeBase/answerSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  editorHtml,
  findEditor,
  mountEditorWithAttachments,
  waitForLastSearch,
} from './browser-utils.ts'

describe('Testing "knowledge base" popup: "??" command', () => {
  it('inserts a knowledge base mention > but exit on Esc > keyboard keys should still work', async () => {
    const suggestions = mockKnowledgeBaseAnswerSuggestionsQuery({
      knowledgeBaseAnswerSuggestions: [
        {
          id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
          title: 'How to create a ticket?',
          categoryTreeTranslation: [
            {
              id: convertToGraphQLId('KnowledgeBase::Category::Translation', 1),
              title: 'Category 1',
            },
          ],
        },
      ],
    })

    await mountEditorWithAttachments({}, { permissions: ['ticket.agent'] })

    const editor = await findEditor()
    await userEvent.type(editor, '??How to c')
    await waitForLastSearch(suggestions, { query: 'How to c' })

    const popup = page.getByTestId('mention-knowledge-base')

    await expect.element(popup).toBeInTheDocument()
    await userEvent.keyboard('{Escape}')
    await expect.element(popup).not.toBeInTheDocument()

    await expect.poll(editorHtml).toContain('<p dir="auto">??How to c</p>')
    // Escape in any editor currently blurs it (see zammad/zammad#6525); `type` refocuses it.
    await userEvent.type(editor, '{Backspace}{Backspace}123')
    await expect.poll(editorHtml).toContain('<p dir="auto">??How to123</p>')
    await userEvent.type(editor, '{ArrowLeft}{ArrowLeft}654')
    await expect.poll(editorHtml).toContain('<p dir="auto">??How to165423</p>')
  })
})
