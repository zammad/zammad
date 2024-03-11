<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'
import { getAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'
import type { AlertVariant } from './types.ts'

export interface Props {
  variant?: AlertVariant
  dismissible?: boolean
  link?: string | null
  linkText?: string | null
  id?: string
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'info',
  dismissible: false,
})

const icon = computed(() => {
  switch (props.variant) {
    case 'success':
      return 'common-alert-success'
    case 'warning':
      return 'common-alert-warning'
    case 'danger':
      return 'common-alert-danger'
    case 'info':
    default:
      return 'common-alert-info'
  }
})

const classMap = getAlertClasses()

const dismissed = ref(false)
</script>

<template>
  <div
    v-if="!dismissed"
    :id="props.id"
    class="-:rounded-lg gap-1.5 p-2 border-transparent"
    :class="[classMap.base, classMap[props.variant]]"
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
        class="ltr:mr-2 rtl:ml-2 text-ellipsis"
        :class="classMap.link"
        :link="props.link"
        open-in-new-tab
        rel="noopener noreferrer"
        >{{ props.linkText || props.link }}</CommonLink
      >

      <CommonIcon
        v-if="props.dismissible"
        size="small"
        decorative
        name="common-alert-dismiss"
        class="ltr:mr-2 rtl:ml-2 cursor-pointer"
        @click="dismissed = true"
      />
    </div>
  </div>
</template>
