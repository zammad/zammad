<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import {
  computed,
  markRaw,
  nextTick,
  Teleport,
  toRef,
  useTemplateRef,
  watch,
  type Component,
} from 'vue'

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData, FormValues } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { EnumFormUpdaterId, EnumKnowledgeBaseAnswerScreen } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { getAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { SidebarName } from '#desktop/components/layout/types.ts'
import { useKeepAliveHooks } from '#desktop/composables/useKeepAliveHooks.ts'
import { usePage } from '#desktop/composables/usePage.ts'
import { useScrollPosition } from '#desktop/composables/useScrollPosition.ts'
import { useAnswerFormSchema } from '#desktop/entities/knowledge-base/composables/useAnswerFormSchema.ts'
import { useKnowledgeBaseAnswerDelete } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerDelete.ts'
import { useKnowledgeBaseAnswerLiveUserList } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerLiveUserList.ts'
import { useKnowledgeBaseAnswerUpdate } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerUpdate.ts'
import type { KnowledgeBaseAnswerEditFormData } from '#desktop/entities/knowledge-base/types.ts'
import { isTranslationMissing } from '#desktop/entities/knowledge-base/utils/translationLocale.ts'
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

// The translation this tab edits, and whether the tab is writing one that does not exist yet - then
//   the text it was handed belongs to the locale it falls back to (see `isTranslationMissing`).
const translation = computed(() => answer.value?.translation)

const translationMissing = computed(
  () => Boolean(answer.value) && isTranslationMissing(translation.value, props.localeCode),
)

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

  const { translation: answerTranslation, ...answerValues } = answer.value

  const seeded = {
    ...answerValues,
    categoryId: Number(getIdFromGraphQLId(answer.value.category.id)),
  }

  // A locale the answer has no translation in yet - the case the header announces - opens on empty
  //   fields instead: the translation it was handed is another locale's, so seeding from it would
  //   put that text into this one and save it as its own. It would also cost the updater's
  //   deliberately empty initial values, which FormUpdater::Concerns::ProvidesInitialValues skips
  //   for every name the form already sent a value for - so the untouched tab would count as
  //   changed at once, which is what the OBJECT_VALUES table of ::Edit exists to prevent.
  if (translationMissing.value) return seeded

  return {
    ...seeded,
    title: answerTranslation?.title,
    body: answerTranslation?.content?.bodyForEditing,
  }
})

const {
  foreignChange,
  announcedChange,
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
//   fallback label either: a title is empty only for an answer with no translation at all, and then
//   the answer genuinely has no name to show.
usePage({
  metaTitle: computed(() => translation.value?.title ?? ''),
})

useScrollPosition(contentContainerElement)

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

const { confirmAnswerDelete } = useKnowledgeBaseAnswerDelete()

const sidebarActions = computed<MenuItem[]>(() => {
  const currentAnswer = answer.value
  if (!currentAnswer?.policy.destroy) return []

  return [
    {
      key: 'delete-answer',
      label: __('Delete answer'),
      icon: 'trash3',
      variant: 'danger',
      onClick: () =>
        confirmAnswerDelete(
          { id: currentAnswer.id, title: currentAnswer.translation?.title },
          { categoryId: currentAnswer.category.id },
        ),
    },
  ]
})

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

const { updateAnswer, updateRunning } = useKnowledgeBaseAnswerUpdate()

// The stored values this form follows, kept identity-stable: the answer is a new object on every
//   push, and a change that leaves these alone - a tag, a schedule, a sibling locale - is no reason
//   to touch the fields.
//
// The body is not among them: the editor re-serializes what it loads, so its value never compares
//   equal to the stored one and a takeover cannot tell an edit from a reformat. Whether it was typed
//   in is asked separately - see `EDITED_FIELD_NAMES`.
const storedFormValues = computed<FormValues>((previous) => {
  if (!answer.value) return {}

  const stored: FormValues = {
    categoryId: Number(getIdFromGraphQLId(answer.value.category.id)),
    visibility: answer.value.visibility,
  }

  // The rule the initial seeding follows, for the same reason (see `initialEntityObject`): in a
  //   locale without its own translation this is another locale's text, and pulling it in would
  //   offer it up as this translation's own.
  if (!translationMissing.value) stored.title = translation.value?.title

  return previous && isEqual(stored, previous) ? previous : stored
})

// Every field a takeover writes - a reset fills what its values do not name from
//   `initialEntityObject`, and empties a field neither carries. Not derived from
//   `storedFormValues`, which omits the body always and the title while a translation is being
//   written from scratch: the two most likely to hold unsaved work.
//
// `attachments` is among them although no takeover value names it: it is a form field
//   (`useAnswerFormSchema`), so a reset restores the stored answer's list over an upload that has
//   landed in the field but is not saved yet - gone from the form while it stays in the upload
//   cache under this form's id, and submitted by the next save. Tags are not a field of the edit
//   form.
const EDITED_FIELD_NAMES = ['title', 'body', 'categoryId', 'visibility', 'attachments']

// The fields as they are this instant. Not `values`, which FormKit commits a tick after the
//   keystroke, and not the dirty marks, set on that same commit: a change arriving in that window
//   would find both still showing what was there before it.
//
// Compared with what the form last held, never with the stored answer: the editor re-serializes the
//   body it loads, and a translation being written has no stored title to compare with.
const currentFieldValues = () =>
  Object.fromEntries(
    EDITED_FIELD_NAMES.map((name) => [
      name,
      (form.value?.findNodeByName(name) as { _value?: unknown } | undefined)?._value,
    ]),
  )

// What the fields held when the stored answer was last taken over. Read from the form rather than
//   from the answer, because a field may hold a stored value in another shape - the editor
//   re-serializes the body it loads - and comparing against the answer would report an edit nobody
//   made.
let lastTakenOver: Record<string, unknown> | undefined

// A change to the text alone leaves every field a takeover compares by untouched, and the body
//   cannot stand in for it: the editor re-serializes what it loads, so the form's value never
//   equals the stored one. `editedAt` is what moves when the stored text does, so it is what says
//   a takeover is due.
const storedEditedAt = computed(() => translation.value?.editedAt)

let lastTakenOverEditedAt: string | null | undefined

const rememberTakenOver = () => {
  lastTakenOver = currentFieldValues()
  lastTakenOverEditedAt = storedEditedAt.value
}

const editorChangedSomething = () => {
  // No baseline yet, so nothing can be told apart: leave the fields alone rather than guess, and
  //   take the baseline now so the next change can be.
  if (!lastTakenOver) {
    rememberTakenOver()

    return true
  }

  const current = currentFieldValues()

  return Object.entries(lastTakenOver).some(([name, taken]) => !isEqual(current[name], taken))
}

// Somebody else's save - or this user's own from another session or the old interface - pulled into
//   the fields, so an open tab shows what is stored rather than what it happened to open with.
//   Without this they never move again: `initial-entity-object` is read once (Form.vue), and the
//   banner below would be the only sign that anything happened at all.
const applyStoredValues = (stored: FormValues) => {
  if (!answer.value || !isInitialSettled.value) return

  // This editor's own save: its response re-baselines the form (see `reset` below), and a refresh
  //   in between would hand the values it is about to replace to the form updater.
  if (updateRunning.value) return

  // The fields already hold what is stored, so there is nothing to take over - somebody else's save
  //   reached them by another route, which is what happens when the taskbar state of another
  //   session is applied (the draft it stored is that save). Only the baseline is behind, and
  //   leaving it behind is what would keep the banner up over values that already match.
  const current = currentFieldValues()
  const storedTextMoved = storedEditedAt.value !== lastTakenOverEditedAt

  if (
    !storedTextMoved &&
    Object.entries(stored).every(([name, value]) => isEqual(current[name], value))
  ) {
    rememberTakenOver()

    return
  }

  // Not over unsaved work. The tab then keeps every value it has and the banner does the talking -
  //   which is also what makes it safe to take the whole set over below rather than field by field.
  if (editorChangedSomething()) return

  formReset(
    { values: stored, object: initialEntityObject.value },
    { resetDirty: false, resetFlags: false },
  )

  nextTick(rememberTakenOver)
}

// The baseline the comparison above starts from: what the form settled on, which is the answer as
//   the tab opened it.
watch(
  isInitialSettled,
  (settled) => {
    if (settled && !lastTakenOver) rememberTakenOver()
  },
  { immediate: true },
)

// Not while the tab is in the background: a parked taskbar tab lives in a detached container (see
//   LayoutPage's cache), where the form's teleported fields - the title and the whole sidebar
//   column - cannot find their targets, and re-creating them there mounts them nowhere at all
//   ("Failed to locate Teleport target", reproduced). The change is held and applied when the tab
//   is looked at again, the rule the content update ping already follows
//   (useKnowledgeBaseContentUpdates).
let onScreen = true
let missedStoredChange = false

watch([storedFormValues, storedEditedAt], ([stored]) => {
  if (!onScreen) {
    missedStoredChange = true
    return
  }

  applyStoredValues(stored)
})

useKeepAliveHooks({
  onDeactivated: () => {
    onScreen = false
  },
  onReactivated: () => {
    onScreen = true

    if (!missedStoredChange) return

    missedStoredChange = false
    applyStoredValues(storedFormValues.value)
  },
})

// Cancelling closes the tab: an answer that is not being edited any more is read in its own view,
//   and its edit tab can be opened again at any time. Same composable as the create view, so both
//   leave in the same order (back first, then drop the tab - the other way round navigates away
//   from under the walker). Only offered while nothing is changed, so it asks no question.
const { closeTab } = useTaskbarTabDiscard(currentTaskbarTabDelete)

const { waitForVariantConfirmation } = useConfirmation()

// Discarding, on the other hand, stays: the fields go back to the stored answer and the tab stays
//   open for the next edit, the way the ticket detail view's own discard button behaves. Not the
//   create view's discard, which has no stored state to go back to and closes the tab instead.
//
// The text is named explicitly, with the stored value or an empty one - a translation being
//   written from scratch has no stored title or body, and `initialEntityObject` leaves both out
//   for that reason (see there). `attachments` is not named and does not need to be: the reset
//   fills it from `initialEntityObject`, which carries the answer's stored set - which is exactly
//   what giving up on the changes means for an upload that was never saved.
const discardChanges = async () => {
  if (!answer.value) return

  const confirm = await waitForVariantConfirmation('unsaved')
  if (!confirm) return

  formReset({
    values: {
      title: translationMissing.value ? '' : (translation.value?.title ?? ''),
      body: translationMissing.value ? '' : (translation.value?.content?.bodyForEditing ?? ''),
      categoryId: Number(getIdFromGraphQLId(answer.value.category.id)),
      visibility: answer.value.visibility,
    },
    object: initialEntityObject.value,
  })

  // The fields now hold the stored answer again, and a later stored change has to be told apart
  //   from that rather than from the edit just given up on.
  nextTick(rememberTakenOver)
}

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
          title: updated.translation?.title,
          body: updated.translation?.content?.bodyForEditing ?? '',
          categoryId: data.categoryId,
          visibility: data.visibility,
        },
      })

      // This editor's own save is not a foreign change: re-snapshot, or the banner and the dialog
      //   would keep reporting the change that was just stored - their own.
      snapshotAnswer()

      // The same for what the stored values are compared against: the form has just been
      //   re-baselined from the response, and a comparison still pointing at the values from before
      //   the save would read as unsaved work and keep every later change out.
      nextTick(rememberTakenOver)

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
        :translation-missing="translationMissing"
      />

      <!-- A band across the whole content area, with the message itself on the form column - the
           shape the ticket detail view's channel alert has (TicketDetailTopBar's
           `alertBaseClasses`): the background spans the view while the text lines up with the
           column below it. Not dismissible: it states what saving will do, and that stays true
           until the tab is saved or closed. -->
      <div v-if="announcedChange" class="w-full shrink-0" :class="ALERT_BAND_CLASS">
        <div class="mx-auto w-full" :class="FORM_COLUMN_CLASS">
          <CommonAlert class="w-full! rounded-none bg-transparent! px-0!" variant="warning">
            <div>
              {{
                $t(
                  foreignChangeMessage,
                  ...(!announcedChange.byCurrentUser && announcedChange.editorName
                    ? [announcedChange.editorName]
                    : []),
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
                size="medium"
              >
                {{ $t('View answer') }}
              </CommonLink>
            </div>
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
        :actions="sidebarActions"
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

      <!-- With changes to give up on it asks first and then restores the stored answer in place,
           the ticket detail view's own discard; without them leaving needs no question, and closes
           the tab. -->
      <CommonButton
        v-if="isInitialSettled && isDirty"
        size="large"
        variant="danger"
        :disabled="isDisabled"
        @click="discardChanges"
      >
        {{ $t('Discard your unsaved changes') }}
      </CommonButton>

      <CommonButton v-else size="large" variant="secondary" @click="closeTab">
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
