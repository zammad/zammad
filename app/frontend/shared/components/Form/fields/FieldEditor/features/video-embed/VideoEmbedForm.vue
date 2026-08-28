<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, onMounted, ref, toRef, useTemplateRef } from 'vue'

import { getEditorEditorLinkFormClasses } from '#shared/components/Form/fields/FieldEditor/features/link/initializeLinkFormClasses.ts'
import {
  detectVideo,
  newVideoRowAt,
  videoServerAllowed,
  videoWidgetMarker,
  type VideoServer,
} from '#shared/components/Form/fields/FieldEditor/features/video-embed/videoEmbed.ts'
import Form from '#shared/components/Form/Form.vue'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import type { FormKitNode } from '@formkit/core'
import type { Editor } from '@tiptap/vue-3'

const props = defineProps<{
  editor?: Editor
}>()

const { form, waitForFormSettled, formSubmit, isValid } = useForm()

const container = useTemplateRef('container')

const { activateTabTrap } = useTrapTab(container)

onMounted(async () => {
  await nextTick()
  activateTabTrap()
  await waitForFormSettled()

  // FormKit does not honour autofocus, so the input is focused by hand, like the link form does.
  container.value?.querySelector('input')?.focus()
})

const applicationConfig = toRef(useApplicationStore(), 'config')

// The setting is `frontend: true`, so the approved servers are on the config already. Its generated
//   type is `unknown`, hence the cast to the shape the admin area stores.
const selfHostedServers = computed(
  () => (applicationConfig.value.kb_self_hosted_video_servers as VideoServer[] | null) || [],
)

// What a URL may point at, the way the legacy popup lists it: the built-in providers first, then
//   every approved server by name. Brand names, so nothing to translate.
const providerList = computed(() =>
  ['Youtube', 'Vimeo']
    .concat(selfHostedServers.value.map((server) => server.name).sort((a, b) => a.localeCompare(b)))
    .join(', '),
)

const url = ref('')

const detectedVideo = computed(() => detectVideo(url.value))

const videoUrl = (node: FormKitNode) => !!detectVideo(node.value as string)

// Refusing a host that is not on the list is a usability guard, not a security one: the same check
//   runs again in `VideoEmbed.embed_url` on read. A URL that is no video URL at all is the other
//   rule's to complain about, so that only ever one message shows.
const allowedVideoServer = (node: FormKitNode) => {
  const video = detectVideo(node.value as string)

  if (!video?.host) return true

  return videoServerAllowed(video.host, selfHostedServers.value)
}

const close = () => props.editor!.commands.closeVideoEmbedForm()

const embedVideo = () => {
  const video = detectedVideo.value

  if (!video) return

  const marker = videoWidgetMarker(video)

  // The marker goes in as plain text, never as a node: the server-side regex works on the raw body
  //   string, so anything wrapping it would end up wrapping the generated iframe.
  const markerText = { type: 'text', text: marker }

  // In a row of its own, which is what a row with a video in it holds: nothing beside the video,
  //   and no second video. A video that is already there is never edited — it is removed from its
  //   own chip, and a new one embedded in its place.
  props
    .editor!.chain()
    .focus()
    .insertContentAt(newVideoRowAt(props.editor!), { type: 'paragraph', content: [markerText] })
    .run()

  close()
}

const { button, buttonContainer, form: formClass } = getEditorEditorLinkFormClasses()
</script>

<template>
  <div ref="container" class="z-20" role="dialog">
    <Form
      ref="form"
      :class="formClass"
      @submit="embedVideo"
      @keydown.enter="
        (event: KeyboardEvent) => {
          event.preventDefault()
          // Form submission validation is not triggered by calling formSubmit.
          if (isValid) formSubmit()
        }
      "
      @keydown.esc="close"
    >
      <FormKit
        v-model.trim="url"
        name="url"
        validation="required|videoUrl|allowedVideoServer"
        :validation-rules="{ videoUrl, allowedVideoServer }"
        :validation-messages="{
          videoUrl: () => $t('Invalid video URL'),
          allowedVideoServer: () =>
            $t('Video server not allowed. Please add to the list of allowed video servers.'),
        }"
        :label="$t('Video URL')"
        :placeholder="$t('Enter video URL')"
        :help="providerList"
      />

      <div :class="buttonContainer">
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
          {{ $t('Embed video') }}
        </button>
      </div>
    </Form>
  </div>
</template>
