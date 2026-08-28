<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { getMarkRange } from '@tiptap/core'
import { computed, nextTick, onMounted, ref, unref, useTemplateRef } from 'vue'

import {
  ANSWER_LINK_TARGET_TYPE,
  answerLinkAttributes,
} from '#shared/components/Form/fields/FieldEditor/features/link/answerLink.ts'
import { getEditorEditorLinkFormClasses } from '#shared/components/Form/fields/FieldEditor/features/link/initializeLinkFormClasses.ts'
import { EXTENSION_NAME as LINK_EXTENSION_NAME } from '#shared/components/Form/fields/FieldEditor/features/link/types.ts'
import { getSelection } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import Form from '#shared/components/Form/Form.vue'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { AutoCompleteKnowledgeBaseAnswerOption } from '#desktop/components/Form/fields/FieldKnowledgeBaseAnswer/types.ts'
import { knowledgeBaseAnswerRouteFromUrl } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import type { FormKitNode } from '@formkit/core'
import type { Editor } from '@tiptap/vue-3'

const props = defineProps<{
  editor?: Editor
}>()

const currentSelection = getSelection(props.editor!)

const { form, waitForFormSettled, formSubmit, isValid } = useForm()

const container = useTemplateRef('container')

const { activateTabTrap } = useTrapTab(container)

onMounted(async () => {
  await nextTick()
  activateTabTrap()
  await waitForFormSettled()

  // FormKit does not honour autofocus, so the picker is focused by hand, like the URL form does.
  container.value?.querySelector<HTMLElement>('[role="combobox"]')?.focus()
})

// The answer this link already points at, if the caret sits inside one. Its title is not queried
//   again: the link's own text is what the answer is called in this document.
const activeAnswerLink = (() => {
  const attributes = props.editor?.getAttributes(LINK_EXTENSION_NAME) || {}

  if (attributes['data-target-type'] !== ANSWER_LINK_TARGET_TYPE) return undefined
  if (!attributes['data-target-id']) return undefined

  // The link the caret is in, which is not necessarily the first one of its row: a row may hold
  //   several, and it is the text of the one being edited that names its answer.
  const linkRange = getMarkRange(
    props.editor!.state.selection.$head,
    props.editor!.schema.marks[LINK_EXTENSION_NAME],
  )

  return {
    value: convertToGraphQLId(
      'KnowledgeBase::Answer::Translation',
      Number(attributes['data-target-id']),
    ),
    label: linkRange ? props.editor!.state.doc.textBetween(linkRange.from, linkRange.to, '') : '',
    href: attributes.href as string,
  }
})()

// Only what the picker needs to show the current pick; the href is kept out of the option.
const prefilledOptions = activeAnswerLink
  ? [{ value: activeAnswerLink.value, label: activeAnswerLink.label }]
  : undefined

const selectedText = props
  .editor!.state.doc.textBetween(currentSelection.from, currentSelection.to, '')
  .trim()

const answerId = ref(activeAnswerLink?.value)

// The full picked option, not just its value: the href is written from the answer's own route,
//   which the picker query supplies. `optionValueLookup` is what the autocomplete field exposes
//   for exactly this lookup.
const answerNode = ref<FormKitNode>()

const pickedAnswer = computed<AutoCompleteKnowledgeBaseAnswerOption | undefined>(() => {
  if (!answerId.value) return undefined

  const lookup = unref(answerNode.value?.context?.optionValueLookup) as
    | Record<string, AutoCompleteKnowledgeBaseAnswerOption>
    | undefined

  return lookup?.[answerId.value]
})

// Where the link would take the reader, offered next to the picker as soon as there is a target.
//   The seeded option carries no route of its own, hence the fall back to the link's own href.
const answerRoute = computed(() => {
  // The server resolves the href of a link whose answer is gone to `#`; there is nowhere to go.
  const url = pickedAnswer.value?.url || activeAnswerLink?.href

  return url && url !== '#' ? knowledgeBaseAnswerRouteFromUrl(url) : undefined
})

const close = () => props.editor!.commands.closeLinkForm()

// The form floats above the editor rather than inside it, so it would outlive the navigation the
//   link performs. It takes itself down instead, once the click it was handed has run its course.
const followAnswerRoute = () => nextTick(close)

const insertAnswerLink = () => {
  const answer = pickedAnswer.value

  if (!answer) return

  // Submitting a prefilled form without touching the picker leaves the option the form was seeded
  //   with, which carries no route of its own — the link then keeps the href it already had.
  const attributes = answerLinkAttributes(answer.url || activeAnswerLink?.href || '', answer.value)

  // Replacing the link the caret sits in, rather than inserting a second one beside it.
  if (activeAnswerLink) {
    props
      .editor!.chain()
      .focus()
      .extendMarkRange(LINK_EXTENSION_NAME)
      .insertContent({
        type: 'text',
        text: selectedText || answer.label,
        marks: [{ type: LINK_EXTENSION_NAME, attrs: attributes }],
      })
      .run()
  } else {
    props
      .editor!.chain()
      .focus()
      .deleteRange(currentSelection)
      .insertContentAt(currentSelection.from, {
        type: 'text',
        text: selectedText || answer.label,
        marks: [{ type: LINK_EXTENSION_NAME, attrs: attributes }],
      })
      .run()
  }

  close()
}

const removeAnswerLink = () => {
  props.editor!.chain().focus().unsetMark(LINK_EXTENSION_NAME, { extendEmptyMarkRange: true }).run()

  close()
}

const { button, buttonContainer, form: formClass } = getEditorEditorLinkFormClasses()
</script>

<template>
  <div ref="container" class="z-20" role="dialog">
    <Form
      ref="form"
      :class="formClass"
      @submit="insertAnswerLink"
      @keydown.enter="
        (event: KeyboardEvent) => {
          // The link to the answer, which Enter follows the same way a click does. Taking the
          //   keystroke for the form would cancel that activation, like the URL form's handler.
          if ((event.target as HTMLElement)?.tagName === 'A') return

          event.preventDefault()
          if (isValid) formSubmit()
        }
      "
      @keydown.esc="close"
    >
      <FormKit
        v-model="answerId"
        type="knowledgeBaseAnswer"
        name="answer"
        validation="required"
        :label="$t('Answer')"
        :options="prefilledOptions"
        :link="answerRoute"
        :on-link-click="followAnswerRoute"
        :no-link-open-in-new-tab="true"
        :link-label="$t('View answer')"
        link-icon="file-richtext"
        @node="answerNode = $event"
      />

      <div :class="buttonContainer">
        <button
          v-if="activeAnswerLink"
          :class="button.danger"
          type="reset"
          @click="removeAnswerLink"
          @keydown.enter.stop="removeAnswerLink"
        >
          {{ $t('Remove link') }}
        </button>

        <button
          :class="button.secondary"
          class="ms-auto"
          type="button"
          @click="close"
          @keydown.enter.stop="close"
        >
          {{ $t('Cancel') }}
        </button>

        <button :class="button.primary" type="submit">
          {{ $t('Link answer') }}
        </button>
      </div>
    </Form>
  </div>
</template>
