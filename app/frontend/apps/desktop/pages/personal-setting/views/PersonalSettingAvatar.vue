<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, useTemplateRef } from 'vue'

import CommonAvatar from '#shared/components/CommonAvatar/CommonAvatar.vue'
import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { useUserCurrentAvatarAddMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentAvatarAdd.api.ts'
import { useUserCurrentAvatarDeleteMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentAvatarDelete.api.ts'
import type {
  UserCurrentAvatarUpdatesSubscriptionVariables,
  UserCurrentAvatarUpdatesSubscription,
  Avatar,
  UserCurrentAvatarListQuery,
} from '#shared/graphql/types.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { ImageFileData } from '#shared/utils/files.ts'
import {
  convertFileList,
  allowedImageTypesString,
} from '#shared/utils/files.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { useUserCurrentAvatarSelectMutation } from '../graphql/mutations/userCurrentAvatarSelect.api.ts'
import {
  useUserCurrentAvatarListQuery,
  UserCurrentAvatarListDocument,
} from '../graphql/queries/userCurrentAvatarList.api.ts'
import { UserCurrentAvatarUpdatesDocument } from '../graphql/subscriptions/userCurrentAvatarUpdates.api.ts'

import type { ApolloCache, NormalizedCacheObject } from '@apollo/client/core'

const { user } = storeToRefs(useSessionStore())

const { breadcrumbItems } = useBreadcrumb(__('Avatar'))

const { notify } = useNotifications()

const application = useApplicationStore()
const apiUrl = String(application.config.api_path)

const { isTouchDevice } = useTouchDevice()

const avatarListQuery = new QueryHandler(useUserCurrentAvatarListQuery())
const avatarListQueryResult = avatarListQuery.result()
const avatarListQueryLoading = avatarListQuery.loading()

avatarListQuery.subscribeToMore<
  UserCurrentAvatarUpdatesSubscriptionVariables,
  UserCurrentAvatarUpdatesSubscription
>({
  document: UserCurrentAvatarUpdatesDocument,
  updateQuery: (_, { subscriptionData }) => {
    if (!subscriptionData.data?.userCurrentAvatarUpdates.avatars) {
      return null as unknown as UserCurrentAvatarListQuery
    }

    return {
      userCurrentAvatarList:
        subscriptionData.data.userCurrentAvatarUpdates.avatars,
    }
  },
})

const currentAvatars = computed(() => {
  return avatarListQueryResult.value?.userCurrentAvatarList || []
})

const currentDefaultAvatar = computed(() => {
  return currentAvatars.value.find((avatar) => avatar.default)
})

const fileUploadElement = useTemplateRef('file-upload')

const cameraFlyout = useFlyout({
  name: 'avatar-camera-capture',
  component: () =>
    import('../components/PersonalSettingAvatarCameraFlyout.vue'),
})

const cropImageFlyout = useFlyout({
  name: 'avatar-file-upload',
  component: () =>
    import('../components/PersonalSettingAvatarCropImageFlyout.vue'),
})

const modifyDefaultAvatarCache = (
  cache: ApolloCache<NormalizedCacheObject>,
  avatar: Avatar | undefined,
  newValue: boolean,
) => {
  if (!avatar) return

  cache.modify({
    id: cache.identify(avatar),
    fields: {
      default() {
        return newValue
      },
    },
  })
}

const storeAvatar = (image: ImageFileData) => {
  if (!image) return

  const addAvatarMutation = new MutationHandler(
    useUserCurrentAvatarAddMutation({
      variables: {
        images: {
          original: image,
          resized: {
            name: 'resized_avatar.png',
            type: 'image/png',
            content: image.content,
          },
        },
      },
      update: (cache, { data }) => {
        if (!data) return

        const { userCurrentAvatarAdd } = data
        if (!userCurrentAvatarAdd?.avatar) return

        const newIdPresent = currentAvatars.value.find((avatar) => {
          return avatar.id === userCurrentAvatarAdd.avatar?.id
        })
        if (newIdPresent) return

        modifyDefaultAvatarCache(cache, currentDefaultAvatar.value, false)

        let existingAvatars = cache.readQuery<UserCurrentAvatarListQuery>({
          query: UserCurrentAvatarListDocument,
        })

        existingAvatars = {
          ...existingAvatars,
          userCurrentAvatarList: [
            ...(existingAvatars?.userCurrentAvatarList || []),
            userCurrentAvatarAdd.avatar,
          ],
        }

        cache.writeQuery({
          query: UserCurrentAvatarListDocument,
          data: existingAvatars,
        })
      },
    }),
    {
      errorNotificationMessage: __('The avatar could not be uploaded.'),
    },
  )

  addAvatarMutation.send().then((data) => {
    if (data?.userCurrentAvatarAdd?.avatar) {
      if (user.value) {
        user.value.image = data.userCurrentAvatarAdd.avatar.imageHash
      }

      notify({
        id: 'avatar-upload-success',
        type: NotificationTypes.Success,
        message: __('Your avatar has been uploaded.'),
      })
    }
  })
}

const addAvatarByUpload = () => {
  fileUploadElement.value?.click()
}

const addAvatarByCamera = () => {
  cameraFlyout.open({
    onAvatarCaptured: (image: ImageFileData) => {
      storeAvatar(image)
    },
  })
}

const loadAvatar = async (input: HTMLInputElement | null) => {
  const files = input?.files
  if (!files) return

  const [avatar] = await convertFileList(files)

  cropImageFlyout.open({
    image: avatar,
    onImageCropped: (image: ImageFileData) => storeAvatar(image),
  })

  // Reset input value to allow selecting the same file again
  input.value = ''
}

const selectAvatar = (avatar: Avatar) => {
  // Update the cache already before the
  const { cache } = getApolloClient()
  const oldDefaultAvatar = currentDefaultAvatar.value

  modifyDefaultAvatarCache(cache, oldDefaultAvatar, false)
  modifyDefaultAvatarCache(cache, avatar, true)

  const accountAvatarSelectMutation = new MutationHandler(
    useUserCurrentAvatarSelectMutation(() => ({
      variables: { id: avatar.id },
    })),
    {
      errorNotificationMessage: __('The avatar could not be selected.'),
    },
  )

  accountAvatarSelectMutation
    .send()
    .then(() => {
      notify({
        id: 'avatar-select-success',
        type: NotificationTypes.Success,
        message: __('Your avatar has been changed.'),
      })
    })
    .catch(() => {
      // Reset the cache again if the mutation fails.
      modifyDefaultAvatarCache(cache, oldDefaultAvatar, true)
      modifyDefaultAvatarCache(cache, avatar, false)
    })
}

const deleteAvatar = (avatar: Avatar) => {
  const accountAvatarDeleteMutation = new MutationHandler(
    useUserCurrentAvatarDeleteMutation(() => ({
      variables: { id: avatar.id },
      update(cache) {
        if (avatar.default) {
          modifyDefaultAvatarCache(cache, currentAvatars.value[0], true)
        }

        cache.evict({ id: cache.identify(avatar) })
        cache.gc()
      },
    })),
    {
      errorNotificationMessage: __('The avatar could not be deleted.'),
    },
  )

  accountAvatarDeleteMutation.send().then(() => {
    notify({
      id: 'avatar-delete-success',
      type: NotificationTypes.Success,
      message: __('Your avatar has been deleted.'),
    })
  })
}

const { waitForVariantConfirmation } = useConfirmation()

const confirmDeleteAvatar = async (avatar: Avatar) => {
  const confirmed = await waitForVariantConfirmation('delete')

  if (confirmed) deleteAvatar(avatar)
}

const avatarButtonClasses = [
  'cursor-pointer',
  'outline-transparent',
  'hover:outline-blue-900',
  'rounded-full',
  'outline',
  'outline-3',
  'focus:outline-blue-800',
  'hover:focus:outline-blue-800',
]

const activeAvatarButtonClass = (active: boolean) => {
  return {
    'outline-blue-800 hover:outline-blue-800': active,
  }
}
</script>

<template>
  <LayoutContent :breadcrumb-items="breadcrumbItems" width="narrow">
    <CommonLoader :loading="avatarListQueryLoading">
      <div class="mb-4">
        <CommonLabel class="!mt-0.5 mb-1 !block"
          >{{ $t('Your avatar') }}
        </CommonLabel>

        <div class="rounded-lg bg-blue-200 dark:bg-gray-700">
          <div class="flex flex-row flex-wrap gap-2.5 p-2.5">
            <template v-for="avatar in currentAvatars" :key="avatar.id">
              <button
                v-if="avatar.initial && user"
                :aria-label="$t('Select this avatar')"
                :class="[
                  ...avatarButtonClasses,
                  activeAvatarButtonClass(avatar.default),
                ]"
                @click.stop="avatar.default ? void 0 : selectAvatar(avatar)"
              >
                <CommonUserAvatar
                  :class="{ 'avatar-selected': avatar.default }"
                  :entity="user"
                  class="!flex border-neutral-100 dark:border-gray-900"
                  size="large"
                  initials-only
                  personal
                  no-indicator
                  no-muted
                />
              </button>
              <div
                v-else-if="avatar.imageHash"
                class="group/avatar relative flex"
              >
                <button
                  :aria-label="$t('Select this avatar')"
                  :class="[
                    ...avatarButtonClasses,
                    activeAvatarButtonClass(avatar.default),
                  ]"
                  @click.stop="avatar.default ? void 0 : selectAvatar(avatar)"
                >
                  <CommonAvatar
                    :class="{ 'avatar-selected': avatar.default }"
                    :image="`${apiUrl}/users/image/${avatar.imageHash}`"
                    class="!flex border-neutral-100 dark:border-gray-900"
                    size="large"
                  >
                  </CommonAvatar>
                </button>
                <CommonButton
                  v-if="avatar.deletable"
                  :aria-label="$t('Delete this avatar')"
                  :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
                  class="absolute -end-2 -top-1 text-white group-hover/avatar:opacity-100 focus:opacity-100"
                  icon="x-lg"
                  size="small"
                  variant="remove"
                  @click.stop="confirmDeleteAvatar(avatar)"
                />
              </div>
            </template>
          </div>

          <CommonDivider padding />

          <div class="w-full p-1 text-center">
            <input
              ref="file-upload"
              :accept="allowedImageTypesString()"
              aria-hidden="true"
              class="hidden"
              data-test-id="fileUploadInput"
              type="file"
              @change="loadAvatar(fileUploadElement)"
            />

            <CommonButton
              class="m-1"
              size="medium"
              prefix-icon="image"
              @click="addAvatarByUpload"
            >
              {{ $t('Upload') }}
            </CommonButton>

            <CommonButton
              class="m-1"
              size="medium"
              prefix-icon="camera"
              @click="addAvatarByCamera"
            >
              {{ $t('Camera') }}
            </CommonButton>
          </div>
        </div>
      </div>
    </CommonLoader>
  </LayoutContent>
</template>
