<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <main class="grid min-h-screen flex-1 overflow-hidden">
    <transition class="z-10 flex-auto" v-bind:name="viewTransition">
      <slot></slot>
    </transition>
  </main>
</template>

<script setup lang="ts">
import useViewTransition from '@mobile/composables/useViewTransition'

const { viewTransition } = useViewTransition()
</script>

<!-- # TODO: does not work with vitest currently.

tests/apps/mobile/components/transition/TransitionViewNavigation.spec.ts [ tests/apps/mobile/components/transition/TransitionViewNavigation.spec.ts ]
TypeError: Cannot read property 'config' of undefined
 ❯ getTailwindConfig ../../node_modules/tailwindcss/lib/lib/setupTrackingContext.js:81:62
 ❯ ../../node_modules/tailwindcss/lib/lib/setupTrackingContext.js:124:92
 ❯ ../../node_modules/tailwindcss/lib/processTailwindFeatures.js:43:11
 ❯ plugins ../../node_modules/tailwindcss/lib/index.js:20:104
 ❯ LazyResult.runOnRoot ../../node_modules/postcss/lib/lazy-result.js:339:16
 ❯ LazyResult.runAsync ../../node_modules/postcss/lib/lazy-result.js:393:26
 ❯ LazyResult.async ../../node_modules/postcss/lib/lazy-result.js:221:30
 ❯ LazyResult.then ../../node_modules/postcss/lib/lazy-result.js:206:17

<style scoped>
/* TODO: Styles needs to be aligned/beautified. */

/* Example from: https://codesandbox.io/s/zq5mw2zk9x */
main {
  grid-template: 'main';
}

main > * {
  grid-area: main; /* Transition: make sections overlap on same cell */
}

/* next */

.next-leave-to {
  animation: leaveToLeft 300ms both cubic-bezier(0.19, 0.61, 0.44, 1);
  z-index: 0;
}

.next-enter-to {
  animation: enterFromRight 400ms both cubic-bezier(0.19, 0.61, 0.44, 1);
  z-index: 1;
}

@keyframes leaveToLeft {
  from {
    transform: translateX(0);
  }

  to {
    transform: translateX(-25%);
    filter: brightness(0.4);
  }
}

@keyframes enterFromRight {
  from {
    transform: translateX(100%);
  }

  to {
    transform: translateX(0);
  }
}

/* prev */

.prev-leave-to {
  animation: leaveToRight 400ms both cubic-bezier(0.19, 0.61, 0.44, 1);
  z-index: 1;
}

.prev-enter-to {
  animation: enterFromLeft 300ms both cubic-bezier(0.19, 0.61, 0.44, 1);
  z-index: 0;
}

@keyframes enterFromLeft {
  from {
    transform: translateX(-25%);
    filter: brightness(0.5);
  }

  to {
    transform: translateX(0);
  }
}

@keyframes leaveToRight {
  from {
    transform: translateX(0);
    filter: brightness(0.9);
  }

  to {
    transform: translateX(100%);
    filter: brightness(0.8);
  }
}
</style>

-->
