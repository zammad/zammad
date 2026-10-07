// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

// The global test setup replaces the editor with a textarea.
vi.unmock('#shared/components/Form/fields/FieldEditor/FieldEditorWrapper.vue')

describe('FieldEditorInput', () => {
  it('applies a value written after setup but before mount', async () => {
    // tiptap creates the editor on mount - write the value in the gap before it.
    const writeBeforeMount = {
      beforeMount(this: { $options: { __name?: string }; context: FormFieldContext }) {
        if (this.$options.__name !== 'FieldEditorInput') return

        this.context.node.input('<p>Quoted message</p>')
      },
    }

    const view = renderComponent(FormKit, {
      form: true,
      props: {
        id: 'editor',
        name: 'editor',
        type: 'editor',
      },
      global: {
        mixins: [writeBeforeMount],
      },
    })

    const textbox = await view.findByRole('textbox')

    await waitFor(() => {
      expect(textbox).toHaveTextContent('Quoted message')
      expect(getNode('editor')?.value).toContain('Quoted message')
    })
  })
})
