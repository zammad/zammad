<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onKeyStroke, useEventListener, useRafFn } from '@vueuse/core'
import { computed, ref, watch } from 'vue'

import ConnectionLostGamePaperStack from './ConnectionLostGamePaperStack.vue'
import ConnectionLostGameScenery from './ConnectionLostGameScenery.vue'
import {
  BIRD_HEIGHT,
  BIRD_MAX_VELOCITY,
  BIRD_WIDTH,
  BIRD_X,
  GAME_HEIGHT,
  GAME_WIDTH,
  type SteeringDirection,
  useConnectionLostGame,
} from './useConnectionLostGame.ts'

// Keeps the bird from twitching around a pointer resting right next to it.
const POINTER_DEAD_ZONE = 4

const { status, score, highScore, distance, bird, obstacles, steer, step } = useConnectionLostGame()

// Caps the step after the tab was in the background, so nothing tunnels through an obstacle.
useRafFn(({ delta }) => step(Math.min(delta, 50) / 1000))

const pressedKeys = ref({ ArrowUp: false, ArrowDown: false })
const pointerY = ref<number | null>(null)

onKeyStroke(['ArrowUp', 'ArrowDown'], (event) => {
  event.preventDefault()
  pressedKeys.value[event.key as keyof typeof pressedKeys.value] = true
})

onKeyStroke(
  ['ArrowUp', 'ArrowDown'],
  (event) => {
    pressedKeys.value[event.key as keyof typeof pressedKeys.value] = false
  },
  { eventName: 'keyup' },
)

// A key released while the window had no focus never fires a keyup.
useEventListener(window, 'blur', () => {
  pressedKeys.value.ArrowUp = false
  pressedKeys.value.ArrowDown = false
})

const pointerDirection = (y: number): SteeringDirection => {
  const distanceToBird = y - (bird.value.y + BIRD_HEIGHT / 2)

  if (Math.abs(distanceToBird) < POINTER_DEAD_ZONE) return 0

  return distanceToBird < 0 ? -1 : 1
}

const direction = computed<SteeringDirection>(() => {
  if (pointerY.value !== null) return pointerDirection(pointerY.value)

  return (Number(pressedKeys.value.ArrowDown) -
    Number(pressedKeys.value.ArrowUp)) as SteeringDirection
})

watch(direction, steer)

const trackPointer = (event: PointerEvent) => {
  const { top, height } = (event.currentTarget as SVGSVGElement).getBoundingClientRect()

  pointerY.value = ((event.clientY - top) / height) * GAME_HEIGHT
}

const startPointer = (event: PointerEvent) => {
  ;(event.currentTarget as SVGSVGElement).setPointerCapture(event.pointerId)
  trackPointer(event)
}

const movePointer = (event: PointerEvent) => {
  if (pointerY.value === null) return

  trackPointer(event)
}

const releasePointer = () => {
  pointerY.value = null
}

const birdTilt = computed(() => (bird.value.velocity / BIRD_MAX_VELOCITY) * 15)

const statusMessage = computed(() => {
  if (status.value === 'idle') return __('Press the up or down arrow key to start.')
  if (status.value === 'over') return __('Game over! Press the up or down arrow key to try again.')

  return ''
})
</script>

<template>
  <div class="mx-auto flex w-150 max-w-full flex-col gap-1">
    <div class="flex justify-end gap-3">
      <CommonLabel v-if="highScore" class="text-stone-200 tabular-nums" size="small">
        {{ $t('High score: %s', highScore) }}
      </CommonLabel>
      <CommonLabel class="tabular-nums" size="small">
        {{ $t('Score: %s', score) }}
      </CommonLabel>
    </div>

    <div class="relative overflow-hidden rounded-lg">
      <svg
        class="block h-auto w-full cursor-pointer touch-none bg-blue-200 select-none dark:bg-gray-700"
        :viewBox="`0 0 ${GAME_WIDTH} ${GAME_HEIGHT}`"
        aria-hidden="true"
        data-test-id="connection-lost-game"
        @pointerdown.prevent="startPointer"
        @pointermove="movePointer"
        @pointerup="releasePointer"
        @pointercancel="releasePointer"
      >
        <ConnectionLostGameScenery :distance="distance" />
        <ConnectionLostGamePaperStack
          v-for="obstacle in obstacles"
          :key="obstacle.id"
          :obstacle="obstacle"
        />

        <g
          :transform="`translate(${BIRD_X} ${bird.y}) rotate(${birdTilt} ${BIRD_WIDTH / 2} ${BIRD_HEIGHT / 2})`"
          data-test-id="connection-lost-game-bird"
        >
          <CommonIcon
            name="logo"
            :fixed-size="{ width: BIRD_WIDTH, height: BIRD_HEIGHT }"
            decorative
          />
        </g>
      </svg>

      <div
        class="pointer-events-none absolute inset-0 flex items-center justify-center"
        role="status"
      >
        <CommonLabel
          v-if="statusMessage"
          class="rounded-md bg-neutral-50/80 px-2 py-1 dark:bg-gray-500/80"
          size="medium"
        >
          {{ $t(statusMessage) }}
        </CommonLabel>
      </div>
    </div>
  </div>
</template>
