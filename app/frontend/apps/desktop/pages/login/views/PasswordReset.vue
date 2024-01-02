<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type {
  FormSchemaNode,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import Form from '#shared/components/Form/Form.vue'
import { useApplicationStore } from '#shared/stores/application.ts'
import { EnumPublicLinksScreen } from '#shared/graphql/types.ts'
import { ref } from 'vue'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import UserError from '#shared/errors/UserError.ts'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonPublicLinks from '#desktop/components/CommonPublicLinks/CommonPublicLinks.vue'
import { useUserPasswordResetSendMutation } from '../graphql/mutations/userPasswordResetSend.api.ts'

defineOptions({
  beforeRouteEnter(to) {
    const application = useApplicationStore()
    if (!application.config.user_lost_password) {
      return to.redirectedFrom ? false : '/'
    }
    return true
  },
})

interface FormValues {
  login: string
}

const formSchema: FormSchemaNode[] = [
  {
    type: 'text',
    label: __('Username / Email'),
    name: 'login',
    required: true,
  },
]

const showSuccessScreen = ref(false)
const resetHandler = new MutationHandler(useUserPasswordResetSendMutation())
const { notify } = useNotifications()

const resetPassword = async (form: FormSubmitData<FormValues>) => {
  try {
    const result = await resetHandler.send({ username: form.login })
    if (result?.userPasswordResetSend?.success) {
      showSuccessScreen.value = true
    }
  } catch (error) {
    if (error instanceof UserError) {
      notify({
        type: NotificationTypes.Error,
        message: error.generalErrors[0],
      })
    }
  }
}

const resetForm = () => {
  showSuccessScreen.value = false
}
</script>

<template>
  <LayoutPublicPage
    box-size="small"
    :title="
      showSuccessScreen
        ? __('Password reset request successful!')
        : __('Forgot your password?')
    "
  >
    <Form
      v-if="!showSuccessScreen"
      :schema="formSchema"
      @submit="resetPassword($event as FormSubmitData<FormValues>)"
    >
      <template #after-fields>
        <div class="flex gap-3 justify-end items-center pt-5">
          <CommonLink link="/login" replace class="select-none">
            {{ $t('Cancel & Go Back') }}
          </CommonLink>
          <CommonButton type="submit" variant="submit" size="large">
            {{ $t('Submit') }}
          </CommonButton>
        </div>
      </template>
    </Form>
    <section v-else>
      <CommonLabel class="text-center mb-5">
        {{
          $t("We've sent password reset instructions to your email address.")
        }}
      </CommonLabel>
      <CommonLabel class="text-center">
        {{
          $t(
            "If you don't receive instructions within a minute or two, check your email's spam and junk filters, or try resending your request.",
          )
        }}
      </CommonLabel>
      <div class="flex gap-3 justify-end items-center pt-5">
        <CommonLink link="/login" replace class="select-none">
          {{ $t('Cancel & Go Back') }}
        </CommonLink>
        <CommonButton variant="submit" size="large" @click="resetForm">
          {{ $t('Try again') }}
        </CommonButton>
      </div>
    </section>
    <template #bottomContent>
      <CommonPublicLinks :screen="EnumPublicLinksScreen.PasswordReset" />
    </template>
  </LayoutPublicPage>
</template>
