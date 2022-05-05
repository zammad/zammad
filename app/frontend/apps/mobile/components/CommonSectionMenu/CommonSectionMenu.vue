<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { MenuItem } from '@mobile/components/CommonSectionMenu'
import CommonSectionMenuLink from '@mobile/components/CommonSectionMenu/CommonSectionMenuLink.vue'

// TODO: Do not output anything, when no items are given via prop or slot?

export interface Props {
  actionTitle?: string
  headerTitle?: string
  items?: MenuItem[]
}

defineProps<Props>()

const emit = defineEmits<{
  (e: 'action-click', event: MouseEvent): void
}>()

const clickOnAction = (event: MouseEvent) => {
  emit('action-click', event)
}
</script>

<template>
  <div class="flex flex-row justify-between">
    <div class="pl-4">
      <slot name="header">{{ i18n.t(headerTitle) }}</slot>
    </div>
    <div
      v-if="actionTitle"
      class="cursor-pointer pr-4 text-blue"
      v-on:click="clickOnAction"
    >
      {{ i18n.t(actionTitle) }}
    </div>
  </div>
  <div
    class="w-fill m-2 flex flex-col rounded-xl bg-gray-500 px-2 py-1 text-white"
  >
    <slot>
      <template v-for="(item, idx) in items" v-bind:key="idx">
        <CommonSectionMenuLink v-if="item.type === 'link'" v-bind="item" />
      </template>
    </slot>
  </div>
</template>
