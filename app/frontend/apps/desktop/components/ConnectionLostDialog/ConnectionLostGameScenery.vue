<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { GAME_WIDTH } from './useConnectionLostGame.ts'

const props = defineProps<{
  distance: number
}>()

// Positions repeat every GAME_WIDTH, so the layer is drawn twice side by side.
const ENVELOPES = [
  { x: 70, y: 150, size: 12 },
  { x: 130, y: 28, size: 16 },
  { x: 260, y: 96, size: 10 },
  { x: 345, y: 160, size: 14 },
  { x: 430, y: 58, size: 12 },
  { x: 520, y: 18, size: 14 },
]

const PARALLAX = 0.2

const offset = computed(() => (props.distance * PARALLAX) % GAME_WIDTH)
</script>

<template>
  <g class="text-neutral-400 dark:text-gray-200" :transform="`translate(${-offset})`">
    <template v-for="repeat in [0, GAME_WIDTH]" :key="repeat">
      <g
        v-for="envelope in ENVELOPES"
        :key="envelope.x"
        :transform="`translate(${envelope.x + repeat} ${envelope.y})`"
      >
        <CommonIcon
          name="envelope"
          :fixed-size="{ width: envelope.size, height: envelope.size }"
          decorative
        />
      </g>
    </template>
  </g>
</template>
