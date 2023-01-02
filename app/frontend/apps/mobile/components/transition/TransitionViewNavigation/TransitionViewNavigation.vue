<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useViewTransition } from './composable'

const { viewTransition } = useViewTransition()
</script>

<template>
  <main class="grid flex-1 overflow-hidden">
    <Transition class="z-10 flex-auto" :name="viewTransition">
      <slot></slot>
    </Transition>
  </main>
</template>

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
