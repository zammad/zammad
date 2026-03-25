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
      :aria-label="
        isEraserActive ? $t('Remove highlight') : $t('Highlighter color: %s', $t(activeColorLabel))
      "
      :addon-label="$t('Highlight options')"
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
    url("data:image/svg+xml,%3Csvg width='24' height='19' viewBox='0 0 24 19' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M17.5562 2.01065L21.0923 5.54581L21.7437 6.19815L21.147 6.9003L13.1919 16.2694L12.4897 17.0966L11.7231 16.329L11.2671 15.873L10.355 16.2821L9.77881 16.8603L9.48584 17.1523H2.41455L4.12158 15.4452L6.81982 12.746L7.22803 11.8349L6.77295 11.3798L6.00635 10.6122L6.8335 9.91007L16.2026 1.95499L16.9048 1.35929L17.5562 2.01065ZM10.4282 10.7919L12.3091 12.6737L17.6665 6.36319L16.7378 5.43448L10.4282 10.7919Z' fill='black' stroke='white' stroke-width='2'/%3E%3C/svg%3E")
      2 17,
    crosshair;
}

[data-theme='dark'] body.cursor-highlight {
  cursor:
    url("data:image/svg+xml,%3Csvg width='24' height='19' viewBox='0 0 24 19' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M17.5562 2.01065L21.0923 5.54581L21.7437 6.19815L21.147 6.9003L13.1919 16.2694L12.4897 17.0966L11.7231 16.329L11.2671 15.873L10.355 16.2821L9.77881 16.8603L9.48584 17.1523H2.41455L4.12158 15.4452L6.81982 12.746L7.22803 11.8349L6.77295 11.3798L6.00635 10.6122L6.8335 9.91007L16.2026 1.95499L16.9048 1.35929L17.5562 2.01065ZM10.4282 10.7919L12.3091 12.6737L17.6665 6.36319L16.7378 5.43448L10.4282 10.7919Z' fill='white' stroke='black' stroke-width='2'/%3E%3C/svg%3E")
      2 17,
    crosshair;
}

body.cursor-eraser {
  cursor:
    url("data:image/svg+xml,%3Csvg width='19' height='18' viewBox='0 0 19 18' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M8.75781 1.87891C9.9294 0.707446 11.8285 0.707372 13 1.87891L16.8789 5.75781C18.0501 6.92937 18.0503 8.82853 16.8789 10L11.3789 15.5C10.8164 16.0625 10.0533 16.3788 9.25781 16.3789H6.5C5.7044 16.3789 4.9415 16.0625 4.37891 15.5L1.87891 13C0.70737 11.8285 0.707449 9.92939 1.87891 8.75781L8.75781 1.87891ZM4 10.8789L6.5 13.3789H8.16406L4.83203 10.0469L4 10.8789Z' fill='black' stroke='white' stroke-width='2' stroke-linejoin='round'/%3E%3C/svg%3E")
      1 17,
    auto;
}

[data-theme='dark'] body.cursor-eraser {
  cursor:
    url("data:image/svg+xml,%3Csvg width='19' height='18' viewBox='0 0 19 18' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M8.75781 1.87891C9.9294 0.707446 11.8285 0.707372 13 1.87891L16.8789 5.75781C18.0501 6.92937 18.0503 8.82853 16.8789 10L11.3789 15.5C10.8164 16.0625 10.0533 16.3788 9.25781 16.3789H6.5C5.7044 16.3789 4.9415 16.0625 4.37891 15.5L1.87891 13C0.70737 11.8285 0.707449 9.92939 1.87891 8.75781L8.75781 1.87891ZM4 10.8789L6.5 13.3789H8.16406L4.83203 10.0469L4 10.8789Z' fill='white' stroke='black' stroke-width='2' stroke-linejoin='round'/%3E%3C/svg%3E")
      1 17,
    auto;
}
</style>
