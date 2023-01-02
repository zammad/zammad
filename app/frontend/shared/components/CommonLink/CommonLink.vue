<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { useLink } from 'vue-router'
import stopEvent from '@shared/utils/events'
import type { Link } from '@shared/types/router'
import { useApplicationStore } from '@shared/stores/application'

export interface Props {
  link: Link
  external?: boolean
  internal?: boolean
  restApi?: boolean
  disabled?: boolean
  rel?: string
  target?: string
  openInNewTab?: boolean
  replace?: boolean
  activeClass?: string
  exactActiveClass?: string
}

const props = withDefaults(defineProps<Props>(), {
  external: false,
  internal: false,
  replace: false,
  append: false,
  openInNewTab: false,
  disabled: false,
  activeClass: 'router-link-active',
  exactActiveClass: 'router-link-exact-active',
})

const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void
}>()

const target = computed(() => {
  if (props.target) return props.target
  if (props.openInNewTab) return '_blank'
  return null
})

// TODO: Correct styling is currently missing.
const linkClass = computed(() => {
  if (props.disabled) {
    return 'pointer-events-none'
  }

  return ''
})

const { href, route, navigate, isActive, isExactActive } = useLink({
  to: toRef(props, 'link'),
  replace: toRef(props, 'replace'),
})

const isInternalLink = computed(() => {
  if (props.external || props.restApi) return false
  if (props.internal) return true
  // zammad desktop urls
  if (route.value.fullPath.startsWith('/#')) return false
  return route.value.matched.length > 0 && route.value.name !== 'Error'
})

const app = useApplicationStore()

const path = computed(() => {
  if (isInternalLink.value) {
    return href.value
  }

  if (props.restApi) {
    return `${String(app.config.api_path)}${props.link}`
  }

  return props.link as string
})

const onClick = (event: MouseEvent) => {
  if (props.disabled) {
    stopEvent(event, { immediatePropagation: true })
    return
  }
  emit('click', event)

  if (isInternalLink.value) {
    navigate(event)
  }

  // Stop the scroll-to-top behavior or navigation on regular links when href is just '#'.
  if (!isInternalLink.value && props.link === '#') {
    stopEvent(event, { propagation: false })
  }
}
</script>

<template>
  <a
    data-test-id="common-link"
    :href="path"
    :target="target"
    :rel="rel"
    :class="[
      linkClass,
      {
        [activeClass]: isActive,
        [exactActiveClass]: isExactActive,
      },
    ]"
    @click="onClick"
  >
    <slot></slot>
  </a>
</template>
