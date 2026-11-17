// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, ref, useTemplateRef, type Ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import type { FieldEditorProps } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { useInlineMode } from '#shared/components/Form/fields/FieldEditor/useInlineMode.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

const renderInlineModeWrapper = (context: {
  inline: boolean
  disabled?: boolean
  id?: string
  reset?: () => void
}) => {
  const Component = defineComponent({
    setup() {
      const fieldContext = ref({
        id: 'editor-field',
        node: { emit: vi.fn() },
        ...context,
      }) as unknown as Ref<FormFieldContext<FieldEditorProps>>

      const { isEditing, onWrapperClick } = useInlineMode(fieldContext, useTemplateRef('wrapper'))

      return { isEditing, onWrapperClick }
    },
    template: `
      <div ref="wrapper" role="button" tabindex="0" @click="onWrapperClick">{{ isEditing }}</div>
    `,
  })

  return renderComponent(Component)
}

describe('useInlineMode', () => {
  it('starts editing when an inline field is clicked', async () => {
    const wrapper = renderInlineModeWrapper({ inline: true })

    await wrapper.events.click(wrapper.getByRole('button'))

    expect(wrapper.getByRole('button')).toHaveTextContent('true')
  })

  // A disabled editor renders with pointer events on, so the content stays
  //   selectable (#6494) and the click reaches the wrapper again.
  it('does not start editing when the inline field is disabled', async () => {
    const wrapper = renderInlineModeWrapper({ inline: true, disabled: true })

    await wrapper.events.click(wrapper.getByRole('button'))

    expect(wrapper.getByRole('button')).toHaveTextContent('false')
  })

  it('does not start editing when the field is not in inline mode', async () => {
    const wrapper = renderInlineModeWrapper({ inline: false })

    await wrapper.events.click(wrapper.getByRole('button'))

    expect(wrapper.getByRole('button')).toHaveTextContent('false')
  })

  // Escape used to blur every editor, inline or not (#6525).
  it('does not handle Escape when the field is not in inline mode', async () => {
    const reset = vi.fn()
    const wrapper = renderInlineModeWrapper({ inline: false, id: 'editor-not-inline', reset })

    wrapper.getByRole('button').focus()
    await wrapper.events.keyboard('{Escape}')

    expect(reset).not.toHaveBeenCalled()
    expect(wrapper.getByRole('button')).toHaveFocus()
  })

  it('cancels on Escape only while the inline field is being edited', async () => {
    const reset = vi.fn()
    const wrapper = renderInlineModeWrapper({ inline: true, id: 'editor-inline', reset })

    await wrapper.events.keyboard('{Escape}')
    expect(reset).not.toHaveBeenCalled()

    await wrapper.events.click(wrapper.getByRole('button'))
    await wrapper.events.keyboard('{Escape}')

    expect(reset).toHaveBeenCalledOnce()
    expect(wrapper.getByRole('button')).toHaveTextContent('false')
  })
})
