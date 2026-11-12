<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, markRaw, ref } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import Form from '#shared/components/Form/Form.vue'
import type { FormSchemaNode, FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { i18n } from '#shared/i18n.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useChatPreferencesUpdateMutation } from '#desktop/entities/chat/graphql/mutations/chatPreferencesUpdate.api.ts'
import { useChatAgentStore } from '#desktop/entities/chat/stores/chatAgent.ts'
import { useChatPreferencesStore } from '#desktop/entities/chat/stores/chatPreferences.ts'

import type { ChatSettingsFormData } from './types.ts'

interface Props {
  name: string
}

const props = defineProps<Props>()

const { form } = useForm()

const session = useSessionStore()

const chatPreferences = useChatPreferencesStore()

const { preferences } = storeToRefs(chatPreferences)

const { refetch: refetchPreferences } = chatPreferences

const { refetch: refetchState } = useChatAgentStore()

// The preferences are loaded once for the page and not pushed, and saving writes every field of the
//   form back, so it starts from what is stored now.
const isRefreshed = ref(false)

// A read that failed is no base for the form: it would show what the page loaded earlier and write it back.
const refreshError = ref<string>()

const refresh = async () => {
  refreshError.value = undefined

  const { error } = await refetchPreferences()

  if (error) {
    refreshError.value = __('The chat settings could not be loaded.')
    return
  }

  isRefreshed.value = true
}

refresh()

type Topic = NonNullable<typeof preferences.value>['topics'][number]['topic']

// The topics are the agent's to choose from, so each one brings its own fields.
const activeField = (topic: Topic) => `topic${topic.internalId}Active`

const phrasesField = (topic: Topic) => `topic${topic.internalId}Phrases`

// A line left empty is no greeting.
const cleanPhrases = (value: unknown) =>
  (Array.isArray(value) ? value : []).map((phrase) => String(phrase).trim()).filter(Boolean)

const divider = () => ({ isLayout: true, component: 'CommonDivider', children: '' })

const hasAvatar = computed(() => Boolean(session.user?.image))

const formSchema = computed(() => {
  const placeholder = i18n.t(
    'Hello, my name is %s, what can I do for you?',
    session.user?.firstname ?? '',
  )

  return defineFormSchema([
    {
      name: 'maxWindows',
      label: __('Max. concurrent chats'),
      type: 'number',
      required: true,
      validation: 'between:1,20',
      props: { min: 1, max: 20 },
    },
    {
      name: 'alternativeName',
      label: __('Alternative name'),
      type: 'text',
    },
    {
      isLayout: true,
      element: 'div',
      attrs: { class: 'flex items-center gap-3' },
      children: [
        ...(session.user && hasAvatar.value
          ? [
              {
                isLayout: true,
                component: 'CommonUserAvatar',
                props: { entity: session.user, size: 'normal', personal: true },
                children: '',
              },
            ]
          : []),
        {
          name: 'avatarEnabled',
          label: __('Avatar'),
          type: 'toggle',
          disabled: !hasAvatar.value,
          help: hasAvatar.value
            ? undefined
            : __('No avatar image yet. Upload one in your personal settings.'),
          props: { variants: { true: 'True', false: 'False' } },
        },
      ],
    },
    {
      isLayout: true,
      element: 'div',
      attrs: { class: 'flex flex-col gap-3' },
      children: [
        {
          isLayout: true,
          component: 'CommonLabel',
          children: i18n.t('Topics'),
        },
        divider(),
        // The topics sit closer together than the heading and its line, as drawn.
        {
          isLayout: true,
          element: 'div',
          attrs: { class: 'flex flex-col gap-2' },
          children: (preferences.value?.topics ?? []).flatMap(({ topic }, index) => {
            const fields: FormSchemaNode[] = [
              {
                name: activeField(topic),
                label: topic.name,
                type: 'toggle',
                props: { variants: { true: 'True', false: 'False' } },
              },
              {
                name: phrasesField(topic),
                label: __('Welcome messages'),
                type: 'textList',
                props: {
                  description: __('One of them is sent at random when you accept a chat.'),
                  emptyLabel: __('No welcome messages added yet.'),
                  itemLabel: __('Welcome message'),
                  itemPlaceholder: placeholder,
                  addLabel: __('Add welcome message'),
                  editLabel: __('Edit welcome message'),
                  removeLabel: __('Remove welcome message'),
                },
              },
            ]

            // A line between the topics, none before the first: the section's own line is there.
            if (index > 0) fields.unshift(divider())

            return fields
          }),
        },
      ],
    },
  ])
})

const initialEntityObject = computed(() => {
  if (!preferences.value) return undefined

  const { maxWindows, alternativeName, avatarEnabled, topics } = preferences.value

  return {
    maxWindows,
    alternativeName: alternativeName ?? '',
    avatarEnabled: avatarEnabled && hasAvatar.value,
    ...Object.fromEntries(
      topics.flatMap(({ topic, active, phrases }) => [
        [activeField(topic), active],
        [phrasesField(topic), phrases],
      ]),
    ),
  }
})

const updateMutation = new MutationHandler(useChatPreferencesUpdateMutation())

const submitForm = async (data: FormSubmitData<ChatSettingsFormData>) => {
  const topics = (preferences.value?.topics ?? []).map(({ topic }) => ({
    topicId: topic.id,
    active: Boolean(data[activeField(topic)]),
    phrases: cleanPhrases(data[phrasesField(topic)]),
  }))

  await updateMutation.send({
    preferences: {
      maxWindows: Number(data.maxWindows),
      alternativeName: String(data.alternativeName ?? ''),
      avatarEnabled: Boolean(data.avatarEnabled),
      topics,
    },
  })

  // The preferences are not pushed. The state is, also when the server switched the agent off for
  //   having no topic left, but the page should not wait for it.
  await Promise.all([refetchPreferences(), refetchState()])

  closeFlyout(props.name)
}
</script>

<template>
  <CommonFlyout
    :name="name"
    header-icon="chat"
    :header-title="__('Chat settings')"
    :form="form"
    :hide-footer="Boolean(refreshError)"
    no-close-on-action
    :footer-action-options="{
      actionLabel: __('Submit'),
      actionButton: {
        type: 'submit',
      },
    }"
  >
    <CommonLoader :loading="!isRefreshed && !refreshError" :error="refreshError">
      <!-- The loader fades between its states, which needs a single element: the form renders several. -->
      <div v-if="initialEntityObject">
        <Form
          id="form-chat-settings"
          ref="form"
          form-class="flex flex-col gap-6"
          should-autofocus
          :schema="formSchema"
          :schema-component-library="{
            CommonUserAvatar: markRaw(CommonUserAvatar),
            CommonDivider: markRaw(CommonDivider),
          }"
          :initial-entity-object="initialEntityObject"
          @submit="submitForm($event as FormSubmitData<ChatSettingsFormData>)"
        />
      </div>
    </CommonLoader>

    <CommonButton
      v-if="refreshError"
      class="mt-3"
      variant="secondary"
      size="medium"
      @click="refresh"
    >
      {{ $t('Try again') }}
    </CommonButton>
  </CommonFlyout>
</template>
