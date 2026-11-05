// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach, describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'
import { ref } from 'vue'

import { mockKnowledgeBaseAnswerSuggestionContentTransformMutation } from '#shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.mocks.ts'
import { mockKnowledgeBaseAnswerSuggestionsQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/knowledgeBase/answerSuggestions.mocks.ts'
import type { MentionKnowledgeBaseRelatedAnswers } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { findEditor, mountEditorWithAttachments } from './browser-utils.ts'

const relatedAnswer = (id: number, title: string) => ({
  id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
  title,
  maybeLocale: null,
  categoryTreeTranslation: [
    {
      __typename: 'KnowledgeBaseCategoryTranslation' as const,
      id: convertToGraphQLId('KnowledgeBase::Category::Translation', 1),
      title: 'Network',
    },
  ],
})

const relatedAnswers = (
  overrides: Partial<MentionKnowledgeBaseRelatedAnswers> = {},
): MentionKnowledgeBaseRelatedAnswers => ({
  linked: [relatedAnswer(1, 'VPN setup on company notebooks (Windows)')],
  suggested: [relatedAnswer(2, 'VPN troubleshooting')],
  ...overrides,
})

const mountWithRelatedAnswers = (answers = relatedAnswers()) =>
  mountEditorWithAttachments({ relatedAnswers: () => answers }, { permissions: ['ticket.agent'] })

const openKnowledgeBaseMention = async () => {
  await userEvent.type(await findEditor(), '??')

  return page.getByTestId('mention-knowledge-base')
}

describe('Testing "knowledge base" popup: "??" command with related answers', () => {
  let transform: ReturnType<typeof mockKnowledgeBaseAnswerSuggestionContentTransformMutation>

  beforeEach(() => {
    transform = mockKnowledgeBaseAnswerSuggestionContentTransformMutation({
      knowledgeBaseAnswerSuggestionContentTransform: {
        body: 'Install the VPN client.',
        attachments: [
          {
            id: convertToGraphQLId('Store', 2062),
            name: 'vpn-profile.ovpn',
            size: 2048,
            type: 'application/x-openvpn-profile',
            preferences: {},
          },
        ],
      },
    })

    mockKnowledgeBaseAnswerSuggestionsQuery({
      knowledgeBaseAnswerSuggestions: [
        {
          id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 3),
          title: 'Printer setup',
          maybeLocale: null,
          categoryTreeTranslation: [
            {
              id: convertToGraphQLId('KnowledgeBase::Category::Translation', 2),
              title: 'Hardware',
            },
          ],
        },
      ],
    })
  })

  it('offers the linked answers first and the suggested ones second before anything is typed', async () => {
    await mountWithRelatedAnswers()

    const options = (await openKnowledgeBaseMention()).getByRole('option')

    await expect.poll(() => options.length).toBe(2)
    await expect
      .element(options.nth(0))
      .toMatchTextContent('VPN setup on company notebooks (Windows)')
    await expect.element(options.nth(1)).toMatchTextContent('VPN troubleshooting')
  })

  it('offers the linked answers only when no suggestions are handed over', async () => {
    await mountWithRelatedAnswers(relatedAnswers({ suggested: [] }))

    const options = (await openKnowledgeBaseMention()).getByRole('option')

    await expect.poll(() => options.length).toBe(1)
    await expect.element(options).toMatchTextContent('VPN setup on company notebooks (Windows)')
  })

  it('shows only the search hint when nothing is linked or suggested', async () => {
    await mountWithRelatedAnswers(relatedAnswers({ linked: [], suggested: [] }))

    const popup = await openKnowledgeBaseMention()

    await expect.element(popup).toMatchTextContent('Start typing to search in knowledge base…')
    expect(popup.getByRole('option').length).toBe(0)
  })

  it('offers the related answers that arrive while the list is open', async () => {
    const answers = ref(relatedAnswers({ linked: [], suggested: [] }))

    await mountEditorWithAttachments(
      { relatedAnswers: () => answers.value },
      { permissions: ['ticket.agent'] },
    )

    const popup = await openKnowledgeBaseMention()
    const options = popup.getByRole('option')

    await expect.element(popup).toMatchTextContent('Start typing to search in knowledge base…')

    answers.value = relatedAnswers({ suggested: [] })

    await expect.poll(() => options.length).toBe(1)
    await expect.element(options).toMatchTextContent('VPN setup on company notebooks (Windows)')

    answers.value = relatedAnswers()

    await expect.poll(() => options.length).toBe(2)
    await expect
      .element(options.nth(0))
      .toMatchTextContent('VPN setup on company notebooks (Windows)')
    await expect.element(options.nth(1)).toMatchTextContent('VPN troubleshooting')
  })

  it('keeps the search results when related answers arrive', async () => {
    const answers = ref(relatedAnswers({ linked: [], suggested: [] }))

    await mountEditorWithAttachments(
      { relatedAnswers: () => answers.value },
      { permissions: ['ticket.agent'] },
    )

    const popup = await openKnowledgeBaseMention()

    await userEvent.keyboard('Printer')

    await expect.element(popup).toMatchTextContent('Printer setup')

    answers.value = relatedAnswers()

    await expect.element(popup).toMatchTextContent('Printer setup')
    await expect.element(popup).not.toMatchTextContent('VPN troubleshooting')
  })

  it('switches to the search results once a search term is typed', async () => {
    await mountWithRelatedAnswers()

    const popup = await openKnowledgeBaseMention()

    await expect.element(popup).toMatchTextContent('VPN troubleshooting')

    await userEvent.keyboard('Printer')

    await expect.element(popup).toMatchTextContent('Printer setup')
    await expect.element(popup).not.toMatchTextContent('VPN troubleshooting')
  })

  it('inserts an offered answer with its attachments, and typing continues after it', async () => {
    await mountWithRelatedAnswers()

    const popup = await openKnowledgeBaseMention()

    await popup.getByText('VPN troubleshooting').click()

    const editor = await findEditor()

    await expect.element(editor).toMatchTextContent('Install the VPN client.')
    await userEvent.keyboard(' Then reconnect.')
    await expect.element(editor).toMatchTextContent('Install the VPN client. Then reconnect.')

    await expect.element(page.getByText('vpn-profile.ovpn')).toBeInTheDocument()

    const [call] = await transform.waitForCalls()
    expect(call.variables).toMatchObject({
      translationId: convertToGraphQLId('KnowledgeBase::Answer::Translation', 2),
    })
  })
})
