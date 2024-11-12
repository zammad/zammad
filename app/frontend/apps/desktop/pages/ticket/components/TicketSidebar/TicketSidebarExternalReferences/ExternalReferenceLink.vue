<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  id: number
  showId?: boolean
  title: string
  link: string
  isEditable: boolean
  tooltip: string
}

const props = defineProps<Props>()

defineEmits<{
  remove: [{ id: number }]
}>()

const linkContent = computed(() => {
  if (props.showId) {
    return `#${props.id} ${props.title}`
  }

  return props.title
})

const { isTouchDevice } = useTouchDevice()
</script>

<template>
  <div class="flex gap-2">
    <CommonLink
      class="grow"
      size="medium"
      external
      open-in-new-tab
      :link="link"
    >
      {{ linkContent }}
    </CommonLink>
    <CommonButton
      v-if="isEditable"
      v-tooltip="tooltip"
      icon="x-lg"
      size="small"
      variant="remove"
      :class="{
        'opacity-0 focus-visible:opacity-100 group-hover:opacity-100':
          !isTouchDevice,
      }"
      @click="$emit('remove', { id })"
    />
  </div>
</template>
