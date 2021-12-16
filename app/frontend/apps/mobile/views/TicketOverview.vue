<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div>
    <h1>{{ i18n.t('Ticket Overview') }}</h1>
    <p v-on:click="goTo">Go to link Home</p>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()

const goTo = () => {
  router.push('/')
}
</script>
