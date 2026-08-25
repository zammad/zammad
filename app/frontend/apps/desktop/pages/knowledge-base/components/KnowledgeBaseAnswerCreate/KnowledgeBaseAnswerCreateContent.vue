<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, markRaw, Teleport, useTemplateRef, type Component } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { EnumFormUpdaterId, EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { SidebarName } from '#desktop/components/layout/types.ts'
import { usePage } from '#desktop/composables/usePage.ts'
import { useKnowledgeBaseAnswerCreate } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerCreate.ts'
import type { KnowledgeBaseAnswerCreateFormData } from '#desktop/entities/knowledge-base/types.ts'
import { knowledgeBaseAnswerRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import { useTaskbarTabContext } from '#desktop/entities/user/current/composables/useTaskbarTabContext.ts'
import { useTaskbarTabDiscard } from '#desktop/entities/user/current/composables/useTaskbarTabDiscard.ts'
import { useTaskbarTabStateUpdates } from '#desktop/entities/user/current/composables/useTaskbarTabStateUpdates.ts'

import KnowledgeBaseAnswerSidebar from '../KnowledgeBaseAnswer/KnowledgeBaseAnswerSidebar/KnowledgeBaseAnswerSidebar.vue'

import KnowledgeBaseAnswerCreateHeader from './KnowledgeBaseAnswerCreateHeader.vue'

interface Props {
  localeCode: string
  tabId: string
}

const props = defineProps<Props>()

const route = useRoute()
const router = useRouter()

const contentContainerElement = useTemplateRef('content-container')

const application = useApplicationStore()

const canCreateTags = computed(() => Boolean(application.config.tag_new))

const { form, formNodeId, isDirty, isDisabled, isInitialSettled, values, triggerFormUpdater } =
  useForm()

// Declared by hand: KnowledgeBase::Answer is not an object manager object, so there is no
//   screen/object block to lean on (same as the category form).
//
// The content column and the sidebar are two regions of **one** form: the sidebar fields are
//   teleported out of it, so the form id - and with it the auto-save and the upload cache - stays
//   a single one. Both groups are declared by hand, because `defineFormSchema` only wraps fields
//   in a `FormGroup` of its own while no node is a layout node, and the `Teleport` is one.
//
// No `triggerFormUpdater: false` on any of these (unlike the category form): the updater of this
//   form is what stores the draft, so a field that does not trigger it never gets auto-saved.
//   The text and editor fields already debounce their round trip (`formUpdaterTrigger('delayed')`).
const formSchema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: [
      {
        name: 'title',
        label: __('Title'),
        type: 'text',
        placeholder: __('Answer title'),
        required: true,
      },
      {
        // No `meta`: every editor plugin that would go in there is ticket-specific - the mention
        //   plugins and the AI text tools all key off ticket form nodes, and `mentionKnowledgeBase`
        //   inserts answers *into a ticket article*, which is the wrong direction here. Trimming the
        //   toolbar itself is its own story (zammad/coordination-desktop-view#786), so the field goes
        //   out with the default feature set.
        name: 'body',
        label: __('Text'),
        type: 'editor',
        required: true,
      },
      {
        // The files live in the upload cache under this form's id, which is the taskbar's - so they
        //   stay with the draft, and the form updater plays them back through
        //   FormUpdater::ApplyValue::FormId once it is wired up.
        name: 'attachments',
        label: __('Attachment'),
        labelSrOnly: true,
        type: 'file',
        props: {
          multiple: true,
        },
      },
      {
        // In the content column, as the design has it. Creating new tags follows the `tag_new`
        //   setting, like the object attribute resolver does for ticket forms. On submit the values
        //   ride the mutation's `tags` input - `tagAssignmentUpdate` needs a persisted record.
        name: 'tags',
        label: __('Tags'),
        type: 'tags',
        props: {
          canCreate: canCreateTags,
        },
      },
    ],
  },
  {
    // The same mechanism the ticket detail view uses to render the attributes of its edit form
    //   into the sidebar (TicketDetailViewContent.vue): a layout node that teleports its children
    //   out of the form's DOM, while they stay part of the form.
    isLayout: true,
    component: 'Teleport',
    props: {
      to: '#knowledgeBaseAnswerCreateSidebarFields',
      // The sidebar renders after the content column, so its container does not exist yet when
      //   the form mounts. Deferring resolves the target at the end of the render cycle, by which
      //   time it does - and it never goes away again: collapsing the sidebar only hides it
      //   (`v-show`).
      defer: true,
    },
    children: [
      {
        isLayout: true,
        component: 'FormGroup',
        children: [
          {
            // The state the answer is created in. The labels and the three published-state notes
            //   are the ones the legacy form shows (App.KnowledgeBaseContentCanBePublishedForm),
            //   so the existing translations apply; the archived note is new copy from the design,
            //   which the legacy form has no note for. `Draft` is the default, which the updater
            //   sends as an initial value - nothing to enforce here.
            name: 'visibility',
            label: __('Visibility'),
            type: 'radioList',
            props: {
              options: [
                {
                  value: EnumKnowledgeBaseVisibility.Draft,
                  label: __('Draft'),
                  description: __('Only visible to editors'),
                },
                {
                  value: EnumKnowledgeBaseVisibility.Internal,
                  label: __('Internal'),
                  description: __('Visible to readers & editors'),
                },
                {
                  value: EnumKnowledgeBaseVisibility.Published,
                  label: __('Public'),
                  description: __('Visible to everyone'),
                },
                {
                  value: EnumKnowledgeBaseVisibility.Archived,
                  label: __('Archived'),
                  description: __('Archive this answer'),
                },
              ],
            },
          },
          {
            // When that state applies, as one field: publishing right away is the *absence* of a
            //   timestamp, which is what the empty value of the first option says - so there is
            //   nothing for the form to carry besides the date itself. The picker belongs to the
            //   second option and is rendered below it, indented, instead of being a field of its
            //   own; it is future only, like the legacy date picker (`setStartDate(new Date())`),
            //   and required as long as its option is picked (the field enforces that itself).
            //
            // Gone for a draft, which carries no timestamp at all - a field's own `if` replaces
            //   the show/hide the form updater would drive, which none of the sidebar fields
            //   needs. The truthiness check keeps the group away while no state is picked at all,
            //   instead of reading "not a draft" into an empty field.
            name: 'scheduledAt',
            label: __('Timing'),
            type: 'radioList',
            if: `$values.visibility && $values.visibility !== "${EnumKnowledgeBaseVisibility.Draft}"`,
            props: {
              options: [
                { value: null, label: __('now') },
                {
                  value: 'scheduled',
                  label: __('Schedule for'),
                  dateField: { label: __('Date'), futureOnly: true },
                },
              ],
            },
          },
          {
            // Options, `required` and the preselection all come from the updater. Not clearable:
            //   an answer always belongs to a category, and there is no top level to fall back
            //   on (unlike the parent field of a category).
            name: 'categoryId',
            label: __('Category'),
            type: 'treeselect',
            props: {
              clearable: false,
              // The labels are category titles, i.e. user data, not UI copy.
              noOptionsLabelTranslation: true,
            },
          },
        ],
      },
    ],
  },
])

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

// The draft's tab goes only after the answer exists: a failed create has to keep it, or the work
//   is gone. Its files are already the answer's by then, so the tab has nothing left to carry.
const submitCreateAnswer = async (data: FormSubmitData<KnowledgeBaseAnswerCreateFormData>) => {
  const answer = await createAnswer(
    { ...data, locale: props.localeCode },
    form.value?.formId ?? undefined,
  )

  if (!answer) return

  await router.replace(knowledgeBaseAnswerRoute(props.localeCode, answer.id))

  currentTaskbarTabDelete()
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
      />

      <div class="w-full max-w-270 shrink-0 px-5.5 py-7.5">
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
        <div v-show="isInitialSettled" id="knowledgeBaseAnswerCreateSidebarFields" class="p-3" />
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
