<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <router-link
    v-if="isInternalLink"
    v-bind:to="link"
    v-bind:replace="replace"
    v-bind:class="linkClass"
    v-bind:active-class="activeClass"
    v-bind:exact-active-class="exactActiveClass"
    v-bind:target="target"
    data-test-id="common-link"
    v-on:click="onClick"
  >
    <slot></slot>
  </router-link>
  <a
    v-else
    v-bind:href="(link as string)"
    v-bind:target="target"
    v-bind:rel="rel"
    v-bind:class="linkClass"
    data-test-id="common-link"
    v-on:click="onClick"
  >
    <slot></slot>
  </a>
</template>

<script setup lang="ts">
import type { Link } from '@common/types/router'
import isRouteLink from '@common/router/utils/isRouteLink'
import { computed } from 'vue'
import stopEvent from '@common/utils/events'

export interface Props {
  link: Link
  isExternal?: boolean
  isRoute?: boolean
  disabled?: boolean
  rel?: string
  target?: string
  openInNewTab?: boolean
  replace?: boolean
  activeClass?: string
  exactActiveClass?: string
}

const props = withDefaults(defineProps<Props>(), {
  isExternal: false,
  isRoute: false,
  replace: false,
  append: false,
  openInNewTab: false,
  disabled: false,
})

const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void
}>()

const isInternalLink = computed(() => {
  if (props.isExternal) return false
  if (props.isRoute) return true

  return isRouteLink(props.link)
})

const target = computed(() => {
  if (props.target) return props.target
  if (props.openInNewTab) return '_blank'
  return null
})

// TODO: Correct styling is currently missing.
const linkClass = computed(() => {
  let classes = 'text-blue hover:underline'

  if (props.disabled) {
    classes += ' pointer-events-none text-gray-300/75'
  }

  return classes
})

const onClick = (event: MouseEvent) => {
  if (props.disabled) {
    stopEvent(event, { immediatePropagation: true })
    return
  }
  emit('click', event)

  // Stop the scroll-to-top behavior or navigation on regular links when href is just '#'.
  if (!isInternalLink.value && props.link === '#') {
    stopEvent(event, { propagation: false })
  }
}
</script>
