<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useSessionStore } from '#shared/stores/session.ts'

const session = useSessionStore()
</script>

<template>
  Hello, {{ session.user?.fullname }}!

  <RouterLink to="/playground" class="link link-primary">Playground</RouterLink>
  <!-- TODO: content -->
  <div class="h-20 bg-test">TEST</div>
</template>
