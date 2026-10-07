// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { mockApolloClient } from '#cy/utils.ts'

import { KnowledgeBaseAnswerSuggestionContentTransformDocument } from '#shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.api.ts'
import { KnowledgeBaseAnswerSuggestionsDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/knowledgeBase/answerSuggestions.api.ts'
import type { MentionKnowledgeBaseRelatedAnswers } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mountEditorWithAttachments } from './utils.ts'

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

const transformResult = {
  data: {
    knowledgeBaseAnswerSuggestionContentTransform: {
      __typename: 'KnowledgeBaseAnswerSuggestionContentTransform',
      body: 'Install the VPN client.',
      attachments: [
        {
          id: convertToGraphQLId('Store', 2062),
          name: 'vpn-profile.ovpn',
          size: 2048,
          type: 'application/x-openvpn-profile',
          preferences: {},
          __typename: 'StoredFile',
        },
      ],
      errors: null,
    },
  },
}

const mountWithRelatedAnswers = (answers = relatedAnswers()) =>
  mountEditorWithAttachments(['ticket.agent'], { relatedAnswers: () => answers })

const openKnowledgeBaseMention = () => {
  cy.findByRole('textbox').type('??')
}

describe('Testing "knowledge base" popup: "??" command with related answers', () => {
  let transform: Cypress.Agent<sinon.SinonSpy>

  beforeEach(() => {
    const client = mockApolloClient()

    transform = cy.spy(async () => transformResult)

    client.setRequestHandler(KnowledgeBaseAnswerSuggestionContentTransformDocument, transform)
    client.setRequestHandler(KnowledgeBaseAnswerSuggestionsDocument, async () => ({
      data: {
        knowledgeBaseAnswerSuggestions: [
          {
            __typename: 'KnowledgeBaseAnswerTranslation',
            id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 3),
            title: 'Printer setup',
            maybeLocale: null,
            categoryTreeTranslation: [
              {
                __typename: 'KnowledgeBaseCategoryTranslation',
                id: convertToGraphQLId('KnowledgeBase::Category::Translation', 2),
                title: 'Hardware',
              },
            ],
          },
        ],
      },
    }))
  })

  it('offers the linked answers first and the suggested ones second before anything is typed', () => {
    mountWithRelatedAnswers()
    openKnowledgeBaseMention()

    cy.findByTestId('mention-knowledge-base')
      .findAllByRole('option')
      .should('have.length', 2)
      .then((options) => {
        expect(options.eq(0)).to.contain.text('VPN setup on company notebooks (Windows)')
        expect(options.eq(1)).to.contain.text('VPN troubleshooting')
      })
  })

  it('offers the linked answers only when no suggestions are handed over', () => {
    mountWithRelatedAnswers(relatedAnswers({ suggested: [] }))
    openKnowledgeBaseMention()

    cy.findByTestId('mention-knowledge-base')
      .findAllByRole('option')
      .should('have.length', 1)
      .and('contain.text', 'VPN setup on company notebooks (Windows)')
  })

  it('shows only the search hint when nothing is linked or suggested', () => {
    mountWithRelatedAnswers(relatedAnswers({ linked: [], suggested: [] }))
    openKnowledgeBaseMention()

    cy.findByTestId('mention-knowledge-base')
      .should('contain.text', 'Start typing to search in knowledge base…')
      .findAllByRole('option')
      .should('not.exist')
  })

  it('offers the related answers that arrive while the list is open', () => {
    const answers = ref(relatedAnswers({ linked: [], suggested: [] }))

    mountEditorWithAttachments(['ticket.agent'], { relatedAnswers: () => answers.value })
    openKnowledgeBaseMention()

    cy.findByTestId('mention-knowledge-base').should(
      'contain.text',
      'Start typing to search in knowledge base…',
    )

    cy.then(() => {
      answers.value = relatedAnswers({ suggested: [] })
    })

    cy.findByTestId('mention-knowledge-base')
      .findAllByRole('option')
      .should('have.length', 1)
      .and('contain.text', 'VPN setup on company notebooks (Windows)')

    cy.then(() => {
      answers.value = relatedAnswers()
    })

    cy.findByTestId('mention-knowledge-base')
      .findAllByRole('option')
      .should('have.length', 2)
      .then((options) => {
        expect(options.eq(0)).to.contain.text('VPN setup on company notebooks (Windows)')
        expect(options.eq(1)).to.contain.text('VPN troubleshooting')
      })
  })

  it('keeps the search results when related answers arrive', () => {
    const answers = ref(relatedAnswers({ linked: [], suggested: [] }))

    mountEditorWithAttachments(['ticket.agent'], { relatedAnswers: () => answers.value })
    openKnowledgeBaseMention()

    cy.findByRole('textbox').type('Printer')

    cy.findByTestId('mention-knowledge-base').should('contain.text', 'Printer setup')

    cy.then(() => {
      answers.value = relatedAnswers()
    })

    cy.findByTestId('mention-knowledge-base')
      .should('contain.text', 'Printer setup')
      .and('not.contain.text', 'VPN troubleshooting')
  })

  it('switches to the search results once a search term is typed', () => {
    mountWithRelatedAnswers()
    openKnowledgeBaseMention()

    cy.findByTestId('mention-knowledge-base').should('contain.text', 'VPN troubleshooting')

    cy.findByRole('textbox').type('Printer')

    cy.findByTestId('mention-knowledge-base')
      .should('contain.text', 'Printer setup')
      .and('not.contain.text', 'VPN troubleshooting')
  })

  it('inserts an offered answer with its attachments, and typing continues after it', () => {
    mountWithRelatedAnswers()
    openKnowledgeBaseMention()

    cy.findByTestId('mention-knowledge-base').findByText('VPN troubleshooting').click()

    cy.findByRole('textbox')
      .should('contain.text', 'Install the VPN client.')
      .type(' Then reconnect.')
      .should('contain.text', 'Install the VPN client. Then reconnect.')

    cy.contains('vpn-profile.ovpn').should('exist')

    cy.wrap(transform).should('have.been.calledWithMatch', {
      translationId: convertToGraphQLId('KnowledgeBase::Answer::Translation', 2),
    })
  })
})
