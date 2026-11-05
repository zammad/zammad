// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it, onTestFinished } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import {
  mockKnowledgeBaseAnswerSuggestionContentTransformMutation,
  mockKnowledgeBaseAnswerSuggestionContentTransformMutationError,
} from '#shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  editorHtml,
  findEditor,
  getEditorContext,
  mountEditor,
  moveCursorToStart,
  pressCursorKey,
  selectText,
} from './browser-utils.ts'

const translationId = convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)

const ANSWER_BODY = 'knowledge base answer body'

const transformResult = (body = ANSWER_BODY) => ({
  knowledgeBaseAnswerSuggestionContentTransform: { body, attachments: [] },
})

const mockTransform = (
  defaults: Parameters<
    typeof mockKnowledgeBaseAnswerSuggestionContentTransformMutation
  >[0] = transformResult(),
) => mockKnowledgeBaseAnswerSuggestionContentTransformMutation(defaults)

// The transform requires the form ID, which a field mounted outside a form does not have.
const mountLoadedEditor = async (props: Record<string, unknown> = {}) => {
  await mountEditor({ formId: 'form', ...props }, { permissions: ['ticket.agent'] })

  const editor = await findEditor()
  const context = await getEditorContext()

  return { editor, context }
}

const editorText = () => page.getByRole('textbox').element().textContent

// The insert is triggered from outside the editor, which takes the focus away first.
const insertAnswer = async (id = translationId) => {
  const editor = page.getByRole('textbox').element() as HTMLElement
  editor.blur()

  const context = await getEditorContext()
  context.insertKnowledgeBaseAnswer(id)
}

describe('inserting a knowledge base answer from outside the editor', () => {
  it('inserts the answer where the cursor was last', async () => {
    const transform = mockTransform()

    const { editor } = await mountLoadedEditor()

    await userEvent.type(editor, 'Hello world')
    await pressCursorKey('{ArrowLeft}'.repeat(6))

    await insertAnswer()

    await expect.poll(editorText).toBe(`Hello${ANSWER_BODY} world`)
    const [call] = await transform.waitForCalls()
    expect(call.variables).toMatchObject({ translationId })

    // The cursor is left after the inserted content.
    await expect.element(editor).toHaveFocus()
    await userEvent.keyboard('!')
    await expect.poll(editorText).toBe(`Hello${ANSWER_BODY}! world`)
  })

  it('replaces the selected text', async () => {
    mockTransform()

    const { editor } = await mountLoadedEditor()

    await userEvent.type(editor, 'Hello world')
    await userEvent.keyboard('{ControlOrMeta>}a{/ControlOrMeta}')

    await insertAnswer()

    await expect.poll(editorText).toBe(ANSWER_BODY)
  })

  it('replaces a partial selection and leaves the cursor after the answer', async () => {
    mockTransform()

    const { editor } = await mountLoadedEditor()

    await userEvent.type(editor, 'Hello world')
    await selectText('left', 5)

    await insertAnswer()

    await expect.poll(editorText).toBe(`Hello ${ANSWER_BODY}`)

    await expect.element(editor).toHaveFocus()
    await userEvent.keyboard('!')
    await expect.poll(editorText).toBe(`Hello ${ANSWER_BODY}!`)
  })

  it('keeps the position in step with text typed while the answer loads', async () => {
    let resolveTransform: () => void = () => {}

    const transform = mockTransform(
      () =>
        new Promise((resolve) => {
          resolveTransform = () => resolve(transformResult())
        }),
    )

    const { editor } = await mountLoadedEditor()

    await userEvent.type(editor, 'Hello')

    await insertAnswer()

    await moveCursorToStart(editor)
    await userEvent.keyboard('Hi ')

    await transform.waitForCalls()
    resolveTransform()

    await expect.poll(editorText).toBe(`Hi Hello${ANSWER_BODY}`)
  })

  it('inserts several answers one after another', async () => {
    let call = 0

    mockTransform(() => {
      call += 1
      return transformResult(`answer ${call}`)
    })

    const { editor } = await mountLoadedEditor()

    await userEvent.type(editor, 'Hello ')

    await insertAnswer()
    await expect.poll(editorText).toBe('Hello answer 1')
    // The insert hands the focus back to the editor a frame later.
    await expect.element(editor).toHaveFocus()

    await insertAnswer(convertToGraphQLId('KnowledgeBase::Answer::Translation', 2))
    await expect.poll(editorText).toBe('Hello answer 1answer 2')
  })

  it('inserts at the start, above the signature, when no cursor was placed', async () => {
    mockTransform()

    const { context } = await mountLoadedEditor({
      signatureEnabled: true,
      signature: { renderedBody: '<strong>Signature</strong>', internalId: 1 },
    })

    await expect.poll(editorHtml).toContain('data-signature-id="1"')

    context.insertKnowledgeBaseAnswer(translationId)

    await expect.poll(editorHtml).toContain(ANSWER_BODY)

    const html = editorHtml()

    expect(html.indexOf(ANSWER_BODY)).toBeLessThan(html.indexOf('data-signature-id="1"'))
  })

  it('inserts into a plain text editor', async () => {
    mockTransform()

    const { editor } = await mountLoadedEditor({ contentType: 'text/plain' })

    await userEvent.type(editor, 'Hello ')

    await insertAnswer()

    await expect.poll(editorText).toBe(`Hello ${ANSWER_BODY}`)
  })

  it('inserts nothing when the answer cannot be loaded', async () => {
    const { hasErrors, clearAllNotifications } = useNotifications()

    onTestFinished(clearAllNotifications)

    mockKnowledgeBaseAnswerSuggestionContentTransformMutationError(
      'The requested object was not found.',
      { type: GraphQLErrorTypes.RecordNotFound },
    )

    const { editor } = await mountLoadedEditor()

    await userEvent.type(editor, 'Hello')

    await insertAnswer()

    // Notified once the request failed, so an insert would have happened by now.
    await expect.poll(hasErrors).toBe(true)
    expect(editorText()).toBe('Hello')
  })

  it('is not offered by an editor without the knowledge base mention', async () => {
    const { context } = await mountLoadedEditor({
      meta: { mentionKnowledgeBase: { disabled: true } },
    })

    expect(context.insertKnowledgeBaseAnswer).toBeUndefined()
  })
})
