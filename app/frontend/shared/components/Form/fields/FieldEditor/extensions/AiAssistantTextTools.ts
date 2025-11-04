// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { Extension, Editor } from '@tiptap/core'
import { effectScope, ref, type Ref, watch } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useAiAssistanceTextToolsListQuery } from '#shared/components/Form/fields/FieldEditor/graphql/queries/aiAssistanceTextTools/aiAssistanceTextToolsList.api.ts'
import type { FieldEditorProps } from '#shared/components/Form/fields/FieldEditor/types.ts'
import {
  getHTMLContentBetweenSelection,
  updateSelectedContent,
} from '#shared/components/Form/fields/FieldEditor/utils.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import { useAiAssistanceTextToolsRunMutation } from '#shared/graphql/mutations/aiAssistanceTextToolsRun.api.ts'
import { convertToGraphQLId, ensureGraphqlId } from '#shared/graphql/utils.ts'
import { MutationHandler, QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useAiAssistantTextToolsStore } from '#shared/stores/aiAssistantTextTools.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import type { FormKitNode } from '@formkit/core'

const createAiTextToolsController = () => {
  let mutationCancelled = false

  const createAbortableMutation = () => {
    const abortController = new AbortController()
    const textToolsMutation = new MutationHandler(
      useAiAssistanceTextToolsRunMutation({
        context: { fetchOptions: { signal: abortController.signal } },
      }),
      {
        errorCallback: (error) => {
          return !(mutationCancelled && error.type === GraphQLErrorTypes.NetworkError)
        },
      },
    )

    return {
      textToolsMutation,
      isLoading: textToolsMutation.loading(),
      abort: () => abortController.abort(),
    }
  }

  return {
    mutation: createAbortableMutation(),
    get isCancelled() {
      return mutationCancelled
    },
    cancel: () => {
      mutationCancelled = true
    },
    reset: () => {
      mutationCancelled = false
    },
    recreate() {
      this.mutation = createAbortableMutation()
    },
  }
}

const createLoaderHandler = (editor: Editor) => ({
  showActionBarAndHideLoader: () => {
    editor.setEditable(true)
    editor.storage.showAiTextLoader = false
  },
  hideActionBarAndShowLoader: () => {
    editor.setEditable(false)
    editor.storage.showAiTextLoader = true
  },
})

const getFormRenderContext = async (context: Ref<FormFieldContext<FieldEditorProps>>) => {
  const { formId, ticketId, meta: editorMeta } = context.value
  const meta = editorMeta?.[PLUGIN_NAME] || {}

  let { customerId, groupId, organizationId } = context.value

  if (!customerId && meta.customerNodeName) {
    customerId = getNodeByName(formId, meta.customerNodeName)?.value as string
  }

  if (!organizationId && meta.organizationNodeName) {
    organizationId = getNodeByName(formId, meta.organizationNodeName)?.value as string
  }

  if (!groupId && meta.groupNodeName) {
    groupId = getNodeByName(formId, meta.groupNodeName)?.value as string
  }

  return {
    customerId: customerId ? ensureGraphqlId('User', customerId) : undefined,
    groupId: groupId ? ensureGraphqlId('Group', groupId) : undefined,
    organizationId: organizationId ? ensureGraphqlId('Organization', organizationId) : undefined,
    ticketId: ticketId ? ensureGraphqlId('Ticket', ticketId) : undefined,
  }
}

const sendTextToolsMutation = async (
  textToolId: ID,
  input: string,
  controller: ReturnType<typeof createAiTextToolsController>,
  context: Ref<FormFieldContext<FieldEditorProps>>,
) => {
  const contextData = await getFormRenderContext(context)

  const response = await controller.mutation.textToolsMutation.send({
    input,
    textToolId,
    templateRenderContext: contextData,
  })

  return response?.aiAssistanceTextToolsRun?.output
}

const setupEventHandlers = (
  editor: Editor,
  controller: ReturnType<typeof createAiTextToolsController>,
) => {
  const { notify } = useNotifications()

  editor.on('cancel-ai-assistant-text-tools-updates', () => {
    controller.cancel()
    controller.mutation.abort()
    controller.recreate()
    controller.reset()
  })

  editor.on('update', () => {
    if (controller.mutation.isLoading.value) {
      notify({
        id: 'ai-assistant-text-tools-aborted',
        type: NotificationTypes.Info,
        message: __('The text was modified. Your request has been aborted to prevent overwriting.'),
      })
      controller.mutation.abort()
      controller.recreate()
    }
  })
}

const executeTextModification = async (
  textToolId: ID,
  editor: Editor,
  context: Ref<FormFieldContext<FieldEditorProps>>,
) => {
  const loadingHandlers = createLoaderHandler(editor)
  const controller = createAiTextToolsController()

  const normalizedRange = editor.state.selection
  const input = getHTMLContentBetweenSelection(editor, normalizedRange)

  loadingHandlers.hideActionBarAndShowLoader()
  setupEventHandlers(editor, controller)

  try {
    const output = await sendTextToolsMutation(textToolId, input, controller, context)
    if (!output) return

    editor.chain().focus().setTextSelection(normalizedRange).run()
    updateSelectedContent(editor, output)
  } catch {
    editor?.chain().focus().setTextSelection(normalizedRange).run()
  } finally {
    loadingHandlers.showActionBarAndHideLoader()
    editor.chain().focus().run()
  }
}

export const PLUGIN_NAME = 'aiAssistantTextTools'

export default (context: Ref<FormFieldContext<FieldEditorProps>>) => {
  const { formId, ticketId, meta: editorMeta } = context.value
  const meta = editorMeta?.[PLUGIN_NAME] || {}
  let scope = effectScope()

  return Extension.create({
    name: PLUGIN_NAME,
    addStorage() {
      return {
        showAiTextLoader: false,
      }
    },
    onBeforeCreate({ editor }) {
      const { config } = useApplicationStore()

      watch(
        () => config.ai_assistance_text_tools,
        (newValue) => {
          if (!newValue) {
            if (scope.active) scope.stop()
            return
          }

          if (!scope.active) {
            scope = effectScope()
          }

          scope.run(() => {
            const textToolsStore = useAiAssistantTextToolsStore()

            const groupNode = getNodeByName(formId, meta.groupNodeName!) as FormKitNode<number>

            const groupId = ref<number>(groupNode?.value)

            groupNode?.on('commit', ({ payload }) => {
              groupId.value = payload
            })

            const queryHandler = new QueryHandler(
              useAiAssistanceTextToolsListQuery(() => ({
                groupId: groupId.value ? convertToGraphQLId('Group', groupId.value) : undefined,
                ticketId: ticketId ? convertToGraphQLId('Ticket', ticketId) : undefined,
              })),
            )

            queryHandler.watchOnResult(({ aiAssistanceTextToolsList }) => {
              if (!editor) return

              editor.emit('toggle-visibility', {
                name: PLUGIN_NAME,
                active: !!aiAssistanceTextToolsList.length,
              })
            })

            watch(
              () => groupId.value,
              (newGroupId, oldGroupId) => {
                // If the groupId changes, we deactivate the old one
                if (oldGroupId !== newGroupId) textToolsStore.deactivate(oldGroupId)

                textToolsStore.activate(newGroupId, queryHandler)
              },
              { immediate: true },
            )

            editor.on('destroy', () => textToolsStore.deactivate(groupId.value))
          })
        },
        { immediate: true },
      )
    },
    addCommands() {
      return {
        modifyTextWithAi:
          (textToolId) =>
          ({ editor }) => {
            executeTextModification(textToolId, editor, context)
            return true
          },
      }
    },
    addOptions() {
      return {
        permission: 'ticket.agent',
      }
    },
    onDestroy() {
      scope.stop()
    },
  })
}
