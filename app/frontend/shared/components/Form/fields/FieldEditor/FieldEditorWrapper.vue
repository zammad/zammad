<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { computed, defineAsyncComponent } from 'vue'
import type { FormFieldContext } from '@shared/components/Form/types/field'
import FieldEditorFooter from './FieldEditorFooter.vue'
import type {
  FieldEditorContext,
  FieldEditorProps,
  PossibleSignature,
} from './types'

const FieldEditor = defineAsyncComponent(() => import('./FieldEditorInput.vue'))

interface Props {
  context: FormFieldContext<FieldEditorProps>
}

const props = defineProps<Props>()

const editorRerenderKey = computed(() => {
  // when plain changes, we need to rerender the editor
  const type = props.context.contentType === 'text/plain' ? 'plain' : 'html'
  return `${type}-${props.context.id}`
})

const onLoad: ((context: FieldEditorContext) => void)[] = []
const queueAction = (fn: (context: FieldEditorContext) => void) => {
  onLoad.push(fn)
}

const preContext = {
  onLoad,
  getEditorValue: () => '',
  addSignature: (signature: PossibleSignature) =>
    queueAction((context) => context.addSignature(signature)),
  removeSignature: () => queueAction((context) => context.removeSignature()),
  focus: () => queueAction((context) => context.focus()),
}

Object.assign(props.context, preContext)
</script>

<template>
  <Suspense>
    <FieldEditor v-bind="$attrs" :key="editorRerenderKey" :context="context" />
    <template #fallback>
      <div class="p-2">
        <div class="h-20" />
        <FieldEditorFooter
          v-if="context.meta?.footer && !context.meta.footer.disabled"
          :footer="context.meta.footer"
          :characters="0"
        />
      </div>
    </template>
  </Suspense>
</template>
