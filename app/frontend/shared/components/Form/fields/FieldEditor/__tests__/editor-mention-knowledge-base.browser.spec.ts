// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it, onTestFinished } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import {
  mockKnowledgeBaseAnswerSuggestionContentTransformMutation,
  mockKnowledgeBaseAnswerSuggestionContentTransformMutationError,
} from '#shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.mocks.ts'
import { mockKnowledgeBaseAnswerSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/knowledgeBase/answerSuggestions.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

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

  it('adds no attachments of an answer whose search was deleted while it loaded', async () => {
    const suggestions = mockKnowledgeBaseAnswerSuggestionsQuery({
      knowledgeBaseAnswerSuggestions: [
        {
          id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
          title: 'How to create a ticket?',
          categoryTreeTranslation: [],
        },
      ],
    })

    let deliver: () => void = () => {}

    const transform = mockKnowledgeBaseAnswerSuggestionContentTransformMutation(
      () =>
        new Promise((resolve) => {
          deliver = () =>
            resolve({
              knowledgeBaseAnswerSuggestionContentTransform: {
                body: 'knowledge base answer body',
                attachments: [
                  {
                    id: convertToGraphQLId('Store', 2062),
                    name: 'Zammad.png',
                    size: 945213,
                    type: 'image/png',
                    preferences: { 'Content-Type': 'image/png' },
                  },
                ],
              },
            })
        }),
    )

    await mountEditorWithAttachments({}, { permissions: ['ticket.agent'] })

    const editor = await findEditor()

    await userEvent.type(editor, '??How')
    await waitForLastSearch(suggestions, { query: 'How' })

    await expect
      .element(page.getByTestId('mention-knowledge-base'))
      .toMatchTextContent('How to create a ticket?')
    await expect.element(editor).toHaveAttribute('aria-activedescendant')

    await userEvent.keyboard('{Enter}')
    await userEvent.keyboard('{Backspace}{Backspace}{Backspace}{Backspace}{Backspace}')
    await expect.poll(() => editor.element().textContent).toBe('')

    await transform.waitForCalls()
    deliver()
    // Long enough for a late insertion to show.
    await new Promise((resolve) => setTimeout(resolve, 300))

    expect(editor.element().textContent).toBe('')
    expect(page.getByText('Zammad.png').query()).toBeNull()
  })

  it('keeps the search when the picked answer cannot be loaded', async () => {
    const unhandled: unknown[] = []
    const collect = (event: PromiseRejectionEvent) => {
      unhandled.push(event.reason)
      event.preventDefault()
    }

    window.addEventListener('unhandledrejection', collect)
    onTestFinished(() => window.removeEventListener('unhandledrejection', collect))

    mockKnowledgeBaseAnswerSuggestionsQuery({
      knowledgeBaseAnswerSuggestions: [
        {
          id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
          title: 'How to create a ticket?',
          categoryTreeTranslation: [],
        },
      ],
    })

    const transform = mockKnowledgeBaseAnswerSuggestionContentTransformMutationError(
      'The answer could not be loaded.',
      { type: GraphQLErrorTypes.UnknownError },
    )

    await mountEditorWithAttachments({}, { permissions: ['ticket.agent'] })

    const editor = await findEditor()

    await userEvent.type(editor, '??How')

    const popup = page.getByTestId('mention-knowledge-base')

    await expect.element(popup).toMatchTextContent('How to create a ticket?')
    await popup.getByText('How to create a ticket?').click()

    await transform.waitForCalls()
    // Long enough for the failed request to settle.
    await new Promise((resolve) => setTimeout(resolve, 300))

    expect(editor.element().textContent).toBe('??How')
    expect(unhandled).toEqual([])
  })

  it('opens no list for an agent with chat access but no ticket access', async () => {
    mockKnowledgeBaseAnswerSuggestionsQuery({ knowledgeBaseAnswerSuggestions: [] })

    await mountEditorWithAttachments({}, { permissions: ['chat.agent'] })

    const editor = await findEditor()

    await userEvent.type(editor, '??How')

    // Set as soon as a list opens, also while it loads.
    await expect.element(editor).not.toHaveAttribute('aria-haspopup')
    expect(page.getByTestId('mention-knowledge-base').query()).toBeNull()
  })

  describe('while a search is still running', () => {
    const answers = {
      knowledgeBaseAnswerSuggestions: [
        {
          id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
          title: 'How to create a ticket?',
          categoryTreeTranslation: [],
        },
      ],
    }

    // Past the time the list itself takes a writer for still typing.
    const waitUntilTypingIsOver = () => new Promise((resolve) => setTimeout(resolve, 500))

    it('keeps "Loading…" until the search for the term typed last is back', async () => {
      let deliver: (() => void) | undefined

      mockKnowledgeBaseAnswerSuggestionsQuery(
        () =>
          new Promise((resolve) => {
            deliver = () => resolve(answers)
          }),
      )

      await mountEditorWithAttachments({}, { permissions: ['ticket.agent'] })

      await userEvent.type(await findEditor(), '??How')

      const popup = page.getByTestId('mention-knowledge-base')

      await expect.poll(() => deliver).toBeDefined()
      await waitUntilTypingIsOver()

      await expect.element(popup).toMatchTextContent('Loading…')
      expect(popup.element().textContent).not.toContain('No results found')

      deliver?.()

      await expect.element(popup).toMatchTextContent('How to create a ticket?')
    })

    it('shows "Loading…" alone for one more key after a search is back', async () => {
      let deliver: (() => void) | undefined

      const suggestions = mockKnowledgeBaseAnswerSuggestionsQuery(({ query }) =>
        query === 'How'
          ? answers
          : new Promise((resolve) => {
              deliver = () =>
                resolve({
                  knowledgeBaseAnswerSuggestions: [
                    {
                      id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 2),
                      title: 'How to close a ticket?',
                      categoryTreeTranslation: [],
                    },
                  ],
                })
            }),
      )

      await mountEditorWithAttachments({}, { permissions: ['ticket.agent'] })

      await userEvent.type(await findEditor(), '??How')

      const popup = page.getByTestId('mention-knowledge-base')

      await expect.element(popup).toMatchTextContent('How to create a ticket?')

      await userEvent.keyboard(' ')
      await expect.poll(() => deliver).toBeDefined()
      await waitUntilTypingIsOver()

      await expect.element(popup).toMatchTextContent('Loading…')
      expect(popup.element().textContent).not.toContain('How to create a ticket?')
      expect(popup.element().textContent).not.toContain('No results found')

      deliver?.()

      await waitForLastSearch(suggestions, { query: 'How ' })
      await expect.element(popup).toMatchTextContent('How to close a ticket?')
      expect(popup.element().textContent).not.toContain('How to create a ticket?')
    })
  })
})
