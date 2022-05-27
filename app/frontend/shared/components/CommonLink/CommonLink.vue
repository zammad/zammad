<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { useLink } from 'vue-router'
import stopEvent from '@shared/utils/events'
import type { Link } from '@shared/types/router'

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
  if (props.isExternal) return false
  if (props.isRoute) return true
  // zammad desktop urls
  if (route.value.fullPath.startsWith('/#')) return false
  return route.value.matched.length > 0 && route.value.name !== 'Error'
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
    :href="isInternalLink ? href : (link as string)"
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
