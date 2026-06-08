<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
</script>

<template>
  <article class="space-y-3">
    <CommonSkeleton :label="$t('Placeholder for AI generated heading')" class="h-6 w-1/3" />

    <CommonSkeleton :label="$t('Placeholder for AI generated text')" class="h-5 w-full" />
    <CommonSkeleton :label="$t('Placeholder for AI generated text')" class="h-5 w-full" />
    <CommonSkeleton :label="$t('Placeholder for AI generated text')" class="h-5 w-full" />
    <CommonSkeleton :label="$t('Placeholder for AI generated text')" class="h-5 w-1/2" />
  </article>
</template>
