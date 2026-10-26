// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

import { mockApolloClient } from '#cy/utils.ts'

import { KnowledgeBaseAnswerSuggestionContentTransformDocument } from '#shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.api.ts'
import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mountEditor } from './utils.ts'

const translationId = convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)

const ANSWER_BODY = 'knowledge base answer body'

const transformResult = (body = ANSWER_BODY) => ({
  data: {
    knowledgeBaseAnswerSuggestionContentTransform: {
      __typename: 'KnowledgeBaseAnswerSuggestionContentTransform',
      body,
      attachments: [],
      errors: null,
    },
  },
})

const mockTransform = (handler = async () => transformResult()) => {
  const client = mockApolloClient()
  const mock = cy.spy(handler)

  client.setRequestHandler(KnowledgeBaseAnswerSuggestionContentTransformDocument, mock)

  return mock
}

const getContext = () => getNode('editor')?.context as FieldEditorContext | undefined

const mountLoadedEditor = (props: Record<string, unknown> = {}, permissions = ['ticket.agent']) => {
  mountEditor(props, permissions)

  return cy.wrap(null).should(() => {
    expect(getContext()).to.have.property('_loaded', true)
  })
}

// The insert is triggered from outside the editor, which takes the focus away first.
const insertAnswer = (id = translationId) =>
  cy
    .findByRole('textbox')
    .blur()
    .then(() => getContext()!.insertKnowledgeBaseAnswer!(id))

describe('inserting a knowledge base answer from outside the editor', () => {
  it('inserts the answer where the cursor was last', () => {
    const mock = mockTransform()

    mountLoadedEditor()

    cy.findByRole('textbox').type(
      'Hello world{leftarrow}{leftarrow}{leftarrow}{leftarrow}{leftarrow}{leftarrow}',
    )

    insertAnswer()

    cy.findByRole('textbox').should('have.text', `Hello${ANSWER_BODY} world`)
    cy.wrap(mock).should('have.been.calledWithMatch', { translationId })

    // The cursor is left after the inserted content.
    cy.findByRole('textbox').type('!').should('have.text', `Hello${ANSWER_BODY}! world`)
  })

  it('replaces the selected text', () => {
    mockTransform()

    mountLoadedEditor()

    cy.findByRole('textbox').type('Hello world{selectall}')

    insertAnswer()

    cy.findByRole('textbox').should('have.text', ANSWER_BODY)
  })

  it('replaces a partial selection and leaves the cursor after the answer', () => {
    mockTransform()

    mountLoadedEditor()

    cy.findByRole('textbox').type('Hello world')
    cy.findByRole('textbox').selectText('left', 5)

    insertAnswer()

    cy.findByRole('textbox').should('have.text', `Hello ${ANSWER_BODY}`)
    cy.findByRole('textbox').type('!').should('have.text', `Hello ${ANSWER_BODY}!`)
  })

  it('keeps the position in step with text typed while the answer loads', () => {
    let resolveTransform: () => void = () => {}

    mockTransform(
      () =>
        new Promise((resolve) => {
          resolveTransform = () => resolve(transformResult())
        }),
    )

    mountLoadedEditor()

    cy.findByRole('textbox').type('Hello')

    insertAnswer()

    cy.findByRole('textbox')
      .type('{moveToStart}Hi ')
      .then(() => resolveTransform())

    cy.findByRole('textbox').should('have.text', `Hi Hello${ANSWER_BODY}`)
  })

  it('inserts several answers one after another', () => {
    let call = 0

    mockTransform(async () => {
      call += 1
      return transformResult(`answer ${call}`)
    })

    mountLoadedEditor()

    cy.findByRole('textbox').type('Hello ')

    insertAnswer()
    cy.findByRole('textbox').should('have.text', 'Hello answer 1')
    // The insert hands the focus back to the editor a frame later.
    cy.findByRole('textbox').should('have.focus')

    insertAnswer(convertToGraphQLId('KnowledgeBase::Answer::Translation', 2))
    cy.findByRole('textbox').should('have.text', 'Hello answer 1answer 2')
  })

  it('inserts at the start, above the signature, when no cursor was placed', () => {
    mockTransform()

    mountLoadedEditor({
      signatureEnabled: true,
      signature: { renderedBody: '<strong>Signature</strong>', internalId: 1 },
    })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).to.include('data-signature-id="1"')
    })

    cy.then(() => getContext()!.insertKnowledgeBaseAnswer!(translationId))

    cy.findByRole('textbox').should(($el) => {
      const html = $el.html()

      expect(html).to.include(ANSWER_BODY)
      expect(html.indexOf(ANSWER_BODY)).to.be.lessThan(html.indexOf('data-signature-id="1"'))
    })
  })

  it('inserts into a plain text editor', () => {
    mockTransform()

    mountLoadedEditor({ contentType: 'text/plain' })

    cy.findByRole('textbox').type('Hello ')

    insertAnswer()

    cy.findByRole('textbox').should('have.text', `Hello ${ANSWER_BODY}`)
  })

  it('inserts nothing when the answer cannot be loaded', () => {
    const mock = mockTransform(async () => ({
      errors: [{ message: 'The requested object was not found.' }],
    }))

    mountLoadedEditor()

    cy.findByRole('textbox').type('Hello')

    insertAnswer()

    cy.wrap(mock).should('have.been.called')
    cy.findByRole('textbox').should('have.text', 'Hello')
  })

  it('is not offered by an editor without the knowledge base mention', () => {
    mountLoadedEditor({ meta: { mentionKnowledgeBase: { disabled: true } } })

    cy.then(() => {
      expect(getContext()!.insertKnowledgeBaseAnswer).to.equal(undefined)
    })
  })
})
