// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { nextTick } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import LinkForm from '#shared/components/Form/fields/FieldEditor/features/link/LinkForm.vue'
import { EXTENSION_NAME as LINK_EXTENSION_NAME } from '#shared/components/Form/fields/FieldEditor/features/link/types.ts'

describe('LinkForm', () => {
  let editor: any

  beforeEach(() => {
    editor = {
      commands: {
        closeLinkForm: vi.fn().mockReturnValue(true),
      },
      chain: vi.fn().mockReturnThis(),
      focus: vi.fn().mockReturnThis(),
      deleteRange: vi.fn().mockReturnThis(),
      insertContentAt: vi.fn().mockReturnThis(),
      extendMarkRange: vi.fn().mockReturnThis(),
      insertContent: vi.fn().mockReturnThis(),
      unsetMark: vi.fn().mockReturnThis(),
      run: vi.fn().mockReturnValue(true),
      getAttributes: vi.fn().mockReturnValue({}),
      state: {
        selection: {
          from: 0,
          to: 0,
          $head: {
            parent: {
              children: [],
            },
          },
        },
        doc: {
          textBetween: vi.fn().mockReturnValue(''),
        },
      },
    }
  })

  it('should render the LinkForm component', () => {
    const wrapper = renderComponent(LinkForm, {
      props: { editor },
      form: true,
    })

    expect(wrapper.getByRole('textbox', { name: 'Link URL' })).toBeTruthy()
    expect(wrapper.getByRole('textbox', { name: 'Link text' })).toBeTruthy()
    expect(wrapper.getByRole('button', { name: 'Add link' })).toBeTruthy()
  })

  it('should add a new link on submit when no active link exists', async () => {
    const wrapper = renderComponent(LinkForm, {
      props: { editor },
      form: true,
      router: true,
    })

    await wrapper.events.type(
      wrapper.getByRole('textbox', { name: 'Link URL' }),
      'https://example.com',
    )
    await wrapper.events.type(wrapper.getByRole('textbox', { name: 'Link text' }), 'Example Link')

    // Submit the form
    await wrapper.events.click(wrapper.getByText('Add link'))

    // Verify expected editor commands were called
    expect(editor.chain).toHaveBeenCalled()
    expect(editor.deleteRange).toHaveBeenCalled()
    expect(editor.insertContentAt).toHaveBeenCalledWith(0, {
      type: 'text',
      text: 'Example Link',
      marks: [
        {
          type: LINK_EXTENSION_NAME,
          attrs: {
            href: 'https://example.com',
            target: '_blank',
          },
        },
      ],
    })
    expect(editor.run).toHaveBeenCalled()
    expect(editor.commands.closeLinkForm).toHaveBeenCalled()
  })

  it('should update an existing link when an active link exists', async () => {
    editor.getAttributes = vi.fn().mockReturnValue({ href: 'https://old-url.com' })

    const wrapper = renderComponent(LinkForm, {
      props: { editor },
      form: true,
      router: true,
    })

    await nextTick()

    await wrapper.events.clear(wrapper.getByRole('textbox', { name: 'Link URL' }))

    await wrapper.events.type(
      wrapper.getByRole('textbox', { name: 'Link URL' }),
      'https://updated.com',
    )
    await wrapper.events.type(wrapper.getByRole('textbox', { name: 'Link text' }), 'Updated Link')

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Add link' }))

    // Verify expected editor commands were called
    expect(editor.chain).toHaveBeenCalled()
    expect(editor.extendMarkRange).toHaveBeenCalledWith(LINK_EXTENSION_NAME)
    expect(editor.insertContent).toHaveBeenCalledWith({
      type: 'text',
      text: 'Updated Link',
      marks: [
        {
          type: LINK_EXTENSION_NAME,
          attrs: {
            href: 'https://updated.com',
            target: '_blank',
          },
        },
      ],
    })
    expect(editor.run).toHaveBeenCalled()
  })

  it('should remove a link when remove button is clicked', async () => {
    editor.getAttributes = vi.fn().mockReturnValue({ href: 'https://example.com' })

    const wrapper = renderComponent(LinkForm, {
      props: { editor },
      form: true,
    })

    const removeButton = wrapper.getByText('Remove link')
    await wrapper.events.click(removeButton)

    expect(editor.chain).toHaveBeenCalled()
    expect(editor.unsetMark).toHaveBeenCalledWith(LINK_EXTENSION_NAME, {
      extendEmptyMarkRange: true,
    })
    expect(editor.commands.closeLinkForm).toHaveBeenCalled()
  })

  it('should close the form when cancel button is clicked', async () => {
    const wrapper = renderComponent(LinkForm, {
      props: { editor },
      form: true,
    })

    await wrapper.events.click(wrapper.getByText('Cancel'))

    expect(editor.commands.closeLinkForm).toHaveBeenCalled()
  })
})
