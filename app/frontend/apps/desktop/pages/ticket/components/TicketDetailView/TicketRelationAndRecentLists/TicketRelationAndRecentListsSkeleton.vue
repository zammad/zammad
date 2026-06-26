<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
import CommonTableSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableSkeleton.vue'
</script>

<template>
  <div class="space-y-6">
    <section v-for="table in 2" :key="table">
      <CommonSkeleton class="mb-2 h-4 w-44" />
      <CommonTableSkeleton :columns="6" :rows="4" />
    </section>
  </div>
</template>
