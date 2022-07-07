<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import type { RouteLocationRaw } from 'vue-router'
import useSessionStore from '@shared/stores/session'
import type { MenuItem } from './types'
import CommonSectionMenuLink from './CommonSectionMenuLink.vue'

export interface Props {
  actionTitle?: string
  actionLink?: RouteLocationRaw
  headerTitle?: string
  items?: MenuItem[]
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'action-click', event: MouseEvent): void
}>()

const clickOnAction = (event: MouseEvent) => {
  emit('action-click', event)
}

const session = useSessionStore()

const itemsWithPermission = computed(() => {
  if (!props.items) return null

  return props.items.filter((item) => {
    if (item.permission) {
      return session.hasPermission(item.permission)
    }

    return true
  })
})
</script>

<template>
  <div
    v-if="itemsWithPermission || $slots.default"
    class="mb-2 flex flex-row justify-between"
  >
    <div class="text-white/80 ltr:pl-4 rtl:pr-4">
      <slot name="header">{{ i18n.t(headerTitle) }}</slot>
    </div>
    <component
      :is="actionLink ? 'CommonLink' : 'div'"
      v-if="actionTitle"
      :link="actionLink"
      class="cursor-pointer text-blue ltr:pr-4 rtl:pl-4"
      @click="clickOnAction"
    >
      {{ i18n.t(actionTitle) }}
    </component>
  </div>
  <div
    v-if="itemsWithPermission || $slots.default"
    class="w-fill mb-6 flex flex-col rounded-xl bg-gray-500 px-3 py-1 text-base text-white"
    v-bind="$attrs"
  >
    <slot name="before-items" />
    <slot>
      <template v-for="(item, idx) in itemsWithPermission" :key="idx">
        <CommonSectionMenuLink
          v-if="item.type === 'link'"
          :title="item.title"
          :link="item.link"
          :icon="item.icon"
          :icon-bg="item.iconBg"
          :information="item.information"
          @click="item.onClick as () => void"
        />
      </template>
    </slot>
  </div>
</template>
