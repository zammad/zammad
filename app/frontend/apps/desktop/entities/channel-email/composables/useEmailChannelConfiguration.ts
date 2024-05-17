// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, watch } from 'vue'

import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import UserError from '#shared/errors/UserError.ts'
import type {
  ChannelEmailInboundConfiguration,
  ChannelEmailOutboundConfiguration,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import type { MutationSendError } from '#shared/types/error.ts'

import { useChannelEmailAddMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailAdd.api.ts'
import { useChannelEmailValidateConfigurationRoundtripMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailValidateConfigurationRoundtrip.api.ts'

import { useChannelEmailGuessConfigurationMutation } from '../graphql/mutations/channelEmailGuessConfiguration.api.ts'
import { useChannelEmailValidateConfigurationInboundMutation } from '../graphql/mutations/channelEmailValidateConfigurationInbound.api.ts'
import { useChannelEmailValidateConfigurationOutboundMutation } from '../graphql/mutations/channelEmailValidateConfigurationOutbound.api.ts'

import type { EmailAccountData } from '../types/email-account.ts'
import type {
  EmailChannelSteps,
  EmailChannelForms,
} from '../types/email-channel.ts'
import type {
  UpdateMetaInformationInboundFunction,
  EmailInboundMetaInformation,
  EmailOutboundData,
  EmailInboundData,
  EmailInboundMessagesData,
} from '../types/email-inbound-outbound.ts'
import type { SetNonNullable, SetOptional } from 'type-fest'
import type { Ref } from 'vue'

export const useEmailChannelConfiguration = (
  emailChannelForms: EmailChannelForms,
  metaInformationInbound: Ref<Maybe<EmailInboundMetaInformation>>,
  updateMetaInformationInbound: UpdateMetaInformationInboundFunction,
  onSuccessCallback: () => void,
) => {
  const { loading, debouncedLoading } = useDebouncedLoading()
  const activeStep = ref<EmailChannelSteps>('account')
  const pendingActiveStep = ref<Maybe<EmailChannelSteps>>(null)

  const setActiveStep = (nextStep: EmailChannelSteps) => {
    if (!debouncedLoading.value) {
      activeStep.value = nextStep
      return
    }

    pendingActiveStep.value = nextStep
  }

  watch(debouncedLoading, (newValue: boolean) => {
    if (!newValue && pendingActiveStep.value) {
      activeStep.value = pendingActiveStep.value
      pendingActiveStep.value = null
    }
  })

  const stepTitle = computed(() => {
    switch (activeStep.value) {
      case 'inbound':
      case 'inbound-messages':
        return __('Email Inbound')
      case 'outbound':
        return __('Email Outbound')
      default:
        return __('Email Account')
    }
  })

  const activeForm = computed(() => {
    switch (activeStep.value) {
      case 'inbound':
        return emailChannelForms.emailInbound.form.value
      case 'inbound-messages':
        return emailChannelForms.emailInboundMessages.form.value
      case 'outbound':
        return emailChannelForms.emailOutbound.form.value
      default:
        return emailChannelForms.emailAccount.form.value
    }
  })

  const validateConfigurationRoundtripAndChannelAdd = async (
    account: EmailAccountData,
    inboundConfiguration: EmailInboundData,
    outboundConfiguration: EmailOutboundData,
  ) => {
    const validateConfigurationRoundtripMutation = new MutationHandler(
      useChannelEmailValidateConfigurationRoundtripMutation(),
    )
    const addEmailChannelMutation = new MutationHandler(
      useChannelEmailAddMutation(),
    )

    // Transform port field to real number for usage in the mutation.
    inboundConfiguration.port = Number(inboundConfiguration.port)
    outboundConfiguration.port = Number(outboundConfiguration.port)

    // Extend inbound configuration with archive information when needed.
    if (metaInformationInbound.value?.archive) {
      inboundConfiguration = {
        ...inboundConfiguration,
        archive: true,
        archiveBefore: metaInformationInbound.value.archiveBefore,
      }
    }

    try {
      const roundTripResult = await validateConfigurationRoundtripMutation.send(
        {
          inboundConfiguration,
          outboundConfiguration,
          emailAddress: account.email,
        },
      )

      if (
        roundTripResult?.channelEmailValidateConfigurationRoundtrip?.success
      ) {
        try {
          const addChannelResult = await addEmailChannelMutation.send({
            input: {
              inboundConfiguration,
              outboundConfiguration,
              emailAddress: account.email,
              emailRealname: account.realname,
            },
          })

          if (addChannelResult?.channelEmailAdd?.channel) {
            onSuccessCallback()
          }
        } catch (errors) {
          emailChannelForms.emailAccount.setErrors(errors as MutationSendError)
          setActiveStep('account')
        }
      }
    } catch (errors) {
      if (
        errors instanceof UserError &&
        Object.keys(errors.getFieldErrorList()).length > 0
      ) {
        if (
          Object.keys(errors.getFieldErrorList()).some((key) =>
            key.startsWith('outbound'),
          )
        ) {
          setActiveStep('outbound')
          emailChannelForms.emailOutbound.setErrors(errors as MutationSendError)
        } else {
          setActiveStep('inbound')
          emailChannelForms.emailInbound.setErrors(errors as MutationSendError)
        }
        return
      }

      emailChannelForms.emailAccount.setErrors(
        new UserError([
          {
            message: i18n.t(
              'Email sending and receiving could not be verified. Please check your settings.',
            ),
          },
        ]),
      )
      setActiveStep('account')
    }
  }

  const guessEmailAccount = (data: FormSubmitData<EmailAccountData>) => {
    loading.value = true

    const guessConfigurationMutation = new MutationHandler(
      useChannelEmailGuessConfigurationMutation(),
    )

    return guessConfigurationMutation
      .send({
        emailAddress: data.email,
        password: data.password,
      })
      .then(async (result) => {
        if (
          result?.channelEmailGuessConfiguration?.result.inboundConfiguration &&
          result?.channelEmailGuessConfiguration?.result.outboundConfiguration
        ) {
          const inboundConfiguration = result.channelEmailGuessConfiguration
            .result.inboundConfiguration as SetOptional<
            SetNonNullable<Required<ChannelEmailInboundConfiguration>>,
            '__typename'
          >
          delete inboundConfiguration.__typename

          const outboundConfiguration = result.channelEmailGuessConfiguration
            .result.outboundConfiguration as SetOptional<
            SetNonNullable<Required<ChannelEmailOutboundConfiguration>>,
            '__typename'
          >
          delete outboundConfiguration.__typename

          emailChannelForms.emailInbound.updateFieldValues(inboundConfiguration)
          emailChannelForms.emailOutbound.updateFieldValues(
            outboundConfiguration,
          )

          const mailboxStats =
            result?.channelEmailGuessConfiguration?.result.mailboxStats

          if (
            mailboxStats?.contentMessages &&
            mailboxStats?.contentMessages > 0
          ) {
            updateMetaInformationInbound(mailboxStats, 'roundtrip')
            setActiveStep('inbound-messages')
            return
          }

          await validateConfigurationRoundtripAndChannelAdd(
            data,
            inboundConfiguration,
            outboundConfiguration,
          )
        } else {
          emailChannelForms.emailInbound.updateFieldValues({
            user: data.email,
            password: data.password,
          })
          emailChannelForms.emailOutbound.updateFieldValues({
            user: data.email,
            password: data.password,
          })

          emailChannelForms.emailInbound.setErrors(
            new UserError([
              {
                message: i18n.t(
                  'The server settings could not be automatically detected. Please configure them manually.',
                ),
              },
            ]),
          )

          setActiveStep('inbound')
        }
      })
      .finally(() => {
        loading.value = false
      })
  }

  const validateEmailInbound = (data: FormSubmitData<EmailInboundData>) => {
    loading.value = true

    const validationConfigurationInbound = new MutationHandler(
      useChannelEmailValidateConfigurationInboundMutation(),
    )

    return validationConfigurationInbound
      .send({
        inboundConfiguration: {
          ...data,
          port: Number(data.port),
        },
      })
      .then((result) => {
        if (result?.channelEmailValidateConfigurationInbound?.success) {
          emailChannelForms.emailOutbound.updateFieldValues({
            host: data.host,
            user: data.user,
            password: data.password,
          })

          const mailboxStats =
            result?.channelEmailValidateConfigurationInbound?.mailboxStats

          if (
            mailboxStats?.contentMessages &&
            mailboxStats?.contentMessages > 0 &&
            !data.keepOnServer
          ) {
            updateMetaInformationInbound(mailboxStats, 'outbound')
            setActiveStep('inbound-messages')
            return
          }

          setActiveStep('outbound')
        }
      })
      .finally(() => {
        loading.value = false
      })
  }

  const importEmailInboundMessages = async (
    data: FormSubmitData<EmailInboundMessagesData>,
  ) => {
    if (metaInformationInbound.value && data.archive) {
      metaInformationInbound.value.archive = true
      metaInformationInbound.value.archiveBefore = new Date().toISOString()
    }

    if (metaInformationInbound.value?.nextAction === 'outbound') {
      setActiveStep('outbound')
    }

    if (metaInformationInbound.value?.nextAction === 'roundtrip') {
      loading.value = true

      await validateConfigurationRoundtripAndChannelAdd(
        emailChannelForms.emailAccount.values.value,
        emailChannelForms.emailInbound.values.value,
        emailChannelForms.emailOutbound.values.value,
      )

      loading.value = false
    }
  }

  const validateEmailOutbound = (data: FormSubmitData<EmailOutboundData>) => {
    loading.value = true

    const validationConfigurationOutbound = new MutationHandler(
      useChannelEmailValidateConfigurationOutboundMutation(),
    )

    return validationConfigurationOutbound
      .send({
        outboundConfiguration: {
          ...data,
          port: Number(data.port),
        },
        emailAddress: emailChannelForms.emailAccount.values.value
          ?.email as string,
      })
      .then(async (result) => {
        if (result?.channelEmailValidateConfigurationOutbound?.success) {
          await validateConfigurationRoundtripAndChannelAdd(
            emailChannelForms.emailAccount.values.value,
            emailChannelForms.emailInbound.values.value,
            emailChannelForms.emailOutbound.values.value,
          )
        }
      })
      .finally(() => {
        loading.value = false
      })
  }

  return {
    debouncedLoading,
    stepTitle,
    activeStep,
    activeForm,
    guessEmailAccount,
    validateEmailInbound,
    importEmailInboundMessages,
    validateEmailOutbound,
  }
}
