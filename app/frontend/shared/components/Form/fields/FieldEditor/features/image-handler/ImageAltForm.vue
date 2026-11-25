<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { omit } from 'lodash-es'
import { ref } from 'vue'

import { useFloatingForm } from '#shared/components/Form/fields/FieldEditor/composables/useFloatingForm.ts'
import { getEditorEditorLinkFormClasses } from '#shared/components/Form/fields/FieldEditor/features/link/initializeLinkFormClasses.ts'
import Form from '#shared/components/Form/Form.vue'

defineOptions({
  // Every floating popover is handed the editor, which this form has no use for.
  inheritAttrs: false,
})

const props = defineProps<{
  alt?: string | null
}>()

const emit = defineEmits<{
  save: [alt: string]
  cancel: []
}>()

const { form, formSubmit } = useFloatingForm()

const alt = ref(props.alt ?? '')

const save = () => emit('save', alt.value)

const cancel = () => emit('cancel')

const { button, buttonContainer, form: formClass } = getEditorEditorLinkFormClasses()
</script>

<template>
  <div
    v-bind="omit($attrs, 'editor')"
    ref="container"
    class="z-20"
    role="dialog"
    :aria-label="$t('Alternative text')"
  >
    <!-- Escape stays in the dialog: an editor field blurs whatever has the focus on any Escape. -->
    <Form
      ref="form"
      :class="formClass"
      @submit="save"
      @keydown.enter="
        (event: KeyboardEvent) => {
          event.preventDefault()
          formSubmit()
        }
      "
      @keydown.esc.stop="cancel"
    >
      <FormKit
        v-model.trim="alt"
        name="alt"
        :label="$t('Alternative text')"
        :help="$t('Describe the image for people who cannot see it.')"
      />

      <div :class="buttonContainer">
        <button
          :class="button.secondary"
          class="ms-auto"
          type="button"
          @click="cancel"
          @keydown.enter.stop.prevent="cancel"
        >
          {{ $t('Cancel') }}
        </button>

        <button :class="button.primary" type="submit">
          {{ $t('Save') }}
        </button>
      </div>
    </Form>
  </div>
</template>
