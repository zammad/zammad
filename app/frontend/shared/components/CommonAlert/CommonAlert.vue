<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import { getAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'

import type { AlertVariant } from './types.ts'

export interface Props {
  variant?: AlertVariant
  dismissible?: boolean
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
    class="-:rounded-lg gap-1.5 border-transparent p-2"
    :class="[classMap.base, classMap[props.variant]]"
    role="alert"
    data-test-id="common-alert"
  >
    <CommonIcon
      class="mx-auto mt-0.5 md:mx-0"
      :name="icon"
      size="tiny"
      decorative
    />

    <slot />

    <div v-if="props.dismissible">
      <CommonIcon
        v-if="props.dismissible"
        size="tiny"
        decorative
        name="common-alert-dismiss"
        class="mx-auto cursor-pointer md:mx-0"
        @click="dismissed = true"
      />
    </div>
  </div>
</template>
