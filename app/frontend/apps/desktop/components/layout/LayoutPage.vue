<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { RouterView } from 'vue-router'
</script>

<template>
  <!-- LayoutBreadcrumbs -->
  <div class="text-sm breadcrumbs">
    <ul>
      <li><a>Home</a></li>
      <li><a>Documents</a></li>
      <li>Add Document</li>
    </ul>
  </div>
  <!-- LayoutHeader -->

  <RouterView />
</template>
