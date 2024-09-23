<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { useDropZone } from '@vueuse/core'
import { useTemplateRef, computed, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { i18n } from '#shared/i18n.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'

export interface Props {
  context: FormFieldContext<{
    placeholderImagePath?: string
  }>
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const { localValue } = useValue(contextReactive)

const imageUpload = computed<string>({
  get() {
    return localValue.value || ''
  },
  set(value) {
    localValue.value = value
  },
})

const imageUploadOrPlaceholder = computed<string>(() => {
  if (props.context.placeholderImagePath && !imageUpload.value) {
    return props.context.placeholderImagePath || ''
  }

  return imageUpload.value
})

const MAX_IMAGE_SIZE_IN_MB = 8

const imageUploadInput = useTemplateRef('image-upload')

const reset = () => {
  imageUpload.value = ''
  const input = imageUploadInput.value
  if (!input) return
  input.value = ''
  input.files = null
}

const loadImages = async (files: FileList | File[] | null) => {
  Array.from(files || []).forEach((file) => {
    const reader = new FileReader()

    reader.onload = (e) => {
      if (!e.target || !e.target.result) return

      imageUpload.value = e.target.result as string
    }

    if (file.size && file.size > 1024 * 1024 * MAX_IMAGE_SIZE_IN_MB) {
      props.context.node.setErrors(
        i18n.t(
          'File too big, max. %s MB allowed.',
          MAX_IMAGE_SIZE_IN_MB.toString(),
        ),
      )
      return
    }

    reader.readAsDataURL(file)
  })
}

const onFileChanged = async ($event: Event) => {
  const input = $event.target as HTMLInputElement
  const { files } = input
  if (files) await loadImages(files)
}

const dropZoneElement = useTemplateRef('drop-zone')

const { isOverDropZone } = useDropZone(dropZoneElement, {
  onDrop: loadImages,
  dataTypes: (types) => types.every((type) => type.startsWith('image/')),
})
</script>

<template>
  <div
    ref="drop-zone"
    class="flex w-full flex-col items-center gap-2 p-2"
    :class="context.classes.input"
  >
    <div
      v-if="isOverDropZone"
      class="w-full rounded text-center outline-dashed outline-1 outline-blue-800"
    >
      <CommonLabel
        class="py-2 text-blue-800 dark:text-blue-800"
        prefix-icon="upload"
      >
        {{ $t('Drop image file here') }}
      </CommonLabel>
    </div>
    <template v-else>
      <template v-if="imageUploadOrPlaceholder">
        <div
          class="grid w-full grid-cols-[20px_auto_20px] items-center justify-items-center gap-2.5 p-2.5"
        >
          <img
            class="col-start-2 max-h-32"
            :src="imageUploadOrPlaceholder"
            :alt="$t('Image preview')"
          />
          <CommonButton
            v-if="imageUpload"
            variant="remove"
            size="small"
            icon="x-lg"
            :aria-label="$t('Remove image')"
            @click="!context.disabled && reset()"
          />
        </div>
        <CommonDivider padding />
      </template>
      <CommonButton
        variant="secondary"
        size="medium"
        prefix-icon="image"
        :disabled="context.disabled"
        @click="!context.disabled && imageUploadInput?.click()"
        @blur="context.handlers.blur"
        >{{ $t('Upload image') }}</CommonButton
      >
    </template>
    <input
      :id="context.id"
      ref="image-upload"
      data-test-id="imageUploadInput"
      type="file"
      :name="context.node.name"
      :disabled="context.disabled"
      class="hidden"
      :class="context.classes.input"
      tabindex="-1"
      aria-hidden="true"
      :aria-describedby="context.describedBy"
      accept="image/*"
      v-bind="context.attrs"
      @change="!context.disabled && onFileChanged($event)"
    />
  </div>
</template>
