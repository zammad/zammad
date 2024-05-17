<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { reactive, shallowRef, watch, ref, computed } from 'vue'
import { Cropper, type CropperResult } from 'vue-advanced-cropper'
import { useRouter } from 'vue-router'
import 'vue-advanced-cropper/dist/style.css'

import CommonAvatar from '#shared/components/CommonAvatar/CommonAvatar.vue'
import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useUserCurrentAvatarAddMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentAvatarAdd.api.ts'
import { useUserCurrentAvatarDeleteMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentAvatarDelete.api.ts'
import type UserError from '#shared/errors/UserError.ts'
import type { UserCurrentAvatarActiveQuery } from '#shared/graphql/types.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { ImageFileData } from '#shared/utils/files.ts'
import {
  convertFileList,
  allowedImageTypesString,
} from '#shared/utils/files.ts'

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonButtonGroup from '#mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import type { CommonButtonOption } from '#mobile/components/CommonButtonGroup/types.ts'
import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import { useHeader } from '#mobile/composables/useHeader.ts'

import { useUserCurrentAvatarActiveQuery } from '../graphql/queries/userCurrentAvatarActive.api.ts'

const router = useRouter()

const fileCameraInput = shallowRef<HTMLInputElement>()
const fileGalleryInput = shallowRef<HTMLInputElement>()
const avatarImage = shallowRef<ImageFileData>()

const activeAvatarQuery = new QueryHandler(useUserCurrentAvatarActiveQuery(), {
  errorNotificationMessage: __('The avatar could not be fetched.'),
})
const activeAvatar =
  ref<UserCurrentAvatarActiveQuery['userCurrentAvatarActive']>()

activeAvatarQuery.watchOnResult((data) => {
  activeAvatar.value = data?.userCurrentAvatarActive
})

const avatarLoading = activeAvatarQuery.loading()

const state = reactive({
  resizedImage: activeAvatar.value?.imageResize || '',
})

watch(activeAvatar, (newValue) => {
  state.resizedImage = newValue?.imageResize || ''
})

const { user } = storeToRefs(useSessionStore())

const avatarDeleteDisabled = computed(() => {
  return !activeAvatar.value?.deletable
})

const addAvatar = () => {
  if (!state.resizedImage) return
  if (!avatarImage.value) return

  const addAvatarMutation = new MutationHandler(
    useUserCurrentAvatarAddMutation({
      variables: {
        images: {
          original: avatarImage.value,
          resized: {
            name: 'resized_avatar.png',
            type: 'image/png',
            content: state.resizedImage,
          },
        },
      },
    }),
    {
      errorNotificationMessage: __('The avatar could not be uploaded.'),
    },
  )

  const { notify, clearAllNotifications } = useNotifications()

  // Clear notifications to avoid duplicated error messages.
  clearAllNotifications()

  addAvatarMutation
    .send()
    .then((data) => {
      if (data?.userCurrentAvatarAdd?.avatar) {
        activeAvatar.value = data.userCurrentAvatarAdd.avatar
        avatarImage.value = undefined

        if (user.value) {
          user.value.image = data.userCurrentAvatarAdd.avatar.imageHash
        }
      }
    })
    .catch((errors: UserError) => {
      notify({
        id: 'avatar-add-error',
        message: errors.generalErrors[0],
        type: NotificationTypes.Error,
      })
    })
}

const canRemoveAvatar = () => {
  if (!user.value) return false
  if (!activeAvatar.value?.id) return false
  if (!activeAvatar.value?.deletable) return false

  return true
}

const removeAvatar = () => {
  if (!canRemoveAvatar()) return
  if (!activeAvatar.value?.id) return

  const removeAvatarMutation = new MutationHandler(
    useUserCurrentAvatarDeleteMutation({
      variables: { id: activeAvatar.value.id },
    }),
    {
      errorNotificationMessage: __('The avatar could not be deleted.'),
    },
  )

  removeAvatarMutation.send().then((data) => {
    if (data?.userCurrentAvatarDelete?.success) {
      state.resizedImage = ''
      avatarImage.value = undefined
      activeAvatar.value = undefined

      // reset image value in user store
      if (user.value) {
        user.value.image = undefined
      }
    }
  })
}
const { waitForConfirmation } = useConfirmation()

const confirmRemoveAvatar = async () => {
  if (!canRemoveAvatar()) return

  const confirmed = await waitForConfirmation(
    __('Do you really want to delete your current avatar?'),
    {
      buttonLabel: __('Delete avatar'),
      buttonVariant: 'danger',
    },
  )
  if (confirmed) removeAvatar()
}

const saveButtonActive = computed(() => {
  if (state.resizedImage && avatarImage.value) return true
  return false
})

useHeader({
  title: __('Avatar'),
  backUrl: '/account',
  actionTitle: __('Done'),
  backIgnore: ['/user/current/avatar'],
  refetch: computed(
    () => avatarLoading.value && !!activeAvatarQuery.result().value,
  ),
  onAction() {
    router.push('/account')
  },
})

const loadAvatar = async (input?: HTMLInputElement) => {
  const files = input?.files
  if (!files) return
  const [avatar] = await convertFileList(files)
  avatarImage.value = avatar

  // Reset input value to allow selecting the same file again
  input.value = ''
}

const imageCropped = (crop: CropperResult) => {
  if (!crop.canvas) return
  state.resizedImage = crop.canvas.toDataURL('image/png')
}

const cancelCropping = () => {
  avatarImage.value = undefined
  state.resizedImage = activeAvatar.value?.imageResize || ''
}

const actions = computed<CommonButtonOption[]>(() => [
  {
    label: __('Library'),
    icon: 'photos',
    value: 'library',
    onAction: () => fileGalleryInput.value?.click(),
  },
  {
    label: __('Camera'),
    icon: 'camera',
    value: 'camera',
    onAction: () => fileCameraInput.value?.click(),
  },
  {
    label: __('Delete'),
    icon: 'delete',
    value: 'delete',
    disabled: avatarDeleteDisabled.value,
    class: 'bg-red-dark !text-red-bright',
    onAction: confirmRemoveAvatar,
  },
])
</script>

<template>
  <div v-if="user" class="px-4">
    <div class="flex flex-col items-center py-6">
      <CommonLoader
        :loading="avatarLoading && !activeAvatarQuery.result().value"
      >
        <CommonAvatar
          v-if="state.resizedImage"
          :image="state.resizedImage"
          size="xl"
        />
        <CommonUserAvatar v-else :entity="user" size="xl" personal />
        <CommonButtonGroup class="mt-6" mode="full" :options="actions" />
      </CommonLoader>

      <input
        ref="fileGalleryInput"
        data-test-id="fileGalleryInput"
        type="file"
        class="hidden"
        aria-hidden="true"
        :accept="allowedImageTypesString()"
        @change="loadAvatar(fileGalleryInput)"
      />

      <input
        ref="fileCameraInput"
        data-test-id="fileCameraInput"
        type="file"
        class="hidden"
        aria-hidden="true"
        :accept="allowedImageTypesString()"
        capture="user"
        @change="loadAvatar(fileCameraInput)"
      />

      <div
        v-if="avatarImage"
        class="flex w-full flex-col items-center justify-center"
      >
        <Cropper
          class="mb-4 mt-4 !max-h-[250px] !max-w-[400px]"
          :src="avatarImage.content"
          :stencil-props="{
            aspectRatio: 1,
          }"
          :transitions="false"
          background-class="!bg-black"
          foreground-class="!bg-black"
          @change="imageCropped"
        />
        <div class="flex w-full gap-2">
          <CommonButton class="h-10 flex-1" @click="cancelCropping">
            {{ $t('Cancel') }}
          </CommonButton>
          <CommonButton
            variant="primary"
            :disabled="!saveButtonActive"
            class="h-10 flex-1"
            @click="addAvatar"
          >
            {{ $t('Save') }}
          </CommonButton>
        </div>
      </div>
    </div>
  </div>
</template>
