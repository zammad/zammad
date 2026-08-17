<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFloatingToolbar from '#desktop/components/CommonFloatingToolbar/CommonFloatingToolbar.vue'

const emit = defineEmits<{
  'zoom-in': []
  'zoom-out': []
  resize: []
  'rotate-left': []
  'rotate-right': []
}>()

const buttonClass =
  'rounded-[(--toolbar-radius)-(--toolbar-p)]! border! border-neutral-100 text-gray-100 dark:border-gray-900 dark:text-neutral-400'
</script>

<template>
  <CommonFloatingToolbar
    class="absolute inset-x-1/2 bottom-4 ltr:-translate-x-1/2 rtl:translate-x-1/2"
    orientation="horizontal"
    :label="$t('Image actions')"
  >
    <CommonButton
      v-tooltip="$t('Zoom in')"
      variant="tertiary"
      icon="zoom-in"
      size="medium"
      :class="buttonClass"
      @click="emit('zoom-in')"
    />

    <CommonButton
      v-tooltip="$t('Zoom out')"
      variant="tertiary"
      icon="zoom-out"
      size="medium"
      :class="buttonClass"
      @click="emit('zoom-out')"
    />

    <CommonButton
      v-tooltip="$t('Fit to screen')"
      variant="tertiary"
      icon="arrows-fullscreen"
      size="medium"
      :class="buttonClass"
      @click="emit('resize')"
    />

    <CommonButton
      v-tooltip="$t('Rotate left')"
      variant="tertiary"
      icon="arrow-counterclockwise"
      size="medium"
      :class="buttonClass"
      @click="emit('rotate-left')"
    />

    <CommonButton
      v-tooltip="$t('Rotate right')"
      variant="tertiary"
      icon="arrow-clockwise"
      size="medium"
      :class="buttonClass"
      @click="emit('rotate-right')"
    />
  </CommonFloatingToolbar>
</template>
