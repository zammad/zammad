<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onKeyStroke, useEventListener, whenever } from '@vueuse/core'
import { computed, onUnmounted, watch } from 'vue'

import CommonPopoverMenu from '#desktop/components/CommonPopoverMenu/CommonPopoverMenu.vue'
import SplitButton from '#desktop/components/SplitButton/SplitButton.vue'

import { useHighlightMenuState } from './useHighlightMenuState.ts'

const { activeMenuItem, isActive, isEraserActive, setActive, selectItem, items, reset } =
  useHighlightMenuState()

// To deactivate isActive whenever we are not within the article body
whenever(isActive, () => {
  const stopClickListener = useEventListener('click', (event) => {
    const evenTarget = event.target as HTMLElement
    // Only if any content of articles is clicked and not any of button
    if (evenTarget?.closest('article') && !evenTarget.closest('button')) return

    // Entire wrapper for the split button should not trigger deactivation
    if (evenTarget?.closest('[data-id="highlight-menu-wrapper"]')) return

    // Popovers which are on the body level
    if (evenTarget?.closest('[data-id="highlight-menu-popover"]')) return

    reset()
    stopClickListener()
  })

  const stopKeyStrokeListener = onKeyStroke('Escape', () => {
    reset()
    stopKeyStrokeListener()
  })
})

const highlightBackgroundClassMap: Record<string, string> = {
  'highlight-yellow': 'bg-yellow-200! dark:bg-yellow-750!',
  'highlight-green': 'bg-green-350! dark:bg-green-700!',
  'highlight-blue': 'bg-blue-550! dark:bg-blue-875!',
  'highlight-pink': 'bg-pink-150! dark:bg-pink-700!',
  'highlight-purple': 'bg-purple-100! dark:bg-purple-700!',
  'remove-highlight': 'bg-neutral-400! dark:bg-gray-700! text-black!',
}

const colorSwatchTextClassMap: Record<string, string> = {
  'highlight-yellow': 'text-yellow-150',
  'highlight-green': 'text-green-350',
  'highlight-blue': 'text-blue-550 dark:blue-500',
  'highlight-pink': 'text-pink-200',
  'highlight-purple': 'text-purple-250',
}

const colorSwatchBackgroundClassMap: Record<string, string> = {
  'highlight-yellow': 'bg-yellow-150',
  'highlight-green': 'bg-green-350',
  'highlight-blue': 'bg-blue-550 dark:blue-500',
  'highlight-pink': 'bg-pink-200',
  'highlight-purple': 'bg-purple-250',
}

const activeColorClass = computed(
  () => `${highlightBackgroundClassMap[activeMenuItem.value.key]} text-black! dark:text-white!`,
)

const activeColorSwatchClass = computed(() => colorSwatchTextClassMap[activeMenuItem.value.key])

const activeColorLabel = computed(() => activeMenuItem.value.label)

watch(
  [isActive, isEraserActive],
  ([active, eraser]) => {
    document.body.classList.toggle('cursor-highlight', active && !eraser)
    document.body.classList.toggle('cursor-eraser', active && !!eraser)
  },
  { immediate: true },
)

onUnmounted(() => {
  document.body.classList.remove('cursor-highlight', 'cursor-eraser')
})
</script>

<template>
  <div :data-id="`highlight-menu-wrapper`" class="flex">
    <SplitButton
      class="h-full!"
      :class="{ [activeColorClass]: isActive }"
      variant="tertiary-light"
      size="small"
      :tooltip="
        isEraserActive ? __('Remove highlight') : $t('Highlighter color: %s', $t(activeColorLabel))
      "
      :addon-label="__('Highlight options')"
      :aria-pressed="isActive"
      aria-describedby="highlight-menu-description"
      caret-pointer="down"
      orientation="autoVertical"
      placement="arrowEnd"
      @click="setActive()"
    >
      <CommonIcon
        :class="{ [activeColorSwatchClass]: !isActive }"
        decorative
        size="xs"
        :name="isEraserActive ? 'eraser-fill' : 'highlighter2'"
      />

      <template #popover-content="slotProps">
        <CommonPopoverMenu
          data-id="highlight-menu-popover"
          class="overflow-clip"
          :items="items"
          :popover="slotProps.popover"
        >
          <template v-for="(item, index) in items" #[`item-${item.key}`] :key="item.key">
            <button
              class="flex w-full grow items-center gap-2 p-2.5 text-gray-100 focus-visible-app-default -outline-offset-1! focus:outline-hidden dark:text-neutral-400"
              :class="{
                'bg-blue-800! text-white!': item.key === activeMenuItem?.key,
                'rounded-t-lg': index === 0,
                'rounded-b-lg': index === items.length - 1,
              }"
              :aria-pressed="item.key === activeMenuItem?.key"
              @click="
                () => {
                  selectItem(item)
                  setActive(true)
                  slotProps.close()
                }
              "
            >
              <CommonIcon v-if="item.icon" size="tiny" :name="item.icon" />
              <span
                v-else
                aria-hidden="true"
                class="size-4 rounded-sm"
                :class="colorSwatchBackgroundClassMap[item.key]"
              />

              <CommonLabel
                :class="{ 'text-current!': item.key === activeMenuItem?.key }"
                size="small"
                >{{ $t(item.label) }}</CommonLabel
              >
            </button>
          </template>
        </CommonPopoverMenu>
      </template>
    </SplitButton>

    <div id="highlight-menu-description" class="sr-only" aria-live="polite">
      <p>{{ $t('Selected highlight color: %s', $t(activeColorLabel)) }}</p>
      <p v-if="isActive">
        {{ $t('Highlighting is active. Select content in the ticket article to apply.') }}
      </p>
      <p v-else>{{ $t('Highlighting is inactive.') }}</p>
    </div>
  </div>
</template>

<style>
body.cursor-highlight {
  cursor:
    image-set(
        url('./assets/cursor/highlight-light.png') 1x,
        url('./assets/cursor/highlight-light@2x.png') 2x
      )
      2 15,
    crosshair;
}

[data-theme='dark'] body.cursor-highlight {
  cursor:
    image-set(
        url('./assets/cursor/highlight-dark.png') 1x,
        url('./assets/cursor/highlight-dark@2x.png') 2x
      )
      2 15,
    crosshair;
}

body.cursor-eraser {
  cursor:
    image-set(
        url('./assets/cursor/eraser-light.png') 1x,
        url('./assets/cursor/eraser-light@2x.png') 2x
      )
      2 15,
    auto;
}

[data-theme='dark'] body.cursor-eraser {
  cursor:
    image-set(
        url('./assets/cursor/eraser-dark.png') 1x,
        url('./assets/cursor/eraser-dark@2x.png') 2x
      )
      2 15,
    auto;
}
</style>
