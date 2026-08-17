<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { clamp } from 'lodash-es'
import { computed, ref, toRef, watch } from 'vue'
import VueEasyLightbox from 'vue-easy-lightbox'

import { imageViewerOptions } from '#shared/composables/useImageViewer.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import FloatingToolbar from './FloatingToolbar.vue'

import 'vue-easy-lightbox/dist/external-css/vue-easy-lightbox.css'

// The lightbox tracks the shown image internally and the `index` prop is only its
//   initial value, so mirror the navigation to know when an end is reached.
const currentIndex = ref(imageViewerOptions.value.index)

// Showing an image always replaces the options, which also covers reopening the
//   viewer on the same image after navigating away from it.
watch(imageViewerOptions, ({ visible, index, images }) => {
  if (!visible) return

  currentIndex.value = clamp(index, 0, Math.max(images.length - 1, 0))
})

const updateCurrentIndex = (_oldIndex: number, newIndex: number) => {
  currentIndex.value = newIndex
}

const isFirstImage = computed(() => currentIndex.value <= 0)

const isLastImage = computed(() => currentIndex.value >= imageViewerOptions.value.images.length - 1)

const localeData = toRef(useLocaleStore(), 'localeData')

const isRtl = computed(() => localeData.value?.dir === 'rtl')
</script>

<template>
  <VueEasyLightbox
    data-test-id="imageViewer"
    :imgs="imageViewerOptions.images"
    :index="imageViewerOptions.index"
    :visible="imageViewerOptions.visible"
    :rtl="isRtl"
    @hide="imageViewerOptions.visible = false"
    @on-index-change="updateCurrentIndex"
  >
    <template #toolbar="{ toolbarMethods }">
      <FloatingToolbar
        @zoom-in="toolbarMethods.zoomIn"
        @zoom-out="toolbarMethods.zoomOut"
        @resize="toolbarMethods.resize"
        @rotate-left="toolbarMethods.rotateLeft"
        @rotate-right="toolbarMethods.rotateRight"
      />
    </template>

    <template #prev-btn="{ prev }">
      <CommonButton
        v-tooltip="$t('Previous image')"
        class="absolute inset-y-1/2 -translate-y-1/2 ltr:left-4 rtl:right-4"
        variant="tertiary"
        :icon="isRtl ? 'chevron-right' : 'chevron-left'"
        size="large"
        :disabled="isFirstImage"
        @click="prev"
      />
    </template>

    <template #next-btn="{ next }">
      <CommonButton
        v-tooltip="$t('Next image')"
        class="absolute inset-y-1/2 -translate-y-1/2 ltr:right-4 rtl:left-4"
        variant="tertiary"
        :icon="isRtl ? 'chevron-left' : 'chevron-right'"
        size="large"
        :disabled="isLastImage"
        @click="next"
      />
    </template>

    <template #close-btn="{ close }">
      <CommonButton
        v-tooltip="$t('Close image preview')"
        class="absolute top-4 ltr:right-4 rtl:left-4"
        variant="tertiary"
        size="medium"
        icon="x-lg"
        @click="close"
    /></template>
  </VueEasyLightbox>
</template>

<style>
/*
  The image viewer (vue-easy-lightbox) appends its own stylesheet to the document head at
  runtime, so its rules always come after ours. Overriding them needs `!important`.

  The shipped z-index of 9998 would cover the tooltips of its own controls, so keep the
  viewer above the app, but below the tooltip layer.
*/
.vel-modal {
  z-index: calc(var(--z-index-60) - 1) !important;
  background: var(--color-alpha-900) !important;
}
</style>
