<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, reactive } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type {
  FormSchemaNode,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import type { TicketArticleTimeAccountingFormData } from '#shared/entities/ticket/types.ts'
import { EnumFormUpdaterId } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import type { ActionFooterOptions } from '#desktop/components/CommonFlyout/types.ts'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

import type { FormKitNode } from '@formkit/core'

const emit = defineEmits<{
  'account-time': [TicketArticleTimeAccountingFormData]
  skip: []
}>()

const { form } = useForm()

const flyoutName = 'ticket-time-accounting'

const submitForm = (
  formData: FormSubmitData<TicketArticleTimeAccountingFormData>,
) => {
  if (formData.time_unit) {
    formData.time_unit = formData.time_unit.replace(',', '.')
  }
  emit('account-time', formData)
  closeFlyout(flyoutName)
}

const onClose = (isCancel?: boolean) => {
  if (!isCancel) return
  emit('skip')
}

const { config } = useApplicationStore()

const timeAccountingUnit = computed(() => {
  switch (config.time_accounting_unit) {
    case 'hour':
      return __('hour(s)')
    case 'quarter':
      return __('quarter-hour(s)')
    case 'minute':
      return __('minute(s)')
    case 'custom': {
      if (config.time_accounting_unit_custom)
        return config.time_accounting_unit_custom
      return null
    }
    default:
      return null
  }
})

const validationRuleTimeAccountingUnit = (node: FormKitNode<string>) => {
  if (!node.value) return false
  return !Number.isNaN(+node.value.replace(',', '.'))
}

const formSchema = [
  {
    isLayout: true,
    component: 'FormGroup',
    props: {
      class: '@container/form-group',
    },
    children: [
      {
        id: 'timeUnit',
        name: 'time_unit',
        label: __('Accounted Time'),
        type: 'text',
        required: true,
        placeholder: __('Enter the time you want to record'),
        validation: 'validationRuleTimeAccountingUnit',
        validationRules: {
          validationRuleTimeAccountingUnit,
        },
        validationMessages: {
          validationRuleTimeAccountingUnit: __(
            'This field must contain a number.',
          ),
        },
        ...(timeAccountingUnit.value
          ? {
              sectionsSchema: {
                suffix: {
                  // FIXME: Not working.
                  // if: '$timeAccountingUnit',
                  // children: '$timeAccountingUnit',
                  $el: 'span',
                  children: i18n.t(timeAccountingUnit.value || ''),
                  attrs: {
                    class:
                      'py-2.5 px-2.5 outline outline-1 -outline-offset-1 outline-blue-200 dark:outline-gray-700 bg-neutral-50 dark:bg-gray-500 rounded-e-md text-gray-100 dark:text-neutral-400',
                  },
                },
              },
            }
          : {}),
      },
      {
        if: '$timeAccountingTypes === true',
        id: 'accountedTimeTypeId',
        name: 'accounted_time_type_id',
        label: __('Activity Type'),
        type: 'select',
        props: {
          clearable: true,
        },
      },
    ],
  },
] as FormSchemaNode[]

const timeAccountingTypes = computed(() => config.time_accounting_types)

const schemaData = reactive({
  // timeAccountingUnit,
  timeAccountingTypes,
})

const footerActionOptions = computed<ActionFooterOptions>(() => ({
  actionLabel: __('Account Time'),
  actionButton: { variant: 'submit', type: 'submit' },
  cancelLabel: __('Skip'),
}))
</script>

<template>
  <CommonFlyout
    :header-title="__('Time Accounting')"
    :form="form"
    :footer-action-options="footerActionOptions"
    header-icon="stopwatch"
    :name="flyoutName"
    no-close-on-action
    @close="onClose"
  >
    <div class="flex flex-col gap-3">
      <Form
        id="form-ticket-time-accounting"
        ref="form"
        :schema="formSchema"
        :schema-data="schemaData"
        should-autofocus
        :form-updater-id="
          EnumFormUpdaterId.FormUpdaterUpdaterTicketTimeAccounting
        "
        form-updater-initial-only
        @submit="
          submitForm(
            $event as FormSubmitData<TicketArticleTimeAccountingFormData>,
          )
        "
      />
    </div>
  </CommonFlyout>
</template>
