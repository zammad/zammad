<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { Obstacle } from './useConnectionLostGame.ts'

const props = defineProps<{
  obstacle: Obstacle
}>()

const PILE_WIDTH = 22
const PILE_GAP = 2
const SHEET_HEIGHT = 3.5
const SHEET_JITTER = [0, 1.5, -1, 0.5, -1.5, 1, -0.5]
const TALL_PILE_HEIGHT = 40

const piles = computed(() => {
  const pileCount = Math.round(props.obstacle.width / PILE_WIDTH)
  const sheetCount = Math.round(props.obstacle.height / SHEET_HEIGHT)

  return Array.from({ length: pileCount }, (_, pile) => {
    const x = pile * (PILE_WIDTH + PILE_GAP)

    return {
      x,
      sheets: Array.from({ length: sheetCount }, (_, sheet) => ({
        x: x + 1 + SHEET_JITTER[(sheet + pile * 3) % SHEET_JITTER.length],
        y: props.obstacle.height - (sheet + 1) * SHEET_HEIGHT,
      })),
      hasStickyNote: props.obstacle.height >= TALL_PILE_HEIGHT && pile === 0,
    }
  })
})
</script>

<template>
  <g
    :transform="`translate(${obstacle.x} ${obstacle.y})`"
    data-test-id="connection-lost-game-obstacle"
  >
    <g v-for="pile in piles" :key="pile.x">
      <rect
        v-for="(sheet, index) in pile.sheets"
        :key="index"
        class="fill-stone-400 stroke-white dark:fill-neutral-300 dark:stroke-stone-400"
        :x="sheet.x"
        :y="sheet.y"
        :width="PILE_WIDTH - 2"
        :height="SHEET_HEIGHT"
        stroke-width="0.75"
      />
      <rect
        v-if="pile.hasStickyNote"
        class="fill-yellow-300"
        :x="pile.x + 11"
        y="-3"
        width="8"
        height="7"
        :transform="`rotate(12 ${pile.x + 15} 0.5)`"
      />
    </g>
  </g>
</template>
