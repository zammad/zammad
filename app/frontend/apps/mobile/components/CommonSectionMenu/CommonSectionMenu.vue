<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useSlots } from 'vue'
import type { RouteLocationRaw } from 'vue-router'
import { useSessionStore } from '@shared/stores/session'
import type { MenuItem } from './types'
import CommonSectionMenuLink from './CommonSectionMenuLink.vue'

export interface Props {
  actionLabel?: string
  actionLink?: RouteLocationRaw
  headerLabel?: string
  items?: MenuItem[]
  help?: string
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
  if (!props.items || !props.items.length) return null

  return props.items.filter((item) => {
    if (item.permission) {
      return session.hasPermission(item.permission)
    }

    return true
  })
})

const slots = useSlots()

const hasHelp = computed(() => slots.help || props.help)
const showLabel = computed(() => {
  if (!itemsWithPermission.value && !slots.default) return false
  return slots.header || props.headerLabel || props.actionLabel
})
</script>

<template>
  <div v-if="showLabel" class="mb-2 flex flex-row justify-between">
    <div class="text-white/80 ltr:pl-3 rtl:pr-3">
      <slot name="header">{{ i18n.t(headerLabel) }}</slot>
    </div>
    <component
      :is="actionLink ? 'CommonLink' : 'div'"
      v-if="actionLabel"
      :link="actionLink"
      class="cursor-pointer text-blue ltr:pr-4 rtl:pl-4"
      @click="clickOnAction"
    >
      {{ i18n.t(actionLabel) }}
    </component>
  </div>
  <div
    v-if="itemsWithPermission || $slots.default"
    class="flex w-full flex-col rounded-xl bg-gray-500 px-3 py-1 text-base text-white"
    :class="{ 'mb-6': !hasHelp }"
    v-bind="$attrs"
  >
    <slot name="before-items" />
    <slot>
      <template v-for="(item, idx) in itemsWithPermission" :key="idx">
        <CommonSectionMenuLink
          v-if="item.type === 'link'"
          :label="item.label"
          :link="item.link"
          :icon="item.icon"
          :icon-bg="item.iconBg"
          :information="item.information"
          :label-placeholder="item.labelPlaceholder"
          @click="item.onClick?.($event)"
        />
      </template>
    </slot>
  </div>
  <div v-if="hasHelp" class="mb-4 pt-1 text-xs text-gray-100 ltr:pl-3 rtl:pr-3">
    <slot name="help">
      {{ $t(help) }}
    </slot>
  </div>
</template>
