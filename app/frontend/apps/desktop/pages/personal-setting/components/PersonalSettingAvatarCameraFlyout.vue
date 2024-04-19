<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useUserMedia, usePermission } from '@vueuse/core'

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
  context.drawImage(video, 0, 0, canvasHeight, canvasWidth)

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
    <div class="flex flex-col items-center gap-6">
      <CommonIcon
        v-if="!image"
        :name="cameraIcon"
        size="xl"
        class="fixed top-32"
      />

      <canvas
        v-show="cameraIsDisabled || image"
        class="h-64 min-h-64 w-64 min-w-64 rounded-full border-[1px] border-black dark:border-white"
      >
      </canvas>

      <CommonAlert v-if="cameraIsDisabled" variant="danger">
        {{
          $t('Accessing your camera is forbidden. Please check your settings.')
        }}
      </CommonAlert>

      <video
        v-show="!cameraIsDisabled && !image"
        :aria-label="$t('Use the camera to take a photo for the avatar.')"
        :srcObject="stream"
        autoplay
        class="h-64 min-h-64 w-64 min-w-64 rounded-full border-[1px] border-black dark:border-white"
      />

      <div v-if="!cameraIsDisabled" class="flex flex-row gap-2">
        <CommonButton
          :disabled="!!image"
          variant="primary"
          size="medium"
          @click="captureImage"
          >{{ $t('Capture From Camera') }}</CommonButton
        >
        <CommonButton
          :disabled="!image"
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
