// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { camelCase } from 'lodash-es'
import { computed } from 'vue'

import { useReducedMotion } from '#shared/composables/useReducedMotion.ts'

// Maps transition names to their corresponding CSS class names.
//   The keys in strict PascalCase format are currently unused in the codebase.
//   However, they are enforced by our linting rules and are kept for future usage.
export enum TransitionName {
  Collapse = 'collapse',
  CollapseHeight = 'collapse-height',
  Fade = 'fade',
  FadeAbsolute = 'fade-absolute',
  FadeDown = 'fade-down',
  FadeMove = 'fade-move',
  FadeQuick = 'fade-quick',
  FadeUp = 'fade-up',
  Slide = 'slide',
  SlideDown = 'slide-down',
}

export const useTransitionConfig = () => {
  const { hasReducedMotion } = useReducedMotion()

  // Returns requested transition name or undefined if reduced motion is preferred.
  //   For usage of the transition, make sure to use the key in camelCase format:
  //   <Transition :name="transitions.fadeUp" />
  const transitions = computed(() =>
    Object.fromEntries(
      Object.entries(TransitionName).map(([key, name]) => [
        camelCase(key),
        hasReducedMotion.value ? undefined : name,
      ]),
    ),
  )

  return { transitions }
}
