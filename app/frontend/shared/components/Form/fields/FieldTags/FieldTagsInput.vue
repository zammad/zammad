<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { useDialog } from '@shared/composables/useDialog'
import { useFormBlock } from '@mobile/form/useFormBlock'
import useValue from '../../composables/useValue'
import type { FieldTagsContext } from './types'

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

const dialog = useDialog({
  name: `field-tags-${props.context.id}`,
  prefetch: true,
  component: () => import('./FieldTagsDialog.vue'),
  afterClose: () => {
    reactiveContext.value.node.emit('dialog:afterClose', reactiveContext.value)
  },
})

const showDialog = () => {
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
      class="flex grow items-center focus:outline-none formkit-disabled:pointer-events-none"
      :aria-disabled="context.disabled"
      :tabindex="context.disabled ? '-1' : '0'"
      data-multiple="true"
      v-bind="context.attrs"
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
          class="rounded-sm bg-gray/20 py-[2px] px-[4px] text-base uppercase leading-4 text-gray"
          role="listitem"
        >
          {{ tag }}
        </div>
      </div>
    </output>
  </div>
</template>
