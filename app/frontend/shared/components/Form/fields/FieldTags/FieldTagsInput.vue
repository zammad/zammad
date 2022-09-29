<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { useDialog } from '@shared/composables/useDialog'
import useValue from '../../composables/useValue'
import type { FieldTagsContext } from './types'

interface Props {
  context: FieldTagsContext
}

const props = defineProps<Props>()

const context = toRef(props, 'context')

const { localValue } = useValue(context)

const selectedTagsList = computed(() => {
  if (!localValue.value || !Array.isArray(localValue.value)) return []
  return localValue.value
})

const dialog = useDialog({
  name: `field-tags-${props.context.node.name}`,
  prefetch: true,
  component: () => import('./FieldTagsDialog.vue'),
})

const showDialog = () => {
  return dialog.open({
    name: dialog.name,
    context,
  })
}
</script>

<template>
  <div
    :class="context.classes.input"
    class="flex h-auto rounded-none bg-transparent focus-within:bg-blue-highlight focus-within:pt-0 formkit-populated:pt-0"
    data-test-id="field-tags"
  >
    <output
      :id="context.id"
      :name="context.node.name"
      class="flex grow cursor-pointer items-center focus:outline-none formkit-disabled:pointer-events-none"
      :aria-disabled="context.disabled"
      :tabindex="context.disabled ? '-1' : '0'"
      v-bind="context.attrs"
      role="list"
      @click="showDialog()"
      @keypress.space="showDialog()"
      @blur="context.handlers.blur"
    >
      <div class="flex grow flex-wrap gap-1">
        <div
          v-for="tag of selectedTagsList"
          :key="tag"
          class="rounded-sm bg-gray/20 py-[2px] px-[4px] text-base uppercase leading-4 text-gray"
        >
          {{ tag }}
        </div>
      </div>
    </output>
  </div>
</template>
