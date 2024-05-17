<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import { Cropper, type CropperResult } from 'vue-advanced-cropper'
import 'vue-advanced-cropper/dist/style.css'

import CommonAvatar from '#shared/components/CommonAvatar/CommonAvatar.vue'
import type { ImageFileData } from '#shared/utils/files.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'

interface Props {
  image?: ImageFileData
}

const props = defineProps<Props>()

defineEmits<{
  imageCropped: [void]
}>()

const croppedImage = ref<ImageFileData>()

const imageCropped = (crop: CropperResult) => {
  if (!crop.canvas) return

  croppedImage.value = {
    content: crop.canvas.toDataURL('image/png'),
    name: 'avatar.png',
    type: 'image/png',
  }
}

const discardImage = () => {
  croppedImage.value = undefined
}
</script>

<template>
  <CommonFlyout
    :header-title="__('Crop Image')"
    :footer-action-options="{
      actionLabel: __('Save'),
      actionButton: { variant: 'submit' },
    }"
    header-icon="image"
    name="avatar-file-upload"
    @action="$emit('imageCropped', croppedImage)"
    @close="discardImage"
  >
    <div class="flex flex-col gap-3">
      <div v-if="croppedImage" class="flex flex-row items-center gap-1">
        <CommonAvatar :image="croppedImage.content" size="normal" />
        <CommonLabel>{{ $t('Avatar Preview') }}</CommonLabel>
      </div>

      <Cropper
        :src="props.image?.content"
        :stencil-props="{
          aspectRatio: 1,
          class: 'cropper-stencil',
          previewClass: 'cropper-stencil__preview',
          draggingClass: 'cropper-stencil--dragging',
          handlersClasses: {
            default: 'cropper-handler',
            eastNorth: 'cropper-handler--east-north',
            westNorth: 'cropper-handler--west-north',
            eastSouth: 'cropper-handler--east-south',
            westSouth: 'cropper-handler--west-south',
          },
        }"
        :transitions="false"
        class="cropper !max-h-[340px] !max-w-[476px]"
        background-class="cropper-background"
        image-class="cropper__image"
        @change="imageCropped"
      />
    </div>
  </CommonFlyout>
</template>

<style scoped>
:deep(.cropper-background) {
  background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAAAA3NCSVQICAjb4U/gAAAABlBMVEXMzMz////TjRV2AAAACXBIWXMAAArrAAAK6wGCiw1aAAAAHHRFWHRTb2Z0d2FyZQBBZG9iZSBGaXJld29ya3MgQ1M26LyyjAAAABFJREFUCJlj+M/AgBVhF/0PAH6/D/HkDxOGAAAAAElFTkSuQmCC');
}

:deep(.cropper) {
  &__image {
    opacity: 1;
  }
}

:deep(.cropper-stencil) {
  &__preview {
    &::after,
    &::before {
      content: '';
      opacity: 0;
      transition: opacity 0.25s;
      position: absolute;
      pointer-events: none;
      z-index: 1;
    }

    &::after {
      border-left: solid 1px white;
      border-right: solid 1px white;
      width: 33%;
      height: 100%;
      transform: translateX(-50%);
      left: 50%;
      top: 0;
    }

    &::before {
      border-top: solid 1px white;
      border-bottom: solid 1px white;
      height: 33%;
      width: 100%;
      transform: translateY(-50%);
      top: 50%;
      left: 0;
    }
  }

  &--dragging {
    :deep(.cropper-stencil__preview) {
      &::after,
      &::before {
        opacity: 0.4;
      }
    }
  }
}

:deep(.cropper-line) {
  border-color: rgba(white, 0.8);
}

:deep(.cropper-handler) {
  display: block;
  opacity: 0.7;
  position: relative;
  flex-shrink: 0;
  transition: opacity 0.5s;
  border: none;
  background: white;
  top: auto;
  left: auto;
  height: 4px;
  width: 4px;

  &--west-north,
  &--east-south,
  &--west-south,
  &--east-north {
    display: block;
    height: 16px;
    width: 16px;
    background: none;
  }

  &--west-north {
    border-left: solid 2px white;
    border-top: solid 2px white;
    top: 7px;
    left: 7px;
  }

  &--east-south {
    border-right: solid 2px white;
    border-bottom: solid 2px white;
    top: -7px;
    left: -7px;
  }

  &--west-south {
    border-left: solid 2px white;
    border-bottom: solid 2px white;
    top: -7px;
    left: 7px;
  }

  &--east-north {
    border-right: solid 2px white;
    border-top: solid 2px white;
    top: 7px;
    left: -7px;
  }

  &--hover {
    opacity: 1;
  }
}
</style>
