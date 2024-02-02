<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'
</script>

<template>
  <LayoutPublicPage box-size="medium" :title="__('Automated Setup')">
    <div class="text-center">
      <CommonLabel>{{
        $t('This system is configured for automated setup.')
      }}</CommonLabel>
      <CommonLabel>{{ $t('Please use the provided URL.') }}</CommonLabel>
    </div>
  </LayoutPublicPage>
</template>
