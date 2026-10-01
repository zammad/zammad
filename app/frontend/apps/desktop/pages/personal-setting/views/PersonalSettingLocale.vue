<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, reactive, watch } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type {
  FormFieldValue,
  FormSchemaField,
  FormSchemaNode,
} from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useLocaleUpdate } from '#shared/composables/useLocaleUpdate.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { usePersonalSettingTabs } from '../composables/usePersonalSettingTabs.ts'

const { modelCurrentLocale, localeOptions, isSavingLocale, translation } = useLocaleUpdate()

const { breadcrumbItems } = useBreadcrumb()

const { tabs, activeTab } = usePersonalSettingTabs()

const translationStore = useArticleTranslationStore()

// Whether "translate all" is available is only known once the server answered this. Only agents
// may ask, so customers, who see this page too, must not.
if (translationStore.isEnabled && useSessionStore().user?.hasContentTranslationAutoAvailable)
  translationStore.loadTargetLocales()

const { locales, localeData } = storeToRefs(useLocaleStore())

const languageOptions = computed(() => {
  const languageNames = new Intl.DisplayNames([localeData.value?.locale ?? 'en-us'], {
    type: 'language',
    languageDisplay: 'standard',
  })
  const languages = new Set(locales.value?.map((locale) => locale.language))

  return [...languages].map((language) => ({
    label: languageNames.of(language) ?? language,
    value: language,
  }))
})

const { form, updateFieldValues } = useForm()

const translationLinkLabel = __('You can help translating Zammad.')

const schema: FormSchemaNode[] = [
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        type: 'select',
        name: 'locale',
        label: __('User interface language'),
        help: __('Did you know?'),
        sectionsSchema: {
          help: {
            children: [
              '$help',
              ' ',
              {
                $cmp: 'CommonLink',
                props: {
                  link: translation.link,
                  openInNewTab: true,
                  size: 'small',
                },
                children: `$fns.t("${translationLinkLabel}")`,
              },
            ],
          },
        },
        props: {
          clearable: false,
          noOptionsLabelTranslation: true,
          rejectNonExistentValues: false,
          sorting: 'value',
        },
      },
      {
        if: '$isExclusionAvailable',
        type: 'select',
        name: 'excludedLanguages',
        label: __('Languages you understand'),
        help: __(
          'Content written in any of these languages is shown in its original form instead of being automatically translated.',
        ),
        props: {
          clearable: true,
          multiple: true,
          noOptionsLabelTranslation: true,
          rejectNonExistentValues: false,
          sorting: 'label',
        },
      },
    ],
  },
]

const schemaData = reactive({
  isExclusionAvailable: computed(() => translationStore.isExclusionAvailable),
})

const initialFormValues = {
  locale: modelCurrentLocale.value,
  excludedLanguages: translationStore.excludedLanguages,
}

const formChangeFields = computed<Record<string, Partial<FormSchemaField>>>(() => ({
  locale: {
    disabled: isSavingLocale.value,
    props: { options: localeOptions.value },
  },
  // Only computed while the field is shown: the locales are a naming source for it alone.
  ...(translationStore.isExclusionAvailable && {
    excludedLanguages: {
      props: { options: languageOptions.value },
    },
  }),
}))

// Each field saves on its own, so there is no submit. The stores stay the source of truth: a
//   change in a field is written to them, and a change of theirs, e.g. pushed by the server,
//   is written to the field.
const fieldChangeHandlers: Record<string, (value: FormFieldValue) => void> = {
  locale: (locale) => {
    modelCurrentLocale.value = locale as string
  },
  excludedLanguages: (languages) => {
    translationStore.setExcludedLanguages((languages as string[]) ?? [])
  },
}

const onFieldChanged = (name: string, value: FormFieldValue) => fieldChangeHandlers[name]?.(value)

watch(modelCurrentLocale, (locale) => updateFieldValues({ locale }))

watch(
  () => translationStore.excludedLanguages,
  (languages) => updateFieldValues({ excludedLanguages: languages }),
)
</script>

<template>
  <LayoutContent
    :active-tab="activeTab"
    :tabs="tabs"
    :breadcrumb-items="breadcrumbItems"
    width="narrow"
    provide-default
  >
    <div class="mb-4">
      <Form
        id="locale-form"
        ref="form"
        :schema="schema"
        :schema-data="schemaData"
        :initial-values="initialFormValues"
        :change-fields="formChangeFields"
        @changed="onFieldChanged"
      />
    </div>
  </LayoutContent>
</template>
