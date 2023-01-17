<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import VueEasyLightbox from 'vue-easy-lightbox'
import 'vue-easy-lightbox/dist/external-css/vue-easy-lightbox.css'
import { imageViewerOptions } from '@shared/composables/useImageViewer'
</script>

<template>
  <VueEasyLightbox
    data-test-id="imageViewer"
    :imgs="imageViewerOptions.images"
    :index="imageViewerOptions.index"
    :visible="imageViewerOptions.visible"
    @hide="imageViewerOptions.visible = false"
  />
</template>
