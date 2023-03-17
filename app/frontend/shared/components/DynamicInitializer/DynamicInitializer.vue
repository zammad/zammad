<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEventListener } from '@vueuse/core'
import type { TransitionProps } from 'vue'
import { markRaw, shallowRef } from 'vue'
import { Events } from './manage'
import type { DestroyComponentData, PushComponentData } from './types'

const props = defineProps<{
  /**
   * Name of a group of components that will be pushed to with unique ID.
   */
  name: string
  /**
   * Transition, if any.
   */
  transition?: TransitionProps
}>()

const components = shallowRef<PushComponentData[]>([])

useEventListener(
  window,
  Events.Push,
  ({ detail }: CustomEvent<PushComponentData>) => {
    if (detail.name !== props.name) return

    components.value = [
      ...components.value,
      {
        ...detail,
        cmp: markRaw(detail.cmp),
      },
    ]
  },
)

useEventListener(
  window,
  Events.Destroy,
  ({ detail }: CustomEvent<DestroyComponentData>) => {
    if (detail.name !== props.name) return

    if (!detail.id) {
      components.value = []

      return
    }

    components.value = components.value.filter(
      (item) => !(item.name === detail.name && item.id === detail.id),
    )
  },
)
</script>

<template>
  <TransitionGroup v-if="transition" v-bind="transition">
    <Component
      :is="cmp"
      v-for="{ cmp, name: cmpName, id, props: cmpProps } in components"
      :key="`${cmpName + id}`"
      v-bind="cmpProps"
    />
  </TransitionGroup>

  <template v-else-if="!$slots.default">
    <Component
      :is="cmp"
      v-for="{ cmp, name: cmpName, id, props: cmpProps } in components"
      :key="`${cmpName + id}`"
      v-bind="cmpProps"
    />
  </template>

  <slot v-else :components="components" />
</template>
