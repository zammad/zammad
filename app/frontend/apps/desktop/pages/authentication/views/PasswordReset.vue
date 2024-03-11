<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { ref } from 'vue'

import type {
  FormSchemaNode,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import Form from '#shared/components/Form/Form.vue'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { EnumPublicLinksScreen } from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import UserError from '#shared/errors/UserError.ts'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'
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

const router = useRouter()

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

const { form, isDisabled } = useForm()

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

const goToLogin = () => {
  router.replace('/login')
}
</script>

<template>
  <LayoutPublicPage
    box-size="small"
    :title="
      showSuccessScreen
        ? __('The password reset request was successful.')
        : __('Forgot your password?')
    "
  >
    <Form
      v-if="!showSuccessScreen"
      id="password-reset"
      ref="form"
      form-class="mb-2.5"
      :schema="formSchema"
      @submit="resetPassword($event as FormSubmitData<FormValues>)"
    />
    <section v-else>
      <CommonLabel class="text-center mb-5">
        {{ $t('Password reset instructions were sent to your email address.') }}
      </CommonLabel>
      <CommonLabel class="text-center">
        {{
          $t(
            "If you don't receive instructions within a minute or two, check your email's spam and junk filters, or try resending your request.",
          )
        }}
      </CommonLabel>
    </section>
    <template #boxActions>
      <CommonButton
        variant="secondary"
        size="medium"
        :disabled="isDisabled"
        @click="goToLogin()"
      >
        {{ $t('Cancel & Go Back') }}
      </CommonButton>
      <CommonButton
        v-if="!showSuccessScreen"
        type="submit"
        variant="submit"
        size="medium"
        form="password-reset"
        :disabled="isDisabled"
      >
        {{ $t('Submit') }}
      </CommonButton>
      <CommonButton v-else variant="submit" size="medium" @click="resetForm">
        {{ $t('Try again') }}
      </CommonButton>
    </template>
    <template #bottomContent>
      <CommonPublicLinks :screen="EnumPublicLinksScreen.PasswordReset" />
    </template>
  </LayoutPublicPage>
</template>
