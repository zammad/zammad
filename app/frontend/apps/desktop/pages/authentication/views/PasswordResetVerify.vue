<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, onBeforeMount } from 'vue'
import { useRouter } from 'vue-router'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSchemaNode,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { EnumPublicLinksScreen } from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonPublicLinks from '#desktop/components/CommonPublicLinks/CommonPublicLinks.vue'
import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'

import { useUserPasswordResetUpdateMutation } from '../graphql/mutations/userPasswordResetUpdate.api.ts'
import { useUserPasswordResetVerifyMutation } from '../graphql/mutations/userPasswordResetVerify.api.ts'

defineOptions({
  beforeRouteEnter(to) {
    const application = useApplicationStore()
    if (!application.config.user_lost_password) {
      return to.redirectedFrom ? false : '/'
    }
    return true
  },
})

interface Props {
  token?: string
}

const props = defineProps<Props>()

interface FormValues {
  password: string
  confirmPassword: string
}

const formSchema: FormSchemaNode[] = [
  {
    type: 'password',
    label: __('Password'),
    name: 'password',
    outerClass: 'col-span-1',
    required: true,
    props: {
      maxLength: 1001,
    },
  },
  {
    type: 'password',
    label: __('Confirm password'),
    name: 'password_confirm',
    outerClass: 'col-span-1',
    validation: 'confirm',
    props: {
      maxLength: 1001,
    },
    required: true,
  },
]

const { form, isDisabled } = useForm()

const errorMessage = ref('')
const loading = ref(true)
const canResetPassword = ref(false)

const { notify } = useNotifications()
const router = useRouter()

onBeforeMount(() => {
  if (!props.token) {
    loading.value = false
    canResetPassword.value = false
    errorMessage.value = __(
      'The token could not be verified. Please contact your administrator.',
    )
    return
  }

  const userSignupVerify = new MutationHandler(
    useUserPasswordResetVerifyMutation({
      variables: { token: props.token },
    }),
    {
      errorShowNotification: false,
    },
  )

  userSignupVerify
    .send()
    .then(() => {
      canResetPassword.value = true
      errorMessage.value = ''
    })
    .catch(() => {
      canResetPassword.value = false
      errorMessage.value = __('The provided token is invalid.')
    })
    .finally(() => {
      loading.value = false
    })
})

const resetPasswordHandler = new MutationHandler(
  useUserPasswordResetUpdateMutation(),
  { errorShowNotification: false },
)

const updatePassword = async (form: FormSubmitData<FormValues>) => {
  await resetPasswordHandler.send({
    token: props.token!,
    password: form.password,
  })

  notify({
    id: 'password-change',
    type: NotificationTypes.Success,
    message: __('Woo hoo! Your password has been changed!'),
  })
  router.replace('/login')
}

const goToLogin = () => {
  router.replace('/login')
}
</script>

<template>
  <LayoutPublicPage box-size="medium" :title="__('Choose your new password')">
    <CommonLoader :loading="loading" :error="errorMessage" />
    <Form
      v-if="canResetPassword"
      id="password-reset-verify"
      ref="form"
      form-class="mb-2.5 grid grid-cols-2 gap-y-2.5 gap-x-3"
      :schema="formSchema"
      @submit="updatePassword($event as FormSubmitData<FormValues>)"
    />

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
        v-if="canResetPassword"
        type="submit"
        variant="submit"
        size="medium"
        form="password-reset-verify"
        :disabled="isDisabled"
      >
        {{ $t('Submit') }}
      </CommonButton>
    </template>
    <template #bottomContent>
      <CommonPublicLinks :screen="EnumPublicLinksScreen.PasswordReset" />
    </template>
  </LayoutPublicPage>
</template>
