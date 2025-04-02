<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed, reactive, ref, watch } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type {
  FormSchemaNode,
  FormValues,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useMultiStepForm } from '#shared/components/Form/useMultiStepForm.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonInputCopyToClipboard from '#desktop/components/CommonInputCopyToClipboard/CommonInputCopyToClipboard.vue'
import CommonTabGroup from '#desktop/components/CommonTabGroup/CommonTabGroup.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { useUserCurrentCalendarSubscriptionUpdateMutation } from '../graphql/mutations/userCurrentCalendarSubscriptionUpdate.api.ts'
import { useUserCurrentCalendarSubscriptionListQuery } from '../graphql/queries/userCurrentCalendarSubscriptionList.api.ts'

const { breadcrumbItems } = useBreadcrumb(__('Calendar'))

const { form, isDirty, node, formReset, formSubmit, values } = useForm()

const { multiStepPlugin, allSteps, activeStep } = useMultiStepForm(node)

const getFormSchemaGroupSection = (
  stepName: string,
  children: FormSchemaNode[],
) => {
  return {
    isLayout: true,
    element: 'section',
    attrs: {
      style: {
        if: `$activeStep !== "${stepName}"`,
        then: 'display: none;',
      },
    },
    children: [
      {
        type: 'group',
        name: stepName,
        isGroupOrList: true,
        plugins: [multiStepPlugin],
        children,
      },
    ],
  }
}

const escalationSection = getFormSchemaGroupSection('escalation', [
  {
    name: 'escalationOwn',
    type: 'toggle',
    label: __('My tickets'),
    help: __('Include your own tickets in subscription for escalated tickets.'),
    props: {
      variants: {
        true: 'yes',
        false: 'no',
      },
    },
  },
  {
    name: 'escalationNotAssigned',
    type: 'toggle',
    label: __('Not assigned'),
    help: __(
      'Include unassigned tickets in subscription for escalated tickets.',
    ),
    props: {
      variants: {
        true: 'yes',
        false: 'no',
      },
    },
  },
])

const newOpenSection = getFormSchemaGroupSection('newOpen', [
  {
    name: 'newOpenOwn',
    type: 'toggle',
    label: __('My tickets'),
    help: __(
      'Include your own tickets in subscription for new & open tickets.',
    ),
    props: {
      variants: {
        true: 'yes',
        false: 'no',
      },
    },
  },
  {
    name: 'newOpenNotAssigned',
    type: 'toggle',
    label: __('Not assigned'),
    help: __(
      'Include unassigned tickets in subscription for new & open tickets.',
    ),
    props: {
      variants: {
        true: 'yes',
        false: 'no',
      },
    },
  },
])

const pendingSection = getFormSchemaGroupSection('pending', [
  {
    name: 'pendingOwn',
    type: 'toggle',
    label: __('My tickets'),
    help: __('Include your own tickets in subscription for pending tickets.'),
    props: {
      variants: {
        true: 'yes',
        false: 'no',
      },
    },
  },
  {
    name: 'pendingNotAssigned',
    type: 'toggle',
    label: __('Not assigned'),
    help: __('Include unassigned tickets in subscription for pending tickets.'),
    props: {
      variants: {
        true: 'yes',
        false: 'no',
      },
    },
  },
])

const formSchema = defineFormSchema([
  escalationSection,
  newOpenSection,
  pendingSection,
])

const schemaData = reactive({
  activeStep,
})

const calendarSubscriptionListQuery = new QueryHandler(
  useUserCurrentCalendarSubscriptionListQuery(),
)

const calendarSubscriptionListQueryResult =
  calendarSubscriptionListQuery.result()

const { user } = storeToRefs(useSessionStore())

// Refetch calendar subscription list query when the user preference has changed.
watch(
  () => user.value?.preferences?.calendar_subscriptions,
  () => {
    calendarSubscriptionListQuery.refetch()
  },
  { deep: true },
)

const combinedSubscriptionURL = computed(
  () =>
    calendarSubscriptionListQueryResult.value
      ?.userCurrentCalendarSubscriptionList.combinedUrl ?? '',
)

// Alarm is a global option and therefore hoisted out of the multi-step form.
//   Here we keep track of its value from the query, and update it whenever is mutated from outside.
const alarm = computed(() =>
  Boolean(
    calendarSubscriptionListQueryResult.value
      ?.userCurrentCalendarSubscriptionList.globalOptions?.alarm,
  ),
)

const alarmLocalValue = ref(alarm.value)

watch(alarm, (newValue) => {
  alarmLocalValue.value = newValue
})

const directSubscriptionURL = computed(
  () =>
    calendarSubscriptionListQueryResult.value
      ?.userCurrentCalendarSubscriptionList[
      activeStep.value as 'escalation' | 'newOpen' | 'pending'
    ]?.url ?? '',
)

const formInitialValues = computed<FormValues>((oldValues) => {
  const values = {
    escalationOwn:
      calendarSubscriptionListQueryResult.value
        ?.userCurrentCalendarSubscriptionList.escalation?.options?.own,
    escalationNotAssigned:
      calendarSubscriptionListQueryResult.value
        ?.userCurrentCalendarSubscriptionList.escalation?.options?.notAssigned,
    newOpenOwn:
      calendarSubscriptionListQueryResult.value
        ?.userCurrentCalendarSubscriptionList.newOpen?.options?.own,
    newOpenNotAssigned:
      calendarSubscriptionListQueryResult.value
        ?.userCurrentCalendarSubscriptionList.newOpen?.options?.notAssigned,
    pendingOwn:
      calendarSubscriptionListQueryResult.value
        ?.userCurrentCalendarSubscriptionList.pending?.options?.own,
    pendingNotAssigned:
      calendarSubscriptionListQueryResult.value
        ?.userCurrentCalendarSubscriptionList.pending?.options?.notAssigned,
  } as unknown as FormValues

  if (oldValues && isEqual(values, oldValues)) return oldValues

  return values
})

watch(formInitialValues, (newValues) => {
  // No reset needed when the form has already the correct state.
  if (isEqual(values.value, newValues) && !isDirty.value) return

  formReset({ values: newValues })
})

const { notify } = useNotifications()

const submitForm = async (data: FormValues) => {
  const input = {
    alarm: alarmLocalValue.value,
    escalation: {
      own: Boolean(data.escalationOwn),
      notAssigned: Boolean(data.escalationNotAssigned),
    },
    newOpen: {
      own: Boolean(data.newOpenOwn),
      notAssigned: Boolean(data.newOpenNotAssigned),
    },
    pending: {
      own: Boolean(data.pendingOwn),
      notAssigned: Boolean(data.pendingNotAssigned),
    },
  }

  const calendarSubscriptionUpdateMutation = new MutationHandler(
    useUserCurrentCalendarSubscriptionUpdateMutation(),
    {
      errorNotificationMessage: __(
        'Updating your calendar subscription settings failed.',
      ),
    },
  )

  return calendarSubscriptionUpdateMutation.send({ input }).then(() => {
    notify({
      id: 'calendar-subscription-update-success',
      type: NotificationTypes.Success,
      message: __('You calendar subscription settings were updated.'),
    })
  })
}

const tabs = [
  {
    label: __('Escalated Tickets'),
    key: 'escalation',
  },
  {
    label: __('New & Open Tickets'),
    key: 'newOpen',
  },
  {
    label: __('Pending Tickets'),
    key: 'pending',
  },
]
</script>

<template>
  <LayoutContent
    :breadcrumb-items="breadcrumbItems"
    :help-text="
      $t(
        'See your tickets from within your favorite calendar by adding the subscription URL to your calendar app.',
      )
    "
    width="narrow"
  >
    <div class="mb-4">
      <CommonInputCopyToClipboard
        :label="__('Combined subscription URL')"
        :copy-button-text="__('Copy URL')"
        :value="combinedSubscriptionURL"
        :help="__('Includes escalated, new & open and pending tickets.')"
      />

      <FormKit
        v-model="alarmLocalValue"
        type="toggle"
        :label="__('Add alarm to pending reminder and escalated tickets')"
        :variants="{ true: 'yes', false: 'no' }"
        @update:model-value="formSubmit"
      />

      <CommonLabel role="heading" aria-level="2" class="mt-5 mb-2" size="large">
        {{ $t('Subscription settings') }}
      </CommonLabel>

      <CommonTabGroup v-model="activeStep" class="mb-3" :tabs="tabs" />

      <div
        :id="`tab-panel-${activeStep}`"
        role="tabpanel"
        :aria-labelledby="`tab-label-${activeStep}`"
      >
        <CommonInputCopyToClipboard
          :label="__('Direct subscription URL')"
          :copy-button-text="__('Copy URL')"
          :value="directSubscriptionURL"
        />

        <Form
          id="calendar-subscription"
          ref="form"
          :schema="formSchema"
          :flatten-form-groups="Object.keys(allSteps)"
          :initial-values="formInitialValues"
          :schema-data="schemaData"
          @changed="formSubmit"
          @submit="submitForm"
        />
      </div>
    </div>
  </LayoutContent>
</template>
