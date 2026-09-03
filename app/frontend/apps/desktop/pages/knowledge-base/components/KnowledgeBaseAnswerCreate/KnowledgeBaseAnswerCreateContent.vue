<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, markRaw, Teleport, toRef, useTemplateRef, type Component } from 'vue'
import { useRoute } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import {
  EnumFormUpdaterId,
  EnumKnowledgeBaseAnswerScreen,
  type EnumKnowledgeBaseVisibility,
} from '#shared/graphql/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { SidebarName } from '#desktop/components/layout/types.ts'
import { usePage } from '#desktop/composables/usePage.ts'
import { useScrollPosition } from '#desktop/composables/useScrollPosition.ts'
import { useAnswerFormSchema } from '#desktop/entities/knowledge-base/composables/useAnswerFormSchema.ts'
import { useKnowledgeBaseAnswerCreate } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerCreate.ts'
import type { KnowledgeBaseAnswerCreateFormData } from '#desktop/entities/knowledge-base/types.ts'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import { useTaskbarTabContext } from '#desktop/entities/user/current/composables/useTaskbarTabContext.ts'
import { useTaskbarTabDiscard } from '#desktop/entities/user/current/composables/useTaskbarTabDiscard.ts'
import { useTaskbarTabStateUpdates } from '#desktop/entities/user/current/composables/useTaskbarTabStateUpdates.ts'

import KnowledgeBaseAnswerSidebar from '../KnowledgeBaseAnswer/KnowledgeBaseAnswerSidebar/KnowledgeBaseAnswerSidebar.vue'
import KnowledgeBaseAnswerScreenBehavior from '../KnowledgeBaseAnswerScreenBehavior/KnowledgeBaseAnswerScreenBehavior.vue'
import { useKnowledgeBaseAnswerScreenBehavior } from '../KnowledgeBaseAnswerScreenBehavior/useKnowledgeBaseAnswerScreenBehavior.ts'
import { FORM_COLUMN_CLASS } from '../KnowledgeBaseTopBarHeader/headerClasses.ts'

import KnowledgeBaseAnswerCreateHeader from './KnowledgeBaseAnswerCreateHeader.vue'

interface Props {
  localeCode: string
  tabId: string
}

const props = defineProps<Props>()

const route = useRoute()

const contentContainerElement = useTemplateRef('content-container')

const { form, formNodeId, isDirty, isDisabled, isInitialSettled, values, triggerFormUpdater } =
  useForm()

// Bare id, not a CSS selector: it doubles as the target `<div>`'s `id` attribute in the header's
//   own template (KnowledgeBaseAnswerCreateHeader.vue), so the `#` is added only below, where the
//   schema needs an actual selector.
const TITLE_FIELD_TARGET_ID = 'knowledgeBaseAnswerCreateTitleField'

// Written once for the same reason, and used the same two ways - as the container's `id` in this
//   view's own sidebar below, and as the schema's selector.
const SIDEBAR_FIELDS_TARGET_ID = 'knowledgeBaseAnswerCreateSidebarFields'

// Shared with the edit form (useAnswerFormSchema.ts), which is also where the comments explaining
//   this shape live: the content/sidebar split via `Teleport`, and why every field triggers the
//   form updater.
const formSchema = useAnswerFormSchema({
  titleFieldTarget: `#${TITLE_FIELD_TARGET_ID}`,
  sidebarFieldsTarget: `#${SIDEBAR_FIELDS_TARGET_ID}`,
  // Which brings the tags field along. The visibility field is in both forms; what this one has
  //   no part of is scheduling a state for later, which is the edit sidebar's own widget.
  edit: false,
})

// The category the draft goes into. Until the form has answered, the seed the view was opened
//   with is all there is, and rendering the breadcrumb from it beats waiting for the round trip.
//
// Afterwards the field decides — including when it is *empty*. The updater drops a category the
//   editor may no longer write to, and falling back to the seed then would point the header's
//   query at a forbidden category, whose Forbidden handler redirects the whole view to
//   not-found: the editor could not even reopen the draft to move it somewhere they may write.
//
// An internal id either way, but the field's option values are numbers while the route carries
//   text - so the header sees one type.
const categoryId = computed(() => {
  const selectedCategoryId = (
    isInitialSettled.value
      ? values.value.categoryId
      : (values.value.categoryId ?? route.query.categoryId)
  ) as string | number | undefined

  return selectedCategoryId ? String(selectedCategoryId) : undefined
})

const currentTitle = computed(() => values.value.title as string | undefined)

usePage({
  metaTitle: computed(() => currentTitle.value || __('New knowledge base answer')),
})

useScrollPosition(contentContainerElement)

// Live, for the header's badge row: a draft has no stored answer for it to read instead, unlike
//   the edit header's. Undefined until the first form updater round trip has resolved a value, so
//   the header shows no badge rather than one for a state nothing has picked yet.
const visibility = computed(() =>
  isInitialSettled.value ? (values.value.visibility as EnumKnowledgeBaseVisibility) : undefined,
)

// What the taskbar tab renders itself from, so the tab title follows the title being typed
//   before anything is stored.
const tabContext = useTaskbarTabContext(
  () => ({
    formValues: values.value,
    formIsDirty: isDirty.value,
  }),
  isInitialSettled,
)

const { currentTaskbarTab, currentTaskbarTabId, currentTaskbarTabFormId, currentTaskbarTabDelete } =
  useTaskbarTab(tabContext)

// **This is the auto-save.** The form updater writes every resolved value into the taskbar state
//   on each round trip, and plays it back when the tab is reopened - but only when it is told
//   which taskbar to store into. Without `taskbarId` the backend's StoresTaskbarState does
//   nothing and no draft is kept.
//
// The rest of the query travels along for the same reason ticket create does it: `categoryId`
//   arrives that way and preselects the category of the browse page the draft was started from.
const formUpdaterAdditionalParams = computed(() => ({
  // `categoryId` rides the query when the draft is started from a category, and is only ever a
  //   *seed*: the auto-save owns the live value from the first round trip on, and a stored draft
  //   value wins over it (`value ?? initialValue` while the form initializes, see Form.vue).
  ...route.query,
  taskbarId: currentTaskbarTab.value?.taskbarTabId,
  // The locale of the draft, so the category options read in the language the answer is written
  //   in rather than in the editor's profile language. A route param, so it does not come along
  //   with the query below.
  locale: props.localeCode,
}))

// Another session of the same user editing this draft: pull its changes in instead of letting the
//   two overwrite each other.
useTaskbarTabStateUpdates(currentTaskbarTabId, form, triggerFormUpdater)

const { goBack, discardChanges } = useTaskbarTabDiscard(currentTaskbarTabDelete)

const { createAnswer } = useKnowledgeBaseAnswerCreate()

// What happens once the answer is created - the same control the edit view carries, per the story's
//   acceptance criteria, with a preference of its own and one option of its own: adding another
//   answer, which is this tab closing and a fresh form opening in the same category.
const { handleScreenBehavior } = useKnowledgeBaseAnswerScreenBehavior({
  currentTaskbarTabId,
  localeCode: toRef(props, 'localeCode'),
  screen: EnumKnowledgeBaseAnswerScreen.Create,
})

// The draft's tab goes only after the answer exists: a failed create has to keep it, or the work
//   is gone. Its files are already the answer's by then, so the tab has nothing left to carry -
//   and closing it is `handleScreenBehavior`'s job, whichever of its destinations it leaves for,
//   the fresh form for the next answer included.
const submitCreateAnswer = async (data: FormSubmitData<KnowledgeBaseAnswerCreateFormData>) => {
  const answer = await createAnswer(
    { ...data, locale: props.localeCode },
    form.value?.formId ?? undefined,
  )

  if (!answer) return

  await handleScreenBehavior(answer)
}
</script>

<template>
  <LayoutContent
    name="knowledge-base-answer-create"
    background-variant="primary"
    content-alignment="center"
    show-sidebar
    :sidebar-name="SidebarName.KnowledgeBaseAnswerCreate"
    no-scrollable
    no-padding
  >
    <div
      ref="content-container"
      class="@container flex size-full flex-col items-center overflow-y-auto"
    >
      <KnowledgeBaseAnswerCreateHeader
        :content-container-element="contentContainerElement"
        :category-id="categoryId"
        :title="currentTitle"
        :title-field-target="TITLE_FIELD_TARGET_ID"
        :visibility="visibility"
      />

      <div class="w-full shrink-0 py-7.5" :class="FORM_COLUMN_CLASS">
        <Form
          id="knowledge-base-answer-create"
          ref="form"
          :key="tabId"
          :form-id="currentTaskbarTabFormId"
          :schema="formSchema"
          :schema-component-library="{ Teleport: markRaw(Teleport) as unknown as Component }"
          :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterKnowledgeBaseAnswerCreate"
          :form-updater-additional-params="formUpdaterAdditionalParams"
          form-class="flex flex-col gap-3"
          @submit="submitCreateAnswer($event as FormSubmitData<KnowledgeBaseAnswerCreateFormData>)"
        />
      </div>
    </div>

    <template #sideBar>
      <!-- The reader's shell, with its title and icon: switching from creating an answer to
           reading one must not move the sidebar around. No action menu - there is no stored
           answer to act on yet. -->
      <KnowledgeBaseAnswerSidebar
        :name="SidebarName.KnowledgeBaseAnswerCreate"
        :title="__('Knowledge base answer')"
        icon="file-richtext"
      >
        <!-- Teleported nodes escape the loading gate the form applies to its own wrapper, so
             without this the sidebar would show an empty radio list and an option-less category
             field while the content column is still blank. `v-show`, like the sidebar's own
             collapsing: the teleport target has to stay mounted. -->
        <div v-show="isInitialSettled" :id="SIDEBAR_FIELDS_TARGET_ID" class="p-3" />
      </KnowledgeBaseAnswerSidebar>
    </template>

    <template #bottomBar>
      <template v-if="isInitialSettled">
        <CommonButton
          v-if="isDirty"
          size="large"
          variant="danger"
          :disabled="isDisabled"
          @click="discardChanges"
        >
          {{ $t('Discard changes') }}
        </CommonButton>
        <CommonButton v-else size="large" variant="secondary" @click="goBack">
          {{ $t('Cancel & go back') }}
        </CommonButton>
      </template>

      <!-- The same control the edit view carries, with a preference and a "stay" of its own. -->
      <KnowledgeBaseAnswerScreenBehavior :screen="EnumKnowledgeBaseAnswerScreen.Create" />

      <CommonButton
        size="large"
        variant="submit"
        type="submit"
        :form="formNodeId"
        :disabled="isDisabled"
      >
        {{ $t('Create') }}
      </CommonButton>
    </template>
  </LayoutContent>
</template>
