<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'

import Form from '#shared/components/Form/Form.vue'
import { useForm } from '#shared/components/Form/useForm.ts'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'

import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import { useApplicationStore } from '#shared/stores/application.ts'

import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import type { ChangePasswordFormData } from '../types/change-password.ts'
import { useAccountChangePasswordMutation } from '../graphql/mutations/accountChangePassword.api.ts'

defineOptions({
  beforeRouteEnter() {
    const application = useApplicationStore()
    if (!application.config.user_show_password_login) {
      // TODO: Redirect to error page using redirectToError or something similar.
      return '/error'
    }
    return true
  },
})

const { form, isDisabled } = useForm()

const schema = defineFormSchema([
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
])

const { breadcrumbItems } = useBreadcrumb(__('Password'))

const { notify } = useNotifications()

const changePasswordMutation = new MutationHandler(
  useAccountChangePasswordMutation(),
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
      if (data?.accountChangePassword?.success) {
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
  <LayoutContent provide-default :breadcrumb-items="breadcrumbItems">
    <div class="mb-4 max-w-[600px]">
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
