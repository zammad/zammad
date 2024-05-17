<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { FieldTagsContext } from '#shared/components/Form/fields/FieldTags/types.ts'
import { useFormBlock } from '#shared/form/useFormBlock.ts'

import { useDialog } from '#mobile/composables/useDialog.ts'

interface Props {
  context: FieldTagsContext
}

const props = defineProps<Props>()

const reactiveContext = toRef(props, 'context')

const { localValue } = useValue(reactiveContext)

const selectedTagsList = computed(() => {
  if (!localValue.value || !Array.isArray(localValue.value)) return []
  return localValue.value
})

const nameDialog = `field-tags-${props.context.id}`

const dialog = useDialog({
  name: nameDialog,
  prefetch: true,
  component: () => import('./FieldTagsDialog.vue'),
  afterClose: () => {
    reactiveContext.value.node.emit('dialog:afterClose', reactiveContext.value)
  },
})

const showDialog = () => {
  if (props.context.disabled) return
  return dialog.open({
    name: dialog.name,
    context: reactiveContext,
  })
}

const onInputClick = () => {
  if (dialog.isOpened.value) return
  showDialog()
}

useFormBlock(reactiveContext, onInputClick)
</script>

<template>
  <div
    :class="context.classes.input"
    class="flex h-auto rounded-none bg-transparent"
    data-test-id="field-tags"
  >
    <output
      :id="context.id"
      :name="context.node.name"
      role="combobox"
      class="formkit-disabled:pointer-events-none flex grow items-center focus:outline-none"
      :aria-disabled="context.disabled ? 'true' : undefined"
      tabindex="0"
      v-bind="context.attrs"
      aria-haspopup="dialog"
      data-multiple="true"
      :aria-labelledby="`label-${context.id}`"
      :aria-controls="`dialog-${nameDialog}`"
      :aria-owns="`dialog-${nameDialog}`"
      :aria-expanded="dialog.isOpened.value"
      @keyup.shift.down.prevent="showDialog()"
      @keypress.space.prevent="showDialog()"
      @blur="context.handlers.blur"
    >
      <div
        v-if="selectedTagsList.length"
        class="flex grow flex-wrap gap-1"
        role="list"
      >
        <div
          v-for="tag of selectedTagsList"
          :key="tag"
          class="bg-gray/20 text-gray rounded-sm px-[4px] py-[2px] text-base uppercase leading-4"
          role="listitem"
        >
          {{ tag }}
        </div>
      </div>
    </output>
  </div>
</template>
