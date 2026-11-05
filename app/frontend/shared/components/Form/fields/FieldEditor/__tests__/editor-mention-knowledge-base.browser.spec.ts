// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mockKnowledgeBaseAnswerSuggestionContentTransformMutation } from '#shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.mocks.ts'
import { mockKnowledgeBaseAnswerSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/knowledgeBase/answerSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { findEditor, mountEditorWithAttachments, waitForLastSearch } from './browser-utils.ts'

describe('Testing "knowledge base" popup: "??" command', () => {
  it('inserts a knowledge base mention', async () => {
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

    mockKnowledgeBaseAnswerSuggestionContentTransformMutation({
      knowledgeBaseAnswerSuggestionContentTransform: {
        body: 'knowledge base answer body',
        attachments: [
          {
            id: convertToGraphQLId('Store', 2062),
            name: 'Zammad.png',
            size: 945213,
            type: 'image/png',
            preferences: {
              'Content-Type': 'image/png',
              resizable: true,
              content_preview: true,
            },
          },
        ],
      },
    })

    await mountEditorWithAttachments({}, { permissions: ['ticket.agent'] })

    const editor = await findEditor()

    // Without related answers handed over, nothing is offered before a search term is typed.
    await userEvent.type(editor, '??')

    const popup = page.getByTestId('mention-knowledge-base')

    await expect.element(popup).toMatchTextContent('Start typing to search in knowledge base…')
    expect(popup.getByRole('option').length).toBe(0)

    await userEvent.keyboard('How to c') // supports space

    await waitForLastSearch(suggestions, { query: 'How to c' })

    await expect.element(popup).toMatchTextContent('How to create a ticket?')
    await popup.getByText('How to create a ticket?').click()

    await expect.element(editor).toMatchTextContent('knowledge base answer body')
    await userEvent.keyboard('{Backspace}{Backspace}r')
    await expect.element(editor).toMatchTextContent('knowledge base answer bor')

    await expect.element(page.getByText('Zammad.png')).toBeInTheDocument()
    await expect.element(page.getByText('923 KB')).toBeInTheDocument()
  })
})
