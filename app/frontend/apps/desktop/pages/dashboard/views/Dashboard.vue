<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useSessionStore } from '#shared/stores/session.ts'
import LayoutMain from '#desktop/components/layout/LayoutMain.vue'

const session = useSessionStore()
</script>

<template>
  <LayoutMain>
    Hello, {{ session.user?.fullname }}!
    <!-- TODO: content -->
    <div class="h-20 bg-test">TEST</div>
  </LayoutMain>
</template>
