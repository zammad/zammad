// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, ref, useTemplateRef, type Ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import type { FieldEditorProps } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { useInlineMode } from '#shared/components/Form/fields/FieldEditor/useInlineMode.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

const renderInlineModeWrapper = (context: { inline: boolean; disabled?: boolean }) => {
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
      <div ref="wrapper" role="button" @click="onWrapperClick">{{ isEditing }}</div>
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
})
