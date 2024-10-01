<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed, ref, watch } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import { type FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import {
  EnumFormUpdaterId,
  EnumNotificationSoundFile,
  type UserNotificationMatrixInput,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useBreadcrumb } from '#desktop/pages/personal-setting/composables/useBreadcrumb.ts'
import { useUserCurrentNotificationPreferencesResetMutation } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentNotificationPreferencesReset.api.ts'
import { useUserCurrentNotificationPreferencesUpdateMutation } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentNotificationPreferencesUpdate.api.ts'
import type { NotificationFormData } from '#desktop/pages/personal-setting/types/notifications.ts'

const { breadcrumbItems } = useBreadcrumb(__('Notifications'))

const { user } = storeToRefs(useSessionStore())

const { notify } = useNotifications()

const { waitForConfirmation } = useConfirmation()

const loading = ref(false)

const { form, onChangedField, formReset, values, isDirty } = useForm()

const soundOptions = Object.keys(EnumNotificationSoundFile).map((sound) => ({
  label: sound,
  value: sound,
}))

const schema = defineFormSchema([
  {
    type: 'notifications',
    name: 'matrix',
    label: __('Notification matrix'),
    labelSrOnly: true,
  },
  {
    type: 'select',
    name: 'group_ids',
    label: __('Limit notifications to specific groups'),
    help: __('Affects only notifications for not assigned and all tickets.'),
    props: {
      clearable: true,
      multiple: true,
      noOptionsLabelTranslation: true,
    },
  },
  {
    type: 'select',
    name: 'file',
    label: __('Notification sound'),
    props: {
      options: soundOptions,
    },
  },
  {
    type: 'toggle',
    name: 'enabled',
    label: __('Play user interface sound effects'),
    props: {
      variants: { true: 'True', false: 'False' },
    },
  },
])

const initialFormValues = computed<NotificationFormData>((oldValues) => {
  const { notificationConfig = {}, notificationSound = {} } =
    user.value?.personalSettings || {}

  const values: NotificationFormData = {
    group_ids: notificationConfig?.groupIds ?? [],
    matrix: notificationConfig?.matrix || {},

    // Default notification sound settings are not present on the user preferences.
    file: notificationSound?.file ?? EnumNotificationSoundFile.Xylo,
    enabled: notificationSound?.enabled ?? true,
  }

  if (oldValues && isEqual(values, oldValues)) return oldValues

  return values
})

watch(initialFormValues, (newValues) => {
  // No reset needed when the form has already the correct state.
  if (isEqual(values.value, newValues) && !isDirty.value) return

  formReset({ values: newValues })
})

onChangedField('file', (fileName) => {
  new Audio(`/assets/sounds/${fileName?.toString()}.mp3`)?.play()
})

const onSubmit = async (form: FormSubmitData<NotificationFormData>) => {
  loading.value = true

  const notificationUpdateMutation = new MutationHandler(
    useUserCurrentNotificationPreferencesUpdateMutation(),
    {
      errorNotificationMessage: __('Notification settings could not be saved.'),
    },
  )

  return notificationUpdateMutation
    .send({
      matrix: form.matrix as UserNotificationMatrixInput,
      groupIds:
        form?.group_ids?.map((id) => convertToGraphQLId('Group', id)) || [],
      sound: {
        file: form.file as EnumNotificationSoundFile,
        enabled: form.enabled,
      },
    })
    .then((response) => {
      if (response?.userCurrentNotificationPreferencesUpdate) {
        notify({
          id: 'notification-update-success',
          type: NotificationTypes.Success,
          message: __('Notification settings have been saved successfully.'),
        })
      }
    })
    .finally(() => {
      loading.value = false
    })
}

const resetFormToDefaults = (
  personalSettings: UserData['personalSettings'],
) => {
  form.value?.resetForm({
    values: {
      matrix: personalSettings?.notificationConfig?.matrix || {},
    },
  })
}

const onResetToDefaultSettings = async () => {
  const confirmed = await waitForConfirmation(
    __('Are you sure? Your notifications settings will be reset to default.'),
  )

  if (!confirmed) return

  loading.value = true

  const notificationResetMutation = new MutationHandler(
    useUserCurrentNotificationPreferencesResetMutation(),
    {
      errorNotificationMessage: __('Notification settings could not be reset.'),
    },
  )

  return notificationResetMutation
    .send()
    .then((response) => {
      const personalSettings =
        response?.userCurrentNotificationPreferencesReset?.user
          ?.personalSettings

      if (!personalSettings) return

      resetFormToDefaults(personalSettings)

      notify({
        id: 'notification-reset-success',
        type: NotificationTypes.Success,
        message: __('Notification settings have been reset to default.'),
      })
    })
    .finally(() => {
      loading.value = false
    })
}
</script>

<template>
  <LayoutContent :breadcrumb-items="breadcrumbItems" width="narrow">
    <div class="mb-4">
      <Form
        id="notifications-form"
        ref="form"
        :schema="schema"
        :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterUserNotifications"
        form-updater-initial-only
        :initial-values="initialFormValues"
        @submit="onSubmit($event as FormSubmitData<NotificationFormData>)"
      >
        <template #after-fields>
          <div class="flex justify-end gap-2">
            <CommonButton
              size="medium"
              variant="danger"
              :disabled="loading"
              @click="onResetToDefaultSettings"
            >
              {{ $t('Reset to Default Settings') }}
            </CommonButton>
            <CommonButton
              size="medium"
              type="submit"
              variant="submit"
              :disabled="loading"
            >
              {{ $t('Save Notifications') }}
            </CommonButton>
          </div>
        </template>
      </Form>
    </div>
  </LayoutContent>
</template>
