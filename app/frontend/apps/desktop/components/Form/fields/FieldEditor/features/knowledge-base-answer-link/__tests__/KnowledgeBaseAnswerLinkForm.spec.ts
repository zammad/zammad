// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Editor } from '@tiptap/vue-3'

import { renderComponent } from '#tests/support/components/index.ts'

import Link from '#shared/components/Form/fields/FieldEditor/extensions/Link.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseAnswerLinkForm from '#desktop/components/Form/fields/FieldEditor/features/knowledge-base-answer-link/KnowledgeBaseAnswerLinkForm.vue'
import FieldEditorActionBar from '#desktop/components/Form/fields/FieldEditor/FieldEditorActionBar.vue'
import {
  mockAutocompleteSearchKnowledgeBaseAnswerQuery,
  waitForAutocompleteSearchKnowledgeBaseAnswerQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/autocompleteSearch.mocks.ts'

const answerOption = {
  __typename: 'AutocompleteSearchKnowledgeBaseAnswerEntry' as const,
  value: convertToGraphQLId('KnowledgeBase::Answer::Translation', 42),
  label: 'Reset your password',
  heading: 'Account',
  visibility: EnumKnowledgeBaseVisibility.Published,
  url: '/desktop/knowledge-base/locale/en-us/answer/7',
}

const renderForm = (editor: Editor) =>
  renderComponent(KnowledgeBaseAnswerLinkForm, {
    props: { editor },
    form: true,
    router: true,
    store: true,
    dialog: true,
  })

const pickAnswer = async (view: ReturnType<typeof renderForm>) => {
  await view.events.click(await view.findByLabelText('Answer'))

  mockAutocompleteSearchKnowledgeBaseAnswerQuery({
    autocompleteSearchKnowledgeBaseAnswer: [answerOption],
  })

  await view.events.type(view.getByRole('searchbox'), 'password')

  await waitForAutocompleteSearchKnowledgeBaseAnswerQueryCalls()

  await view.events.click(view.getAllByTestId('select-item')[0])
}

const renderEditor = (content: string) =>
  new Editor({
    extensions: [Document, Paragraph, Text, Link],
    content,
  })

const renderToolbar = (editor: Editor) =>
  renderComponent(FieldEditorActionBar, {
    props: {
      editor,
      contentType: 'text/html',
      visible: true,
      disabledExtensions: [],
    },
    form: true,
    router: true,
    store: true,
    dialog: true,
  })

describe('KnowledgeBaseAnswerLinkForm', () => {
  it('inserts a link carrying the internal translation id', async () => {
    const editor = renderEditor('<p>Hello</p>')

    const view = renderForm(editor)

    await pickAnswer(view)

    await view.events.click(view.getByRole('button', { name: 'Link answer' }))

    const html = editor.getHTML()

    expect(html).toContain('data-target-type="knowledge-base-answer"')
    expect(html).toContain('data-target-id="42"')
    expect(html).toContain('href="/desktop/knowledge-base/locale/en-us/answer/7"')

    editor.destroy()
  })

  it('uses the answer title as the link text when nothing is selected', async () => {
    const editor = renderEditor('<p>Hello</p>')

    const view = renderForm(editor)

    await pickAnswer(view)

    await view.events.click(view.getByRole('button', { name: 'Link answer' }))

    expect(editor.getHTML()).toContain('>Reset your password</a>')

    editor.destroy()
  })

  it('links the selected text instead of the answer title', async () => {
    const editor = renderEditor('<p>Hello there</p>')

    editor.commands.setTextSelection({ from: 1, to: 6 })

    const view = renderForm(editor)

    await pickAnswer(view)

    await view.events.click(view.getByRole('button', { name: 'Link answer' }))

    const html = editor.getHTML()

    expect(html).toContain('>Hello</a>')
    expect(html).toContain('data-target-id="42"')
    expect(html).not.toContain('Reset your password')

    editor.destroy()
  })

  it('offers no link to an answer before one is picked', async () => {
    const editor = renderEditor('<p>Hello</p>')

    const view = renderForm(editor)

    await view.findByLabelText('Answer')

    expect(view.queryByTestId('common-link')).not.toBeInTheDocument()

    editor.destroy()
  })

  it('offers a link to the picked answer, which stays in the current tab', async () => {
    const editor = renderEditor('<p>Hello</p>')

    const view = renderForm(editor)

    await pickAnswer(view)

    const link = view.getByTestId('common-link')

    // The app's own mount point comes off the answer's URL, so following it is an in-app
    //   navigation rather than a page load. The test router does not know the route, which is
    //   what leaves the path here unresolved.
    expect(link).toHaveAttribute('href', '/knowledge-base/locale/en-us/answer/7')
    expect(link).not.toHaveAttribute('target')

    editor.destroy()
  })

  describe('with the caret inside an existing answer link', () => {
    const existingAnswerLink =
      '<p><a href="/desktop/knowledge-base/locale/en-us/answer/7" data-target-type="knowledge-base-answer" data-target-id="42">Some answer</a></p>'

    it('prefills the picker with the linked answer', async () => {
      const editor = renderEditor(existingAnswerLink)

      editor.commands.setTextSelection(3)

      const view = renderForm(editor)

      expect(await view.findByText('Some answer')).toBeInTheDocument()

      editor.destroy()
    })

    it('offers a link to the answer it already points at', async () => {
      const editor = renderEditor(existingAnswerLink)

      editor.commands.setTextSelection(3)

      const view = renderForm(editor)

      expect(await view.findByTestId('common-link')).toHaveAttribute(
        'href',
        '/knowledge-base/locale/en-us/answer/7',
      )

      editor.destroy()
    })

    // The form floats above the editor, so nothing else takes it down when the link is followed.
    it('closes itself when the link to the answer is followed', async () => {
      const editor = renderEditor(existingAnswerLink)

      editor.commands.setTextSelection(3)

      // The real command manager rebuilds its commands on every access, which a spy cannot survive.
      const closeLinkForm = vi.fn()
      const editorWithSpy = Object.create(editor, {
        commands: { value: { ...editor.commands, closeLinkForm } },
      }) as Editor

      const view = renderComponent(KnowledgeBaseAnswerLinkForm, {
        props: { editor: editorWithSpy },
        form: true,
        router: true,
        store: true,
        dialog: true,
      })

      await view.events.click(await view.findByTestId('common-link'))

      expect(closeLinkForm).toHaveBeenCalled()

      editor.destroy()
    })

    // Enter on the focused link follows it, the way a click does. Preventing the keystroke's
    //   default would cancel that activation and submit the form instead.
    it('leaves Enter on the link to the answer to the link', async () => {
      const editor = renderEditor(existingAnswerLink)

      editor.commands.setTextSelection(3)

      const view = renderForm(editor)

      const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, cancelable: true })

      ;(await view.findByTestId('common-link')).dispatchEvent(event)

      expect(event.defaultPrevented).toBe(false)

      editor.destroy()
    })

    it('keeps the link as it is when submitted without picking another answer', async () => {
      const editor = renderEditor(existingAnswerLink)

      editor.commands.setTextSelection(3)

      const view = renderForm(editor)

      await view.events.click(await view.findByRole('button', { name: 'Link answer' }))

      const html = editor.getHTML()

      expect(html).toContain('data-target-id="42"')
      expect(html).toContain('href="/desktop/knowledge-base/locale/en-us/answer/7"')
      expect(html).toContain('>Some answer</a>')

      editor.destroy()
    })

    it('removes the link', async () => {
      const editor = renderEditor(existingAnswerLink)

      editor.commands.setTextSelection(3)

      const view = renderForm(editor)

      await view.events.click(view.getByRole('button', { name: 'Remove link' }))

      const html = editor.getHTML()

      expect(html).not.toContain('data-target')
      expect(html).not.toContain('<a')
      expect(html).toContain('Some answer')

      editor.destroy()
    })

    // Both tools write the same `link` mark, so each has to recognize only its own kind of link.
    it('highlights the answer link tool in the toolbar, not the plain link one', () => {
      const editor = renderEditor(existingAnswerLink)

      editor.commands.setTextSelection(3)

      const view = renderToolbar(editor)

      expect(view.getByLabelText('Link answer')).toHaveAttribute('aria-pressed', 'true')
      expect(view.getByLabelText('Add link')).toHaveAttribute('aria-pressed', 'false')

      editor.destroy()
    })
  })

  describe('with the caret inside one of the answer links of a row', () => {
    const answerLink = (id: string, answer: string, text: string) =>
      `<a href="/desktop/knowledge-base/locale/en-us/answer/${answer}" data-target-type="knowledge-base-answer" data-target-id="${id}">${text}</a>`

    const twoAnswerLinks = `<p>${answerLink('42', '7', 'First answer')} and ${answerLink('43', '9', 'Second answer')}</p>`

    // Inside the second link: 'First answer' plus ' and ' ahead of it, and the row starts at 1.
    const caretInSecondLink = 1 + 'First answer and '.length + 1

    it('prefills the picker with the link the caret is in', async () => {
      const editor = renderEditor(twoAnswerLinks)

      editor.commands.setTextSelection(caretInSecondLink)

      const view = renderForm(editor)

      expect(await view.findByText('Second answer')).toBeInTheDocument()
      expect(view.queryByText('First answer')).not.toBeInTheDocument()

      editor.destroy()
    })

    it('keeps that link as it is when submitted without picking another answer', async () => {
      const editor = renderEditor(twoAnswerLinks)

      editor.commands.setTextSelection(caretInSecondLink)

      const view = renderForm(editor)

      await view.events.click(await view.findByRole('button', { name: 'Link answer' }))

      const html = editor.getHTML()

      // Each link keeps its own text, the one the caret was in included.
      expect(html).toContain('data-target-id="42">First answer</a>')
      expect(html).toContain('data-target-id="43">Second answer</a>')

      editor.destroy()
    })
  })

  describe('with the caret inside an ordinary link', () => {
    it('highlights the plain link tool in the toolbar, not the answer link one', () => {
      const editor = renderEditor('<p><a href="https://example.com">Example</a></p>')

      editor.commands.setTextSelection(3)

      const view = renderToolbar(editor)

      expect(view.getByLabelText('Add link')).toHaveAttribute('aria-pressed', 'true')
      expect(view.getByLabelText('Link answer')).toHaveAttribute('aria-pressed', 'false')

      editor.destroy()
    })
  })
})
