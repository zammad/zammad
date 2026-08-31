<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, markRaw, Teleport, toRef, useTemplateRef, type Component } from 'vue'

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { EnumFormUpdaterId, EnumKnowledgeBaseAnswerScreen } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { getAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { SidebarName } from '#desktop/components/layout/types.ts'
import { usePage } from '#desktop/composables/usePage.ts'
import { useAnswerFormSchema } from '#desktop/entities/knowledge-base/composables/useAnswerFormSchema.ts'
import { useKnowledgeBaseAnswerLiveUserList } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerLiveUserList.ts'
import { useKnowledgeBaseAnswerUpdate } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerUpdate.ts'
import type { KnowledgeBaseAnswerEditFormData } from '#desktop/entities/knowledge-base/types.ts'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import { useTaskbarTabContext } from '#desktop/entities/user/current/composables/useTaskbarTabContext.ts'
import { useTaskbarTabDiscard } from '#desktop/entities/user/current/composables/useTaskbarTabDiscard.ts'
import { useTaskbarTabStateUpdates } from '#desktop/entities/user/current/composables/useTaskbarTabStateUpdates.ts'

import { useKnowledgeBaseAnswer } from '../../composables/useKnowledgeBaseAnswer.ts'
import KnowledgeBaseAnswerContentSkeleton from '../KnowledgeBaseAnswer/KnowledgeBaseAnswerContentSkeleton.vue'
import KnowledgeBaseAnswerLinkedTickets from '../KnowledgeBaseAnswer/KnowledgeBaseAnswerSidebar/KnowledgeBaseAnswerLinkedTickets.vue'
import KnowledgeBaseAnswerScheduledVisibility from '../KnowledgeBaseAnswer/KnowledgeBaseAnswerSidebar/KnowledgeBaseAnswerScheduledVisibility.vue'
import KnowledgeBaseAnswerSidebar from '../KnowledgeBaseAnswer/KnowledgeBaseAnswerSidebar/KnowledgeBaseAnswerSidebar.vue'
import KnowledgeBaseAnswerTags from '../KnowledgeBaseAnswer/KnowledgeBaseAnswerSidebar/KnowledgeBaseAnswerTags.vue'
import KnowledgeBaseAnswerScreenBehavior from '../KnowledgeBaseAnswerScreenBehavior/KnowledgeBaseAnswerScreenBehavior.vue'
import { useKnowledgeBaseAnswerScreenBehavior } from '../KnowledgeBaseAnswerScreenBehavior/useKnowledgeBaseAnswerScreenBehavior.ts'
import { FORM_COLUMN_CLASS } from '../KnowledgeBaseTopBarHeader/headerClasses.ts'

import KnowledgeBaseAnswerEditHeader from './KnowledgeBaseAnswerEditHeader.vue'
import KnowledgeBaseAnswerEditLiveUsers from './KnowledgeBaseAnswerEditLiveUsers.vue'
import { useKnowledgeBaseAnswerConcurrentChange } from './useKnowledgeBaseAnswerConcurrentChange.ts'

interface Props {
  localeCode: string
  answerInternalId: string
}

const props = defineProps<Props>()

// The background of the concurrent-change band below, taken from the alert's own `warning` colours
//   rather than restated here: the band is what spans the view, the alert inside it is transparent
//   (see the template).
const ALERT_BAND_CLASS = getAlertClasses().warning

const contentContainerElement = useTemplateRef('content-container')

const answerId = computed(() => convertToGraphQLId('KnowledgeBase::Answer', props.answerInternalId))

// Not the reader's own redirect-on-error behaviour: LayoutTaskbarTabContent has already gated this
//   component's mount on the tab's own (edit-authorized) entity access, so a 403/404 here can only
//   be a race - nothing to navigate to a second time for.
const { answer, answerConfirmed } = useKnowledgeBaseAnswer({
  answerId,
  locale: toRef(props, 'localeCode'),
  redirectOnAccessError: false,
  // The editor must not load the rendered body: `bodyWithUrls` has the answer-link markers resolved
  //   and the `(widget: video …)` markers expanded into an `<iframe>`, and saving that back would
  //   store the rendering in place of the markers.
  withBodyForEditing: true,
  // No stepper in this header, so nothing here reads the neighbours (and nothing prefetches them).
  withNavigation: false,
})

const {
  form,
  formNodeId,
  isDirty,
  isDisabled,
  isInitialSettled,
  values,
  triggerFormUpdater,
  formReset,
} = useForm()

// A bare id, not a CSS selector: it doubles as the target `<div>`'s `id` attribute in the header's
//   own template (KnowledgeBaseAnswerEditHeader.vue), so the `#` is added only below, where the
//   schema needs an actual selector.
const TITLE_FIELD_TARGET_ID = 'knowledgeBaseAnswerEditTitleField'

// Written once for the same reason, and used the same two ways - as the container's `id` in this
//   view's own sidebar below, and as the schema's selector.
const SIDEBAR_FIELDS_TARGET_ID = 'knowledgeBaseAnswerEditSidebarFields'

const formSchema = useAnswerFormSchema({
  titleFieldTarget: `#${TITLE_FIELD_TARGET_ID}`,
  sidebarFieldsTarget: `#${SIDEBAR_FIELDS_TARGET_ID}`,
  // Which brings the visibility field along, and leaves out the tags one: an existing answer is
  //   tagged from its sidebar instead.
  edit: true,
})

// `Form`'s `initial-entity-object` is what gives a field a synchronous `_init` baseline (a flat
//   by-name lookup on the object, see Form.vue's `getInitialEntityObjectValue`), and that baseline
//   is what dirty is measured against. `title`/`visibility` get one for free, being literal answer
//   attributes. `body` and `categoryId` do not - `body` lives at `content.bodyForEditing`, and
//   `categoryId` is the field's internal id while the answer only carries the GraphQL one, at
//   `category.id` - so without this neither has a baseline at all (only the async form-updater
//   round trip sets their live value, which never backfills `_init`), and the tab would read as
//   changed before anybody typed: the discard button up, the taskbar entry marked, the live user
//   list showing this editor as editing. Exposing both under the flat name and shape the fields
//   actually use closes that gap the same way the other fields already benefit from it.
const initialEntityObject = computed(() => {
  if (!answer.value) return undefined

  const { title, ...answerValues } = answer.value

  const seeded = {
    ...answerValues,
    categoryId: Number(getIdFromGraphQLId(answer.value.category.id)),
  }

  // A locale the answer has no translation in yet - the case the header badges as
  //   `translationMissing` - opens on empty fields instead: `title` and `content` both fall back to
  //   the primary locale (Gql::Types::KnowledgeBase::AnswerType), so seeding either would put
  //   another locale's text into this translation and save it as its own. It would also cost the
  //   updater's deliberately empty initial values, which
  //   FormUpdater::Concerns::ProvidesInitialValues skips for every name the form already sent a
  //   value for - so the untouched tab would count as changed at once, which is what the
  //   OBJECT_VALUES table of ::Edit exists to prevent.
  if (answer.value.translationMissing) return seeded

  return { ...seeded, title, body: answer.value.content?.bodyForEditing }
})

const {
  foreignChange,
  foreignChangeMessage,
  storedAnswerLink,
  knownAttachments,
  snapshotAnswer,
  confirmForeignChange,
} = useKnowledgeBaseAnswerConcurrentChange({
  answer,
  answerConfirmed,
  localeCode: toRef(props, 'localeCode'),
})

// The stored answer, never what is being typed - the same rule the header's heading follows. No
//   fallback label either: `title` is non-null and already falls back to the primary locale
//   (Gql::Types::KnowledgeBase::AnswerType), so it is empty only for an answer that has no
//   translation at all, and then the answer genuinely has no name to show.
usePage({
  metaTitle: computed(() => (answer.value?.title ?? '') as string),
})

const tabContext = useTaskbarTabContext(
  () => ({
    formValues: values.value,
    formIsDirty: isDirty.value,
  }),
  isInitialSettled,
)

const {
  currentTaskbarTab,
  currentTaskbarTabId,
  currentTaskbarTabFormId,
  currentTaskbarEntityKey,
  currentTaskbarTabDelete,
} = useTaskbarTab(tabContext)

// The other editors of this translation. Keyed off the tab's own key, which is what the backend
//   collected them under - and which only an edit tab has, so a reader never appears in the list.
const { liveUserList } = useKnowledgeBaseAnswerLiveUserList(currentTaskbarEntityKey)

// What happens once the answer is saved - stay here, or close the tab and leave for the answer or
//   its category.
const { handleScreenBehavior } = useKnowledgeBaseAnswerScreenBehavior({
  currentTaskbarTabId,
  localeCode: toRef(props, 'localeCode'),
  screen: EnumKnowledgeBaseAnswerScreen.Edit,
})

// **This is the auto-save.** Without `taskbarId` the backend's StoresTaskbarState does nothing and
//   no draft of the unsaved edit is kept - see FormUpdater::Updater::KnowledgeBase::Answer::Edit.
const formUpdaterAdditionalParams = computed(() => ({
  taskbarId: currentTaskbarTab.value?.taskbarTabId,
  // The locale of the tab, so the category options - and the title/body seeded on the very first
  //   round trip - read the translation being edited rather than the editor's profile language.
  locale: props.localeCode,
}))

// Another session of the same user editing this tab: pull its changes in instead of letting the
//   two overwrite each other.
useTaskbarTabStateUpdates(currentTaskbarTabId, form, triggerFormUpdater)

const { notify } = useNotifications()

const { updateAnswer } = useKnowledgeBaseAnswerUpdate()

// Giving up on the changes closes the tab, exactly like in the create view: an answer that is not
//   being edited any more is read in its own view, and its edit tab can be opened again at any
//   time. Same composable, so both views ask the same question and leave in the same order (back
//   first, then drop the tab - the other way round navigates away from under the walker).
const { goBack, discardChanges } = useTaskbarTabDiscard(currentTaskbarTabDelete)

const submitUpdateAnswer = async (data: FormSubmitData<KnowledgeBaseAnswerEditFormData>) => {
  if (!answer.value) return

  if (!(await confirmForeignChange())) return

  // Without a form id there is no upload cache to hand over, and saving would take the answer's
  //   files with it (`attach_upload_cache` empties before it refills) - so there is nothing safe to
  //   submit. It is the taskbar tab's own id, so this only happens if the tab has none yet.
  const { formId } = form.value ?? {}
  if (!formId) return

  // Nor is there anything safe to submit without the baseline of the files the tab opened with:
  //   Service::KnowledgeBase::Answer::Update::Validator::ConcurrentAttachmentChange skips its check
  //   when `knownAttachments` is missing, so the save would replay the upload cache over a file
  //   another editor added since - the very deletion that guard exists to refuse. The baseline
  //   arrives with the answer's first confirmed result, so only a submit before that lands (the
  //   form running on a cached answer) can get here.
  if (!knownAttachments.value) return

  const updated = await updateAnswer(
    answer.value.id,
    { ...data, locale: props.localeCode },
    formId,
    {
      knownAttachments: knownAttachments.value,
      // Confirmed above, so the attachment guard must let this save through - it is the very save
      //   the editor was warned about and agreed to.
      replaceConcurrentChange: Boolean(foreignChange.value),
    },
  )

  if (!updated) return

  notify({
    id: 'knowledge-base-answer-update',
    type: NotificationTypes.Success,
    message: __('Knowledge base answer updated successfully.'),
  })

  return {
    // From the mutation result, not the default post-submit reset: title and body can come back
    //   different from what was submitted (e.g. sanitized), and reading them from the response
    //   means the form shows what is actually stored.
    //
    // categoryId/visibility are not re-derived from it: an ordinary save cannot land on anything but
    //   what was submitted (Service::KnowledgeBase::Answer::Base rejects an unauthorized category
    //   outright rather than silently keeping the old one, and the state it applies takes effect at
    //   once), so the submitted values already are the stored ones.
    reset: () => {
      formReset({
        values: {
          title: updated.title,
          body: updated.content?.bodyForEditing ?? '',
          categoryId: data.categoryId,
          visibility: data.visibility,
        },
      })

      // This editor's own save is not a foreign change: re-snapshot, or the banner and the dialog
      //   would keep reporting the change that was just stored - their own.
      snapshotAnswer()

      // After the reset, so a tab about to be closed is no longer dirty, and its final form-updater
      //   round trip is on its way before the taskbar entry it names is gone.
      //
      // Both id and category come from the response rather than from the loaded answer: it is the
      //   saved state that decides where to go, and a save may just have moved the answer.
      handleScreenBehavior({ id: updated.id, category: updated.category })
    },
  }
}
</script>

<template>
  <LayoutContent
    name="knowledge-base-answer-edit"
    background-variant="primary"
    content-alignment="center"
    show-sidebar
    :sidebar-name="SidebarName.KnowledgeBaseAnswerEdit"
    no-scrollable
    no-padding
  >
    <div
      ref="content-container"
      class="@container flex size-full flex-col items-center overflow-y-auto"
    >
      <KnowledgeBaseAnswerEditHeader
        :content-container-element="contentContainerElement"
        :answer="answer"
        :title-field-target="TITLE_FIELD_TARGET_ID"
      />

      <!-- A band across the whole content area, with the message itself on the form column - the
           shape the ticket detail view's channel alert has (TicketDetailTopBar's
           `alertBaseClasses`): the background spans the view while the text lines up with the
           column below it. Not dismissible: it states what saving will do, and that stays true
           until the tab is saved or closed. -->
      <div v-if="foreignChange" class="w-full shrink-0" :class="ALERT_BAND_CLASS">
        <div class="mx-auto w-full" :class="FORM_COLUMN_CLASS">
          <CommonAlert class="w-full! rounded-none bg-transparent! px-0!" variant="warning">
            {{
              $t(
                foreignChangeMessage,
                ...(foreignChange.editorName ? [foreignChange.editorName] : []),
              )
            }}

            <!-- Their version, to read before deciding what to do with it. The edit tab stays in
                 the taskbar with everything typed in it, so following the link loses nothing.
                 In the alert's own colour rather than the link blue, which is what carries the
                 warning across (`!`, because the base link classes set one too). -->
            <CommonLink
              v-if="storedAnswerLink"
              :link="storedAnswerLink"
              internal
              class="text-current! underline hover:text-current!"
            >
              {{ $t('View answer') }}
            </CommonLink>
          </CommonAlert>
        </div>
      </div>

      <div class="w-full shrink-0 py-7.5" :class="FORM_COLUMN_CLASS">
        <CommonLoader :loading="!answer">
          <template #skeleton>
            <KnowledgeBaseAnswerContentSkeleton />
          </template>

          <!-- Wrapped in an element of its own: `Form` renders two root nodes (its initial
               loading spinner beside the form itself), and the loader animates its child through
               a `Transition`, which needs a single element to animate - Vue warns for every other
               shape. -->
          <div v-if="answer">
            <Form
              id="knowledge-base-answer-edit"
              ref="form"
              :key="`${answerInternalId}-${localeCode}`"
              :form-id="currentTaskbarTabFormId"
              :schema="formSchema"
              :schema-component-library="{ Teleport: markRaw(Teleport) as unknown as Component }"
              :initial-entity-object="initialEntityObject"
              :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterKnowledgeBaseAnswerEdit"
              :form-updater-additional-params="formUpdaterAdditionalParams"
              form-class="flex flex-col gap-3"
              @submit="
                submitUpdateAnswer($event as FormSubmitData<KnowledgeBaseAnswerEditFormData>)
              "
            />
          </div>
        </CommonLoader>
      </div>
    </div>

    <template #sideBar>
      <!-- The reader's shell, with its title and icon: switching between reading and editing an
           answer must not move the sidebar around. -->
      <KnowledgeBaseAnswerSidebar
        :name="SidebarName.KnowledgeBaseAnswerEdit"
        :title="__('Knowledge base answer')"
        icon="file-richtext"
      >
        <!-- Teleported nodes escape the loading gate the form applies to its own wrapper, so
             without this the sidebar would show an empty radio list and an option-less category
             field while the content column is still blank. `v-show`, like the sidebar's own
             collapsing: the teleport target has to stay mounted. -->
        <div v-show="isInitialSettled" :id="SIDEBAR_FIELDS_TARGET_ID" class="p-3" />

        <!-- None of these is a form field: a tag, a link and a scheduled visibility change are
             written onto the answer the moment they are added or removed, like the ticket detail
             view's own sections. Which is why they do not wait for the form either.

             The visibility *field* above says what the answer is now; this section says what it is
             going to become (UX decision of 2026-08-26). -->
        <KnowledgeBaseAnswerScheduledVisibility
          v-if="answer"
          :answer="answer"
          editable
          class="p-3"
        />

        <KnowledgeBaseAnswerTags v-if="answer" :answer="answer" editable class="p-3" />

        <KnowledgeBaseAnswerLinkedTickets v-if="answer" :answer="answer" editable class="p-3" />
      </KnowledgeBaseAnswerSidebar>
    </template>

    <template #bottomBar>
      <!-- Pushed to the leading edge, like the ticket detail view's own row. -->
      <KnowledgeBaseAnswerEditLiveUsers
        :live-user-list="liveUserList"
        class="ltr:mr-auto rtl:ml-auto"
      />

      <!-- Like the create view's own pair: with changes to give up on it asks first, without them
           leaving needs no question. -->
      <CommonButton
        v-if="isInitialSettled && isDirty"
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

      <KnowledgeBaseAnswerScreenBehavior :screen="EnumKnowledgeBaseAnswerScreen.Edit" />

      <CommonButton
        size="large"
        variant="submit"
        type="submit"
        :form="formNodeId"
        :disabled="isDisabled"
      >
        {{ $t('Update') }}
      </CommonButton>
    </template>
  </LayoutContent>
</template>
