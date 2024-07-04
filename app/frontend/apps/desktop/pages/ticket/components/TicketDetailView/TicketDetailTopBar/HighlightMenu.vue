<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { onMounted, ref } from 'vue'

import CommonPopover from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import type { HightlightColor } from '#shared/composables/useColorPallet/types.ts'
import { useColorPallet } from '#shared/composables/useColorPallet/useColorPallet.ts'

import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { useThemeStore } from '#desktop/stores/theme.ts'

interface ExtendedMenuItem extends MenuItem, Omit<HightlightColor, 'label'> {}

const { highlightColors } = useColorPallet()

const items = highlightColors.map((color) => {
  return {
    key: `${color.label}`,
    ...color,
  }
})

const colorLabels = highlightColors.map((color) => color.label)

const color = defineModel<ExtendedMenuItem>('currentColor') // Remove if we might not need it to read it from parent

const isActive = ref(false)

const { popover, popoverTarget, toggle, close, isOpen } = usePopover()

const { isDarkMode } = storeToRefs(useThemeStore())

const selectColor = (event: ExtendedMenuItem) => {
  color.value = event
  close()
  isActive.value = true
}

const toggleHighlighterActive = () => {
  isActive.value = !isActive.value
}

onMounted(() => {
  color.value = items[0]
})
</script>

<template>
  <div>
    <div class="flex items-center gap-1">
      <button
        class="flex items-center gap-2 bg-[--highlight-color]"
        :style="{
          '--highlight-color': isDarkMode
            ? color?.value?.dark
            : color?.value?.light,
          background: !isActive ? 'transparent' : undefined,
        }"
        @click="toggleHighlighterActive"
      >
        <CommonIcon size="xs" name="highlighter" />
        <CommonLabel
          class="rounded-sm p-1 text-xs"
          :class="{ 'text-black dark:text-white': isActive }"
          :style="{ backgroundColor: isActive ? color?.value : undefined }"
          >{{ $t('Highlight') }}</CommonLabel
        >
      </button>
      <CommonIcon
        ref="popoverTarget"
        class="cursor-pointer text-gray-100 transition-transform dark:text-neutral-400"
        :class="{ 'rotate-180': isOpen }"
        role="button"
        size="xs"
        name="chevron-down"
        @click="toggle(true)"
      />
    </div>

    <CommonPopover ref="popover" placement="arrowEnd" :owner="popoverTarget">
      <CommonPopoverMenu
        class="overflow-clip"
        :items="items"
        :popover="popover"
      >
        <template
          v-for="(label, index) in colorLabels"
          #[`item-${label}`]="item"
          :key="label"
        >
          <button
            :aria-label="$t((item as ExtendedMenuItem).name)"
            class="relative flex grow items-center gap-2 p-2.5 text-gray-100 outline-none dark:text-neutral-400"
            :class="{
              'bg-blue-600 text-black dark:bg-blue-900 dark:text-white':
                (item as ExtendedMenuItem).id === color?.id,
              'rounded-t-lg': index === 0,
              'rounded-b-lg': index === colorLabels.length - 1,
              'pseudo-border-b': index !== colorLabels.length - 1,
            }"
            @click="selectColor(item as ExtendedMenuItem)"
          >
            <span
              class="inline-block h-4 w-4"
              :style="{
                backgroundColor: (item as ExtendedMenuItem).value.light,
              }"
            />
            <CommonLabel class="p-1 text-current">{{ $t(label) }}</CommonLabel>
            <Transition name="fade">
              <CommonIcon
                v-if="(item as ExtendedMenuItem).id === color?.id"
                class="rtl:-order-1"
                size="small"
                name="check2"
              />
            </Transition>
          </button>
        </template>
      </CommonPopoverMenu>
    </CommonPopover>
  </div>
</template>

<style scoped>
.pseudo-border-b::after {
  content: '';

  @apply absolute bottom-0 left-1/2 h-[1px] w-[calc(100%-1rem)] -translate-x-1/2 bg-neutral-100 dark:bg-gray-900;
}
</style>
