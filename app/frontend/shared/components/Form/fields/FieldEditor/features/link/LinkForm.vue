<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, onMounted, ref, useTemplateRef } from 'vue'

import { getEditorEditorLinkFormClasses } from '#shared/components/Form/fields/FieldEditor/features/link/initializeLinkFormClasses.ts'
import { EXTENSION_NAME as LINK_EXTENSION_NAME } from '#shared/components/Form/fields/FieldEditor/features/link/types.ts'
import { getSelection } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import Form from '#shared/components/Form/Form.vue'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'

import type { Editor } from '@tiptap/vue-3'

const props = defineProps<{
  editor?: Editor
}>()

const currentSelection = getSelection(props.editor!)

const { form, waitForFormSettled, formSubmit, isValid } = useForm()

const container = useTemplateRef('container')

const { activateTabTrap } = useTrapTab(container)

onMounted(async () => {
  await nextTick()
  activateTabTrap()
  await waitForFormSettled()

  // formkit doesn't work with autofocus, so we need to manually focus the input
  container.value?.querySelector('input')?.focus()
})

const getCurrentUrl = () => props.editor?.getAttributes(LINK_EXTENSION_NAME)?.href

const hasActiveLinkMark = computed(getCurrentUrl)

const getCurrentLinkLabel = () => {
  const { state } = props.editor!
  const { from, to } = state.selection

  if (hasActiveLinkMark.value) {
    const activeNode = props.editor!.state.selection.$head.parent

    const linkNode = activeNode.children.find((node) =>
      node.marks.some((mark) => mark.type.name === 'link'),
    )

    if (linkNode) return linkNode.text
  }

  return state.doc.textBetween(from, to, '')
}
const url = ref(hasActiveLinkMark.value ? getCurrentUrl() : '')

const linkText = ref(getCurrentLinkLabel())

const handleNewLink = () => {
  props
    .editor!.chain()
    .focus()
    .deleteRange(currentSelection)
    .insertContentAt(currentSelection.from, {
      type: 'text',
      text: linkText.value?.length ? linkText.value : url.value,
      marks: [
        {
          type: LINK_EXTENSION_NAME,
          attrs: {
            href: url.value,
            target: '_blank',
          },
        },
      ],
    })
    .run()
}

const handleLinkUpdate = () => {
  props
    .editor!.chain()
    .focus()
    .extendMarkRange(LINK_EXTENSION_NAME)
    .insertContent({
      type: 'text',
      text: linkText.value?.length ? linkText.value : url.value,
      marks: [
        {
          type: LINK_EXTENSION_NAME,
          attrs: {
            href: url.value,
            target: '_blank',
          },
        },
      ],
    })
    .run()
}

const close = () => props.editor!.commands.closeLinkForm()

const submitLink = () => {
  if (hasActiveLinkMark.value) {
    handleLinkUpdate()
  } else {
    handleNewLink()
  }

  close()
}

const removeLink = () => {
  props.editor!.chain().focus().unsetMark(LINK_EXTENSION_NAME, { extendEmptyMarkRange: true }).run()

  close()
}

const { button, buttonContainer, form: formClass } = getEditorEditorLinkFormClasses()
</script>

<template>
  <div ref="container" class="z-20" role="dialog">
    <Form
      ref="form"
      :class="formClass"
      @submit="submitLink"
      @keydown.enter="
        (event: KeyboardEvent) => {
          // Link for opening in a new tab
          if ((event.target as HTMLElement)?.tagName === 'A') return

          event.preventDefault()
          if (isValid)
            // form submission validation is not triggered by calling formSubmit
            formSubmit()
        }
      "
      @keydown.esc="close"
    >
      <FormKit
        v-model.trim="url"
        name="url"
        validation="required"
        :link="url"
        :label="$t('Link URL')"
      />
      <FormKit v-model.trim="linkText" name="label" :label="$t('Link text')" />

      <div :class="buttonContainer">
        <button
          v-if="hasActiveLinkMark"
          :class="button.danger"
          type="reset"
          @click="removeLink"
          @keydown.enter.stop="removeLink"
        >
          {{ $t('Remove link') }}
        </button>

        <button
          :class="button.secondary"
          class="ms-auto"
          type="button"
          @click="close"
          @keydown.enter.stop="close"
        >
          {{ $t('Cancel') }}
        </button>

        <button :class="button.primary" type="submit">
          {{ $t('Add link') }}
        </button>
      </div>
    </Form>
  </div>
</template>
