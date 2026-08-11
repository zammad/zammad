<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, watch } from 'vue'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonPopover from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import type { NavigationGroup } from '#desktop/components/PageNavigation/navigationGroups.ts'
import {
  navigationItemClass,
  navigationItemHighlightClass,
} from '#desktop/components/PageNavigation/navigationItemClasses.ts'
import type { PageRoute } from '#desktop/components/PageNavigation/navigationItems.ts'

interface Props {
  group: NavigationGroup
  routes: PageRoute[]
  collapsed?: boolean
}

const props = defineProps<Props>()

const { popover, popoverTarget, isOpen, toggle, close } = usePopover()

const triggerId = computed(() => `page-navigation-group-trigger-${props.group.key}`)
const menuId = computed(() => `page-navigation-group-${props.group.key}`)

const menuItems = computed<MenuItem[]>(() =>
  props.routes.map((route) => ({
    key: route.path,
    label: route.meta.title,
    icon: route.meta.icon,
    link: route.path.replace(/\/:\w+/, ''),
  })),
)

// The trigger is swapped when the sidebar collapses, which would leave the menu
//   positioned from an element that no longer exists.
watch(() => props.collapsed, close)
</script>

<template>
  <CommonButton
    v-if="collapsed"
    :id="triggerId"
    ref="popoverTarget"
    v-tooltip="$t(group.title)"
    class="shrink-0 text-neutral-400 focus-visible-app-default hover:outline-blue-900"
    :class="{ [navigationItemHighlightClass]: isOpen }"
    size="large"
    variant="neutral"
    :icon="group.icon"
    aria-haspopup="true"
    :aria-expanded="isOpen"
    :aria-controls="isOpen ? menuId : undefined"
    @click="toggle(true)"
  />
  <button
    v-else
    :id="triggerId"
    ref="popoverTarget"
    type="button"
    class="cursor-pointer"
    :class="[navigationItemClass, { [navigationItemHighlightClass]: isOpen }]"
    aria-haspopup="true"
    :aria-expanded="isOpen"
    :aria-controls="isOpen ? menuId : undefined"
    @click="toggle(true)"
  >
    <CommonLabel class="gap-2 text-sm! text-current!" size="medium" :prefix-icon="group.icon">
      {{ $t(group.title) }}
    </CommonLabel>
    <CommonIcon
      class="ltr:ml-auto rtl:mr-auto"
      :name="isOpen ? 'chevron-up' : 'chevron-down'"
      size="xs"
      decorative
    />
  </button>

  <CommonPopover
    :id="menuId"
    ref="popover"
    :owner="popoverTarget"
    orientation="right"
    placement="start"
    hide-arrow
  >
    <CommonPopoverMenu :popover="popover" :items="menuItems" />
  </CommonPopover>
</template>
