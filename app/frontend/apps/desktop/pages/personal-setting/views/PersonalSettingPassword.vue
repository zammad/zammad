<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

import { useCheckChangePassword } from '../composables/permission/useCheckChangePassword.ts'
import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { useUserCurrentChangePasswordMutation } from '../graphql/mutations/userCurrentChangePassword.api.ts'

import type { ChangePasswordFormData } from '../types/change-password.ts'

defineOptions({
  beforeRouteEnter() {
    const { canChangePassword } = useCheckChangePassword()

    if (!canChangePassword.value) {
      // TODO: Redirect to error page using redirectToError or something similar.
      return '/error'
    }

    return true
  },
})

const { form, isDisabled } = useForm()

const schema = [
  {
    isLayout: true,
    element: 'div',
    attrs: {
      class: 'grid grid-cols-2 gap-2.5',
    },
    children: [
      {
        name: 'current_password',
        label: __('Current password'),
        type: 'password',
        outerClass: 'col-span-2',
        props: {
          maxLength: 1001,
          autocomplete: 'current-password',
        },
        required: true,
      },
      {
        name: 'new_password',
        label: __('New password'),
        type: 'password',
        outerClass: 'col-span-1',
        props: {
          maxLength: 1001,
          autocomplete: 'new-password',
        },
        required: true,
      },
      {
        name: 'new_password_confirm',
        label: __('Confirm new password'),
        type: 'password',
        validation: 'confirm',
        outerClass: 'col-span-1',
        props: {
          maxLength: 1001,
          autocomplete: 'new-password',
        },
        required: true,
      },
    ],
  },
]

const { breadcrumbItems } = useBreadcrumb(__('Password'))

const { notify } = useNotifications()

const changePasswordMutation = new MutationHandler(
  useUserCurrentChangePasswordMutation(),
  {
    errorNotificationMessage: __('Password could not be changed.'),
  },
)

const submitForm = async (formData: FormSubmitData<ChangePasswordFormData>) => {
  return changePasswordMutation
    .send({
      currentPassword: formData.current_password as string,
      newPassword: formData.new_password as string,
    })
    .then((data) => {
      if (data?.userCurrentChangePassword?.success) {
        notify({
          id: 'password-changed',
          type: NotificationTypes.Success,
          message: __('Password changed successfully.'),
        })
      }
    })
}
</script>

<template>
  <LayoutContent
    :breadcrumb-items="breadcrumbItems"
    :help-text="
      $t('Enter your current password, insert a new one and confirm it.')
    "
    width="narrow"
  >
    <div class="mb-4">
      <Form
        ref="form"
        :schema="schema"
        clear-values-after-submit
        @submit="submitForm($event as FormSubmitData<ChangePasswordFormData>)"
      >
        <template #after-fields>
          <div class="mt-5 flex items-center justify-end gap-2">
            <CommonButton
              variant="submit"
              type="submit"
              size="medium"
              :disabled="isDisabled"
            >
              {{ $t('Change Password') }}
            </CommonButton>
          </div>
        </template>
      </Form>
    </div>
  </LayoutContent>
</template>
