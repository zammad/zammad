<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div>
    <h1>{{ i18n.t('Ticket Overview') }}</h1>
    <p v-on:click="goTo">Go to link Home</p>
    <p v-on:click="goBack">Go Back</p>
  </div>
</template>

<script setup lang="ts">
import useViewTransition from '@mobile/composables/useViewTransition'
import { ViewTransitions } from '@mobile/types/transition'
import { useRouter } from 'vue-router'

const router = useRouter()

const goTo = () => {
  const { setViewTransition } = useViewTransition()
  setViewTransition(ViewTransitions.REPLACE)

  router.replace('/')
}

const goBack = () => {
  const { setViewTransition } = useViewTransition()
  setViewTransition(ViewTransitions.PREV)

  router.go(-1)
}
</script>
g
