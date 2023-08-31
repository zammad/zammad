<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { reactive, shallowRef, watch, ref, computed } from 'vue'
import { storeToRefs } from 'pinia'
import { Cropper, type CropperResult } from 'vue-advanced-cropper'
import 'vue-advanced-cropper/dist/style.css'
import type { ImageFileData } from '#shared/utils/files.ts'
import { convertFileList } from '#shared/utils/files.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import type UserError from '#shared/errors/UserError.ts'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonAvatar from '#shared/components/CommonAvatar/CommonAvatar.vue'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'
import type { AccountAvatarActiveQuery } from '#shared/graphql/types.ts'
import { useRouter } from 'vue-router'
import { useHeader } from '#mobile/composables/useHeader.ts'
import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonButtonGroup from '#mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import type { CommonButtonOption } from '#mobile/components/CommonButtonGroup/types.ts'
import { waitForConfirmation } from '#shared/utils/confirmation.ts'
import { useAccountAvatarActiveQuery } from '../avatar/graphql/queries/active.api.ts'
import { useAccountAvatarAddMutation } from '../avatar/graphql/mutations/add.api.ts'
import { useAccountAvatarDeleteMutation } from '../avatar/graphql/mutations/delete.api.ts'

const router = useRouter()

const fileCameraInput = shallowRef<HTMLInputElement>()
const fileGalleryInput = shallowRef<HTMLInputElement>()
const avatarImage = shallowRef<ImageFileData>()

const activeAvatarQuery = new QueryHandler(useAccountAvatarActiveQuery(), {
  errorNotificationMessage: __('The avatar could not be fetched.'),
})
const activeAvatar = ref<AccountAvatarActiveQuery['accountAvatarActive']>()

activeAvatarQuery.watchOnResult((data) => {
  activeAvatar.value = data?.accountAvatarActive
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
    useAccountAvatarAddMutation({
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
      if (data?.accountAvatarAdd?.avatar) {
        activeAvatar.value = data.accountAvatarAdd.avatar
        avatarImage.value = undefined

        if (user.value) {
          user.value.image = activeAvatar.value?.imageResize
        }
      }
    })
    .catch((errors: UserError) => {
      notify({
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
    useAccountAvatarDeleteMutation({
      variables: { id: activeAvatar.value.id },
    }),
    {
      errorNotificationMessage: __('The avatar could not be deleted.'),
    },
  )

  removeAvatarMutation.send().then((data) => {
    if (data?.accountAvatarDelete?.success) {
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

const confirmRemoveAvatar = async () => {
  if (!canRemoveAvatar()) return

  const confirmed = await waitForConfirmation(
    __('Do you really want to delete your current avatar?'),
    {
      buttonTitle: __('Delete avatar'),
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
  backIgnore: ['/account/avatar'],
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
}

const imageCropped = (crop: CropperResult) => {
  if (!crop.canvas) return
  state.resizedImage = crop.canvas.toDataURL('image/png')
}

const cancelCropping = () => {
  avatarImage.value = undefined
  state.resizedImage = activeAvatar.value?.imageResize || ''
}

const application = useApplicationStore()
const allowedImageTypes = computed(() => {
  if (!application.config['active_storage.web_image_content_types'])
    return 'image/*'

  const types = application.config[
    'active_storage.web_image_content_types'
  ] as Array<string>

  return types.join(',')
})

const actions = computed<CommonButtonOption[]>(() => [
  {
    label: __('Library'),
    icon: 'mobile-photos',
    value: 'library',
    onAction: () => fileGalleryInput.value?.click(),
  },
  {
    label: __('Camera'),
    icon: 'mobile-camera',
    value: 'camera',
    onAction: () => fileCameraInput.value?.click(),
  },
  {
    label: __('Delete'),
    icon: 'mobile-delete',
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
        :accept="allowedImageTypes"
        @change="loadAvatar(fileGalleryInput)"
      />

      <input
        ref="fileCameraInput"
        data-test-id="fileCameraInput"
        type="file"
        class="hidden"
        aria-hidden="true"
        :accept="allowedImageTypes"
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
            aspectRatio: 1 / 1,
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
