// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Editor } from '@tiptap/vue-3'
import { flushPromises } from '@vue/test-utils'
import { effectScope, ref } from 'vue'

import '#tests/graphql/builders/mocks.ts'

import {
  mockKnowledgeBaseAnswerSuggestionContentTransformMutation,
  waitForKnowledgeBaseAnswerSuggestionContentTransformMutationCalls,
} from '#shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.mocks.ts'
import type {
  FieldEditorProps,
  MentionKnowledgeBaseRelatedAnswers,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import createKnowledgeBaseSuggestion from '../KnowledgeBaseSuggestion.ts'

const attachmentField = { value: [], input: vi.fn() }

vi.mock('#shared/components/Form/utils.ts', () => ({
  getNodeByName: () => attachmentField,
}))

const relatedAnswer = (id: number, title: string, maybeLocale?: string) => ({
  id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
  title,
  maybeLocale,
  categoryTreeTranslation: [],
})

const relatedAnswers: MentionKnowledgeBaseRelatedAnswers = {
  linked: [relatedAnswer(1, 'VPN setup on company notebooks (Windows)')],
  suggested: [relatedAnswer(2, 'VPN troubleshooting', 'DE-DE')],
}

const getItemsBeforeTyping = async (answers?: MentionKnowledgeBaseRelatedAnswers) => {
  const context = ref({
    formId: 'form',
    meta: answers ? { mentionKnowledgeBase: { relatedAnswers: () => answers } } : {},
  } as unknown as FormFieldContext<FieldEditorProps>)

  const scope = effectScope()
  const extension = scope.run(() => createKnowledgeBaseSuggestion(context))!

  const items = await extension.options.suggestion.items!({
    query: '',
    editor: {} as Editor,
    signal: new AbortController().signal,
  })

  scope.stop()

  return items
}

describe('KnowledgeBaseSuggestion before a search term is typed', () => {
  it('offers the linked answers first and the suggested ones second', async () => {
    expect(await getItemsBeforeTyping(relatedAnswers)).toEqual([
      expect.objectContaining({
        title: 'VPN setup on company notebooks (Windows)',
        section: 'linked',
      }),
      expect.objectContaining({
        title: 'VPN troubleshooting',
        maybeLocale: 'DE-DE',
        section: 'suggested',
      }),
    ])
  })

  it('offers nothing without related answers', async () => {
    expect(await getItemsBeforeTyping()).toEqual([])
  })
})

describe('KnowledgeBaseSuggestion insert from outside the editor', () => {
  const attachment = { id: convertToGraphQLId('Store', 1), name: 'vpn.pdf' }

  const renderEditor = () => {
    const context = ref({
      formId: 'form',
      meta: { mentionKnowledgeBase: { attachmentsNodeName: 'attachments' } },
    } as unknown as FormFieldContext<FieldEditorProps>)

    const scope = effectScope()
    const editor = scope.run(
      () =>
        new Editor({
          extensions: [Document, Paragraph, Text, createKnowledgeBaseSuggestion(context)],
        }),
    )!

    onTestFinished(() => {
      if (!editor.isDestroyed) editor.destroy()
      scope.stop()
    })

    return editor
  }

  beforeEach(() => {
    attachmentField.input.mockClear()

    mockKnowledgeBaseAnswerSuggestionContentTransformMutation({
      knowledgeBaseAnswerSuggestionContentTransform: {
        body: '<p>Connect to the VPN first.</p>',
        attachments: [attachment],
        errors: null,
      },
    })
  })

  it('adds the attachments while the editor is still there', async () => {
    const editor = renderEditor()

    editor.commands.insertKnowledgeBaseAnswer(relatedAnswer(1, 'VPN setup').id)

    await waitForKnowledgeBaseAnswerSuggestionContentTransformMutationCalls()
    await flushPromises()

    expect(attachmentField.input).toHaveBeenCalledWith([expect.objectContaining(attachment)])
    expect(editor.getHTML()).toContain('Connect to the VPN first.')
  })

  it('adds nothing once the editor is destroyed', async () => {
    const editor = renderEditor()

    editor.commands.insertKnowledgeBaseAnswer(relatedAnswer(1, 'VPN setup').id)
    editor.destroy()

    await waitForKnowledgeBaseAnswerSuggestionContentTransformMutationCalls()
    await flushPromises()

    expect(attachmentField.input).not.toHaveBeenCalled()
  })

  it('replaces the selected text', async () => {
    const editor = renderEditor()

    editor.commands.setContent('<p>Hello world</p>')
    editor.commands.setTextSelection({ from: 7, to: 12 })
    editor.commands.insertKnowledgeBaseAnswer(relatedAnswer(1, 'VPN setup').id)

    await waitForKnowledgeBaseAnswerSuggestionContentTransformMutationCalls()
    await flushPromises()

    expect(editor.getHTML()).toBe('<p>Hello </p><p>Connect to the VPN first.</p>')
  })

  it('keeps text typed at the edges of the selection while the answer loads', async () => {
    const editor = renderEditor()

    editor.commands.setContent('<p>Hello world</p>')
    editor.commands.setTextSelection({ from: 7, to: 12 })
    editor.commands.insertKnowledgeBaseAnswer(relatedAnswer(1, 'VPN setup').id)

    editor.commands.insertContentAt(12, '!')
    editor.commands.insertContentAt(7, 'dear ')

    await waitForKnowledgeBaseAnswerSuggestionContentTransformMutationCalls()
    await flushPromises()

    expect(editor.getHTML()).toBe('<p>Hello dear </p><p>Connect to the VPN first.</p><p>!</p>')
  })
})
