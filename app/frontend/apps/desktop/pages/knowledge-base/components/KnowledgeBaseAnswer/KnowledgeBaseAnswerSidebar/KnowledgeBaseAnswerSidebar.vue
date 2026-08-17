<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { i18n } from '#shared/i18n.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'
import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import type { SidebarName } from '#desktop/components/layout/types.ts'
import { useSidebarDisplay } from '#desktop/components/layout/useSidebarDisplay.ts'

interface Props {
  name: SidebarName
  title: string
  icon: string
  titleClass?: string
  iconClass?: string
  entity?: ObjectLike
  actions?: MenuItem[]
}

const props = withDefaults(defineProps<Props>(), {
  titleClass: '',
  iconClass: 'text-stone-200 dark:text-neutral-500',
})

const { isSidebarCollapsed, toggleSidebar } = useSidebarDisplay(props.name)

const { isTouchDevice } = useTouchDevice()

const translatedTitle = computed(() => i18n.t(props.title))
</script>

<template>
  <div class="flex h-full justify-end">
    <div v-show="!isSidebarCollapsed" class="flex grow flex-col overflow-hidden">
      <div class="flex w-full gap-2 p-3">
        <CommonLabel
          tag="h2"
          class="min-h-7 grow gap-1.5"
          :class="titleClass"
          size="large"
          :prefix-icon="icon"
          :icon-color="iconClass"
        >
          {{ translatedTitle }}
        </CommonLabel>

        <CommonActionMenu
          v-if="actions?.length"
          class="text-gray-100 dark:text-neutral-400"
          no-single-action-mode
          placement="arrowEnd"
          :entity="entity"
          :actions="actions"
        />
      </div>

      <div class="flex h-full flex-col gap-3 overflow-y-auto">
        <slot />
      </div>
    </div>

    <div
      class="flex flex-col items-center gap-2.5 border-neutral-100 px-2.5 py-3 transition-[border] dark:border-gray-900"
      :class="{ 'border-s': !isSidebarCollapsed }"
    >
      <CommonButton
        v-tooltip="translatedTitle"
        class="text-black! outline-1! outline-offset-1 outline-blue-800! dark:text-white!"
        size="large"
        variant="neutral"
        :icon="icon"
        :aria-label="translatedTitle"
        @click="toggleSidebar(false)"
      />

      <CollapseButton
        class="mt-auto"
        :class="{ 'lg:hidden': !isTouchDevice }"
        owner-id="content-sidebar"
        visible
        no-padded
        size="large"
        variant="tertiary-gray"
        inverse
        :collapsed="isSidebarCollapsed"
        :collapse-label="$t('Collapse sidebar')"
        :expand-label="$t('Expand sidebar')"
        @toggle-collapse="toggleSidebar"
      />
    </div>
  </div>
</template>
