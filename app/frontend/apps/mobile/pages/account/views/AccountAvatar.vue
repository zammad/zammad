<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { reactive, shallowRef, watch, ref, computed } from 'vue'
import { storeToRefs } from 'pinia'
import { Cropper, type CropperResult } from 'vue-advanced-cropper'
import 'vue-advanced-cropper/dist/style.css'
import type { ImageFileData } from '@shared/utils/files'
import { convertFileList } from '@shared/utils/files'
import { useSessionStore } from '@shared/stores/session'
import { useApplicationStore } from '@shared/stores/application'
import {
  useNotifications,
  NotificationTypes,
} from '@shared/components/CommonNotifications'
import type UserError from '@shared/errors/UserError'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonAvatar from '@shared/components/CommonAvatar/CommonAvatar.vue'
import { MutationHandler, QueryHandler } from '@shared/server/apollo/handler'
import type { AccountAvatarActiveQuery } from '@shared/graphql/types'
import { useRouter } from 'vue-router'
import { useHeader } from '@mobile/composables/useHeader'
import useConfirmation from '@mobile/components/CommonConfirmation/composable'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { useAccountAvatarActiveQuery } from '../avatar/graphql/queries/active.api'
import { useAccountAvatarAddMutation } from '../avatar/graphql/mutations/add.api'
import { useAccountAvatarDeleteMutation } from '../avatar/graphql/mutations/delete.api'

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
  image: activeAvatar.value?.imageResize || '',
})

watch(activeAvatar, (newValue) => {
  state.image = newValue?.imageResize || ''
})

const { user } = storeToRefs(useSessionStore())

const avatarDeleteDisabled = computed(() => {
  return !activeAvatar.value?.deletable
})

const addAvatar = () => {
  if (!state.image) return
  if (!avatarImage.value) return

  const addAvatarMutation = new MutationHandler(
    useAccountAvatarAddMutation({
      variables: {
        images: {
          full: avatarImage.value?.content,
          resize: state.image,
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
      state.image = ''
      avatarImage.value = undefined
      activeAvatar.value = undefined

      // reset image value in user store
      if (user.value) {
        user.value.image = undefined
      }
    }
  })
}

const { showConfirmation } = useConfirmation()

const confirmRemoveAvatar = async () => {
  if (!canRemoveAvatar()) return

  showConfirmation({
    heading: __('Do you really want to delete your current avatar?'),
    buttonTitle: __('Delete avatar'),
    buttonTextColorClass: 'text-red-bright',
    confirmCallback: removeAvatar,
  })
}

const saveButtonActive = computed(() => {
  if (state.image && avatarImage.value) return true
  return false
})

useHeader({
  title: __('Avatar'),
  backUrl: '/account',
  backTitle: __('Account'),
  actionTitle: __('Done'),
  onAction() {
    router.push('/account')
  },
})

const loadAvatar = async (input?: HTMLInputElement) => {
  const files = input?.files
  const [avatar] = await convertFileList(files)
  avatarImage.value = avatar
}

const imageCropped = (crop: CropperResult) => {
  if (!crop.canvas) return
  state.image = crop.canvas.toDataURL('image/png')
}

const cancelCropping = () => {
  avatarImage.value = undefined
  state.image = activeAvatar.value?.imageResize || ''
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
</script>

<template>
  <div v-if="user" class="px-4">
    <div class="flex flex-col items-center py-6">
      <CommonLoader :loading="avatarLoading">
        <CommonAvatar v-if="state.image" :image="state.image" size="xl" />
        <CommonUserAvatar v-else :entity="user" size="xl" personal />

        <div class="mt-4 flex w-full justify-center gap-2">
          <button
            class="w-full cursor-pointer rounded-xl bg-green py-2 px-3 text-base text-black"
            @click="fileGalleryInput?.click()"
          >
            {{ $t('Library') }}
          </button>
          <button
            class="w-full cursor-pointer rounded-xl bg-blue py-2 px-3 text-base text-black"
            @click="fileCameraInput?.click()"
          >
            {{ $t('Camera') }}
          </button>
          <button
            class="w-full rounded-xl bg-red-bright py-2 px-3 text-base text-black disabled:opacity-50"
            :class="{
              ['cursor-pointer']: !avatarDeleteDisabled,
              ['cursor-not-allowed']: avatarDeleteDisabled,
            }"
            :disabled="avatarDeleteDisabled"
            @click="confirmRemoveAvatar"
          >
            {{ $t('Delete') }}
          </button>
        </div>
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
        capture="environment"
        @change="loadAvatar(fileCameraInput)"
      />

      <div
        v-if="avatarImage"
        class="flex w-full flex-col items-center justify-center"
      >
        <Cropper
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
        <div class="flex w-full gap-2">
          <button
            class="w-full cursor-pointer rounded-xl py-2 px-3 text-base"
            @click="cancelCropping"
          >
            {{ $t('Cancel') }}
          </button>
          <button
            class="w-full cursor-pointer rounded-xl bg-yellow py-2 px-3 text-base text-black"
            :disabled="!saveButtonActive"
            @click="addAvatar"
          >
            {{ $t('Save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.cropper {
  max-height: 250px;
  max-width: 400px;
}
</style>
