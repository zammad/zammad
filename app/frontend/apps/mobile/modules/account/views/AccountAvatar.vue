<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { reactive, shallowRef } from 'vue'
import { storeToRefs } from 'pinia'
import { convertFileList, ImageFileData } from '@shared/utils/files'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import useSessionStore from '@shared/stores/session'
import { useHeader } from '@mobile/composables/useHeader'
import { Cropper, type CropperResult } from 'vue-advanced-cropper'
import 'vue-advanced-cropper/dist/style.css'
import CommonAvatar from '@shared/components/CommonAvatar/CommonAvatar.vue'

const fileCameraInput = shallowRef<HTMLInputElement>()
const fileGalleryInput = shallowRef<HTMLInputElement>()
const avatarImage = shallowRef<ImageFileData>()

const state = reactive({
  image: '',
  deleted: false,
})

useHeader({
  title: __('Avatar'),
  backUrl: '/account',
  backTitle: __('Account'),
  actionTitle: __('Save'),
  onAction() {
    console.log('save image', state)
  },
})

const { user } = storeToRefs(useSessionStore())

const actions = [
  {
    title: __('Library'),
    class: 'bg-green',
    onClick() {
      fileGalleryInput.value?.click()
    },
  },
  {
    title: __('Camera'),
    class: 'bg-blue',
    onClick() {
      fileCameraInput.value?.click()
    },
  },
  {
    title: __('Delete'),
    class: 'bg-red',
    onClick() {
      if (!user.value) return
      state.deleted = true
      state.image = ''
      avatarImage.value = undefined
      // delete user.value.image
    },
  },
]

const loadAvatar = async (input?: HTMLInputElement) => {
  const files = input?.files
  const [avatar] = await convertFileList(files)
  avatarImage.value = avatar
}

const imageCropped = (crop: CropperResult) => {
  if (!crop.canvas) return
  state.image = crop.canvas.toDataURL('image/png')
  state.deleted = false
}
</script>

<template>
  <div v-if="user" class="mt-4 px-4">
    <div class="flex flex-col items-center">
      <CommonAvatar v-if="state.image" :image="state.image" size="xl" />
      <CommonUserAvatar v-else :entity="user" size="xl" personal />

      <div class="mt-4 flex">
        <div
          v-for="action in actions"
          :key="action.title"
          class="cursor-pointer rounded-xl py-2 px-3 text-base ltr:mr-2 rtl:ml-2"
          :class="action.class"
          @click="action.onClick"
        >
          {{ $t(action.title) }}
        </div>
      </div>

      <input
        ref="fileGalleryInput"
        data-test-id="fileGalleryInput"
        type="file"
        class="hidden"
        accept="image/*"
        @change="loadAvatar(fileGalleryInput)"
      />

      <input
        ref="fileCameraInput"
        data-test-id="fileCameraInput"
        type="file"
        class="hidden"
        accept="image/*"
        capture="environment"
        @change="loadAvatar(fileCameraInput)"
      />

      <Cropper
        v-if="avatarImage"
        class="cropper mb-4 mt-4"
        :src="avatarImage.content"
        :stencil-props="{
          aspectRatio: 1 / 1,
        }"
        :transitions="false"
        background-class="!bg-black"
        foreground-class="!bg-black"
        @change="imageCropped"
      />
    </div>

    <!-- TODO list of avatars to choose from? -->
  </div>
</template>

<style scoped lang="scss">
.cropper {
  max-height: 250px;
  max-width: 400px;
}
</style>
