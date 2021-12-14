<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div>
    <h1>{{ i18n.t('Error - %s', statusCode) }}</h1>
    <p>{{ message }}</p>
    <p v-if="route">
      {{ route }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { ErrorStatusCodes } from '@common/types/error'

interface Props {
  title?: string
  message?: string
  statusCode?: ErrorStatusCodes
  route?: string
}

withDefaults(defineProps<Props>(), {
  title: __('Not Found'),
  message: __("We're sorry, but this page doesn't exist."),
  statusCode: ErrorStatusCodes.NotFound,
})
</script>
