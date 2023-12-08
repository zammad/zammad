<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

export interface Props {
  variant?: 'success' | 'info' | 'warning' | 'danger'
  dismissible?: boolean
  link?: string | null
  linkText?: string | null
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'info',
  dismissible: false,
})

const icon = computed(() => {
  switch (props.variant) {
    case 'success':
      return 'alert-success'
    case 'warning':
      return 'alert-warning'
    case 'danger':
      return 'alert-danger'
    case 'info':
    default:
      return 'alert-info'
  }
})

const classMap = {
  success: 'alert-success bg-green-900 text-green-500',
  info: 'alert-info bg-blue-950 text-blue-800',
  warning: 'alert-warning bg-yellow-900 text-yellow-600',
  danger: 'alert-error bg-red-900 text-red-500',
}

const dismissed = ref(false)
</script>

<template>
  <div
    v-if="!dismissed"
    class="alert rounded-lg gap-1.5 p-2 border-transparent"
    :class="classMap[props.variant]"
    role="alert"
    data-test-id="common-alert"
  >
    <CommonIcon size="small" decorative :name="icon" />

    <slot />

    <div
      v-if="props.link || props.dismissible"
      class="flex items-center justify-start ltr:ml-auto rtl:mr-auto"
    >
      <CommonLink
        v-if="props.link"
        class="ltr:mr-2 rtl:ml-2 font-extrabold underline text-ellipsis"
        :link="props.link"
        open-in-new-tab
        rel="noopener noreferrer"
        >{{ props.linkText || props.link }}</CommonLink
      >

      <CommonIcon
        v-if="props.dismissible"
        size="small"
        decorative
        name="alert-dismiss"
        class="ltr:mr-2 rtl:ml-2 cursor-pointer"
        @click="dismissed = true"
      />
    </div>
  </div>
</template>
