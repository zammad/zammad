<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { getNode } from '@formkit/core'
import { useEventListener, useMutationObserver } from '@vueuse/core'
import { computed, onBeforeUnmount, onMounted, ref, shallowRef, useId, useTemplateRef } from 'vue'

import { SUGGESTIONS_LOADING_ATTRIBUTE } from '#shared/components/Form/fields/FieldEditor/features/suggestions/constants.ts'
import type {
  FieldEditorContext,
  FieldEditorProps,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import { isComposing } from '#shared/utils/events.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useChatMessageInputs } from '#desktop/entities/chat/composables/useChatMessageInputs.ts'

interface Props {
  // Rejects when the message could not be stored, which puts it back into the field.
  send: (html: string) => Promise<unknown>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  typing: []
  leave: []
}>()

// The limit of a message in the old interface, which counts the text and not the images in it.
const MAX_LENGTH = 40000

// The footer only carries the limit: the old interface shows no counter either.
const editorMeta: FieldEditorProps['meta'] = {
  footer: { maxlength: MAX_LENGTH, disabled: true },
}

const fieldId = `chat-composer-${useId()}`

const html = ref('')

// An image alone is a message too.
const hasContent = (value: string) => {
  const { body } = new DOMParser().parseFromString(value, 'text/html')

  return body.textContent?.trim() !== '' || body.querySelector('img') !== null
}

const isSending = ref(false)

const canSend = computed(() => !isSending.value && hasContent(html.value))

// The editor hands its value over asynchronously; the uncommitted one has the last key before an Enter.
const fieldValue = () => {
  const value = getNode(fieldId)?._value

  return typeof value === 'string' ? value : html.value
}

const setFieldValue = (value: string) => getNode(fieldId)?.input(value)

const editorContext = () => getNode(fieldId)?.context as FieldEditorContext | undefined

const submit = async () => {
  if (isSending.value) return

  const written = fieldValue()

  // An image pasted right before belongs to this message, also while it is still being read.
  const imagesOnTheirWay = editorContext()?.takeImagesOnTheirWay?.()

  if (!imagesOnTheirWay && !hasContent(written)) return

  isSending.value = true

  // Emptied right away like in the old interface, so the agent can go on with the next message.
  setFieldValue('')

  const sent = imagesOnTheirWay ? `${written}${await imagesOnTheirWay}` : written

  if (!hasContent(sent)) {
    isSending.value = false
    return
  }

  try {
    await props.send(sent)
  } catch {
    // Back for another try, before what the agent wrote since; the handler already told them.
    const typed = fieldValue()

    setFieldValue(hasContent(typed) ? `${sent}<br>${typed}` : sent)
  } finally {
    isSending.value = false
  }
}

// A control inside the message, like the button of an image, keeps its own Enter.
const isInText = (event: KeyboardEvent) =>
  event.target instanceof HTMLElement && event.target.id === fieldId

const hasAttribute = (event: KeyboardEvent, name: string) =>
  event.target instanceof HTMLElement && event.target.hasAttribute(name)

// While the text module list is open, Enter belongs to it and sends nothing, so the customer never
//   gets the "::" of a search: Escape closes the list first.
const isSuggestionListOpen = (event: KeyboardEvent) => hasAttribute(event, 'aria-expanded')

// An entry marked while the list still loads is one of the search before.
const isPickingSuggestion = (event: KeyboardEvent) =>
  hasAttribute(event, 'aria-activedescendant') &&
  !hasAttribute(event, SUGGESTIONS_LOADING_ATTRIBUTE)

// Caught on the way down, before the editor turns it into a new paragraph; Shift+Enter still breaks
//   the line. The Enter that commits an input method conversion belongs to the conversion.
const onEnter = (event: KeyboardEvent) => {
  if (event.key !== 'Enter' || event.shiftKey || event.altKey || event.ctrlKey || event.metaKey)
    return
  if (isComposing(event)) return
  if (!isInText(event)) return
  if (isSuggestionListOpen(event) && isPickingSuggestion(event)) return

  event.preventDefault()
  event.stopPropagation()

  if (!isSuggestionListOpen(event)) submit()
}

const focus = () => editorContext()?.focus()

const onInput = (value: unknown) => {
  html.value = typeof value === 'string' ? value : ''

  if (hasContent(html.value)) emit('typing')
}

// Tab goes from message input to message input, around the ends, as in the old interface.
const { hasLoop, registerInput, unregisterInput, focusNextInput, focusPreviousInput } =
  useChatMessageInputs()

const form = useTemplateRef('form')

const input = shallowRef<HTMLElement | null>(null)

// The editor loads after the composer, so its text field joins the loop once it is there. Looked up in
//   the form, as a window opened while the page is kept in the background is not in the document.
const registerInputOnceThere = () => {
  input.value = form.value?.querySelector<HTMLElement>(`[id="${fieldId}"]`) ?? null

  if (input.value) registerInput(input.value)

  return !!input.value
}

const { stop: stopWaitingForInput } = useMutationObserver(
  form,
  () => {
    if (registerInputOnceThere()) stopWaitingForInput()
  },
  { childList: true, subtree: true },
)

onMounted(() => {
  if (registerInputOnceThere()) stopWaitingForInput()
})

onBeforeUnmount(() => {
  if (input.value) unregisterInput(input.value)
})

const onTab = (event: KeyboardEvent) => {
  if (event.key !== 'Tab' || event.altKey || event.ctrlKey || event.metaKey) return
  if (!input.value || !isInText(event) || isSuggestionListOpen(event)) return

  const hasMoved = event.shiftKey ? focusPreviousInput(input.value) : focusNextInput(input.value)

  if (!hasMoved) return

  event.preventDefault()
  event.stopPropagation()
}

// Escape closes an open list first, which takes the focus off the editor too (zammad/zammad#6525);
//   the agent goes on writing or sends. Otherwise it leaves the loop of the inputs, unless it
//   cancels an input method conversion; with a single input there is no loop to leave.
const onEscape = (event: KeyboardEvent) => {
  if (event.key !== 'Escape' || !isInText(event)) return

  if (isSuggestionListOpen(event)) {
    requestAnimationFrame(focus)
    return
  }

  if (!hasLoop.value || isComposing(event)) return

  emit('leave')
}

useEventListener(form, 'keydown', onEnter, { capture: true })
useEventListener(form, 'keydown', onTab, { capture: true })
useEventListener(form, 'keydown', onEscape, { capture: true })

// For the window to put the agent into the conversation, e.g. from the browser notification, and
//   to tell when they are in it. The focus goes through the field, which keeps it for an editor
//   that is still loading.
defineExpose({ focus, input })
</script>

<template>
  <form ref="form" class="flex flex-row-reverse items-end gap-3 px-3 py-2" @submit.prevent="submit">
    <!-- The send button comes first in the document and last in the row: Tab from the window reaches
      it before the input, whose own Tab moves on to the next window. -->
    <CommonButton type="submit" variant="primary" size="medium" :disabled="!canSend">
      {{ $t('Send') }}
    </CommonButton>

    <!-- Starts as one line as tall as the button and grows up to half the screen, as in the old interface; with no toolbar above, rounded all round. -->
    <FormKit
      :id="fieldId"
      type="editor"
      :delay="0"
      outer-class="grow"
      inner-class="rounded-t-lg!"
      input-class="min-h-5! max-h-[50vh] overflow-y-auto [&_p]:my-0!"
      :label="__('Message')"
      :label-sr-only="true"
      extension-set="reduced"
      :meta="editorMeta"
      :model-value="html"
      @input="onInput"
    />
  </form>
</template>
