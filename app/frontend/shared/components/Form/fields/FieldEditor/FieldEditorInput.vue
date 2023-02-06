<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { FormFieldContext } from '@shared/components/Form/types/field'
import { convertFileList } from '@shared/utils/files'
import type { Editor } from '@tiptap/vue-3'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import { useEventListener } from '@vueuse/core'
import { computed, onMounted, onUnmounted, ref, toRef, watch } from 'vue'
import testFlags from '@shared/utils/testFlags'
import useValue from '../../composables/useValue'
import {
  getCustomExtensions,
  getHtmlExtensions,
  getPlainExtensions,
} from './extensions/list'
import type {
  EditorContentType,
  EditorCustomPlugins,
  FieldEditorContext,
  FieldEditorProps,
  PossibleSignature,
} from './types'
import FieldEditorActionBar from './FieldEditorActionBar.vue'
import FieldEditorFooter from './FieldEditorFooter.vue'
import { PLUGIN_NAME as userMentionPluginName } from './suggestions/UserMention'

interface Props {
  context: FormFieldContext<FieldEditorProps>
}

const props = defineProps<Props>()

const reactiveContext = toRef(props, 'context')
const { currentValue } = useValue(reactiveContext)

// TODO: add maybe something to extract the props from the context, instead of using context.XYZ (or props.context.XYZ)

const disabledPlugins = Object.entries(props.context.meta || {})
  .filter(([, value]) => value.disabled)
  .map(([key]) => key as EditorCustomPlugins)

const contentType = computed<EditorContentType>(
  () => props.context.contentType || 'text/html',
)

// remove user mention in plain text mode and inline images
if (contentType.value === 'text/plain') {
  disabledPlugins.push(userMentionPluginName, 'image')
}

const editorExtensions =
  contentType.value === 'text/plain'
    ? getPlainExtensions()
    : getHtmlExtensions()

getCustomExtensions(reactiveContext).forEach((extension) => {
  if (!disabledPlugins.includes(extension.name as EditorCustomPlugins)) {
    editorExtensions.push(extension)
  }
})

const showActionBar = ref(false)
const editor = useEditor({
  extensions: editorExtensions,
  editorProps: {
    attributes: {
      role: 'textbox',
      name: props.context.node.name,
      id: props.context.id,
      class: 'min-h-[80px]',
    },
    // add inlined files
    handlePaste(view, event) {
      const files = event.clipboardData?.files || null
      convertFileList(files).then((urls) => {
        editor.value?.commands.setImages(urls)
      })

      if (files && files.length) {
        event.preventDefault()
        return true
      }

      return false
    },
    handleDrop(view, event) {
      const e = event as unknown as InputEvent
      const files = e.dataTransfer?.files || null
      convertFileList(files).then((urls) => {
        editor.value?.commands.setImages(urls)
      })
      if (files && files.length) {
        event.preventDefault()
        return true
      }
      return false
    },
  },
  editable: props.context.disabled !== true,
  content: currentValue.value,
  onUpdate({ editor }) {
    const content =
      contentType.value === 'text/plain' ? editor.getText() : editor.getHTML()
    const value = content === '<p></p>' ? '' : content
    props.context.node.input(value)
  },
  onFocus() {
    showActionBar.value = true
  },
  onBlur() {
    props.context.handlers.blur()
  },
})

watch(
  () => props.context.id,
  (id) => {
    editor.value?.setOptions({
      editorProps: {
        attributes: {
          role: 'textbox',
          name: props.context.node.name,
          id,
          class: 'min-h-[80px]',
        },
      },
    })
  },
)

watch(
  () => props.context.disabled,
  (disabled) => {
    editor.value?.setEditable(!disabled, false)
    if (disabled && showActionBar.value) {
      showActionBar.value = false
    }
  },
)

// Set the new editor value, when it was changed from outside (e.G. form schema update).
const updateValueKey = props.context.node.on('input', ({ payload: value }) => {
  const currentValue =
    contentType.value === 'text/plain'
      ? editor.value?.getText()
      : editor.value?.getHTML()
  if (editor.value && value !== currentValue) {
    editor.value.commands.setContent(value, false)
  }
})

onUnmounted(() => {
  props.context.node.off(updateValueKey)
})

const focusEditor = () => {
  const view = editor.value?.view
  view?.focus()
}

// focus editor when clicked on its label
useEventListener('click', (e) => {
  const label = document.querySelector(`label[for="${props.context.id}"]`)
  if (label === e.target) focusEditor()
})

// insert signature before full article blockquote or at the end of the document
const resolveSignaturePosition = (editor: Editor) => {
  let blockquotePosition: number | null = null
  editor.state.doc.descendants((node, pos) => {
    if (node.type.name === 'blockquote' && node.attrs['data-full']) {
      blockquotePosition = pos
      return false
    }
  })
  if (blockquotePosition !== null) {
    return { position: 'top', from: blockquotePosition }
  }
  return { position: 'bottom', from: editor.state.doc.content.size || 0 }
}

const addSignature = (signature: PossibleSignature) => {
  if (!editor.value || editor.value.isDestroyed || !editor.value.isEditable)
    return
  const currentPosition = editor.value.state.selection.anchor
  const positionFromEnd = editor.value.state.doc.content.size - currentPosition
  // don't use "chain()", because we change positions a lot
  // and chain doesn't know about it
  editor.value.commands.removeSignature()
  const { position, from } = resolveSignaturePosition(editor.value)
  editor.value.commands.addSignature({ ...signature, position, from })
  // calculate new position from the end of the signature otherwise
  editor.value.commands.focus(
    signature.position ??
      (currentPosition < from
        ? currentPosition
        : editor.value.state.doc.content.size - positionFromEnd),
  )
  requestAnimationFrame(() => {
    testFlags.set('editor.signatureAdd')
  })
}

const removeSignature = () => {
  if (!editor.value || editor.value.isDestroyed || !editor.value.isEditable)
    return
  const currentPosition = editor.value.state.selection.anchor
  editor.value.chain().removeSignature().focus(currentPosition).run()
  requestAnimationFrame(() => {
    testFlags.set('editor.removeSignature')
  })
}

const characters = computed(() => {
  if (!editor.value) return 0
  return editor.value.storage.characterCount.characters({
    node: editor.value.state.doc,
  })
})

const editorCustomContext = {
  _loaded: true,
  getEditorValue: (type: EditorContentType) => {
    if (!editor.value) return ''

    return type === 'text/plain'
      ? editor.value.getText()
      : editor.value.getHTML()
  },
  addSignature,
  removeSignature,
  focus: focusEditor,
}

Object.assign(props.context, editorCustomContext)

onMounted(() => {
  const onLoad = props.context.onLoad as ((
    context: FieldEditorContext,
  ) => void)[]
  onLoad.forEach((fn) => fn(editorCustomContext))
  onLoad.length = 0
})
</script>

<template>
  <div class="p-2">
    <EditorContent
      ref="editorVueInstance"
      data-test-id="field-editor"
      :editor="editor"
    />
    <FieldEditorFooter
      v-if="context.meta?.footer && !context.meta.footer.disabled && editor"
      :footer="context.meta.footer"
      :characters="characters"
    />
  </div>

  <!-- TODO: questionable usability - it moves, when new line is added -->
  <FieldEditorActionBar
    :editor="editor"
    :content-type="contentType"
    :visible="showActionBar"
    :disabled-plugins="disabledPlugins"
    @hide="showActionBar = false"
    @blur="focusEditor"
  />
</template>
