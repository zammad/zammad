<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useUserMedia, usePermission } from '@vueuse/core'
import { computed, ref, watch } from 'vue'

import type { ImageFileData } from '#shared/utils/files.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'

defineEmits<{
  avatarCaptured: [void]
}>()

const image = ref<ImageFileData>()

const canvasHeight = 256
const canvasWidth = 256

const cameraAccess = usePermission('camera')
const cameraIsDisabled = computed(
  () => !cameraAccess.value || cameraAccess.value === 'denied',
)

const cameraIcon = computed(() =>
  cameraIsDisabled.value ? 'camera-video-off' : 'camera-video',
)

const { stream, start, stop } = useUserMedia({
  constraints: {
    video: {
      width: 256,
      height: 256,
    },
  },
})

if (!cameraIsDisabled.value) start()

const getCanvasObject = () => {
  const canvas = document.querySelector('canvas')
  if (!canvas) return

  return canvas
}

const getCanvas2dContext = (canvas: HTMLCanvasElement) => {
  if (!canvas) return

  const context = canvas.getContext('2d')
  if (!context) return

  return context
}

const discardImage = () => {
  if (image.value) {
    image.value = undefined
  }

  const canvas = getCanvasObject()
  if (!canvas) return

  getCanvas2dContext(canvas)?.clearRect(0, 0, canvas.width, canvas.height)
}

watch(cameraIsDisabled, (isDisabled) => {
  if (isDisabled) {
    discardImage()
    stop()

    return
  }

  start()
})

const captureImage = () => {
  if (!stream.value) return

  const canvas = getCanvasObject()
  if (!canvas) return

  const context = getCanvas2dContext(canvas)
  if (!context) return

  canvas.width = canvasWidth
  canvas.height = canvasHeight

  const video = document.querySelector('video')

  if (!video) return

  context.translate(canvasWidth, 0)
  context.scale(-1, 1)
  context.drawImage(
    video,
    (video.videoWidth - video.videoHeight) / 2,
    0,
    video.videoHeight,
    video.videoHeight,
    0,
    0,
    canvasWidth,
    canvasHeight,
  )

  image.value = {
    content: canvas.toDataURL('image/png'),
    name: 'avatar.png',
    type: 'image/png',
  }
}
</script>

<template>
  <CommonFlyout
    :header-title="__('Camera')"
    :footer-action-options="{
      actionLabel: __('Save'),
      actionButton: { variant: 'submit', disabled: !image },
    }"
    header-icon="camera"
    name="avatar-camera-capture"
    @action="$emit('avatarCaptured', image)"
    @close="stop"
  >
    <div class="flex flex-col items-center gap-6 pb-10 pt-12">
      <canvas
        v-show="image"
        class="h-64 min-h-64 w-64 min-w-64 rounded-full border border-black dark:border-white"
      >
      </canvas>

      <div
        v-if="!image"
        class="relative h-64 min-h-64 w-64 min-w-64 overflow-hidden rounded-full border border-black bg-blue-200 text-stone-200 dark:border-white dark:bg-gray-700 dark:text-neutral-500"
      >
        <CommonIcon
          :name="cameraIcon"
          size="xl"
          class="absolute top-1/2 -translate-y-1/2 ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
        />
        <!-- eslint-disable vuejs-accessibility/media-has-caption -->
        <video
          v-show="!cameraIsDisabled"
          class="h-full w-full object-cover"
          :aria-label="$t('Use the camera to take a photo for the avatar.')"
          :srcObject="stream"
          autoplay
        />
      </div>

      <CommonAlert v-if="cameraIsDisabled" variant="danger">
        {{
          $t('Accessing your camera is forbidden. Please check your settings.')
        }}
      </CommonAlert>

      <div v-else class="flex flex-row gap-2">
        <CommonButton
          v-if="!image"
          variant="primary"
          size="medium"
          @click="captureImage"
        >
          {{ $t('Capture From Camera') }}
        </CommonButton>
        <CommonButton
          v-else
          variant="remove"
          size="medium"
          @click="discardImage"
        >
          {{ $t('Discard Snapshot') }}
        </CommonButton>
      </div>
    </div>
  </CommonFlyout>
</template>

<style scoped>
video {
  transform: rotateY(180deg);
}
</style>
