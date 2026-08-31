// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { ANSWER_EDITOR_TOOLS } from '#desktop/entities/knowledge-base/utils/answerEditorTools.ts'

import { answerVisibilityOptions } from '../form/answerVisibilityOptions.ts'

interface AnswerFormSchemaOptions {
  // The create and edit views each teleport the title field into their header - a container of
  //   its own, per the 2026-08-26 UX decision that moved it out of the content column. Same
  //   mechanism and same reason as sidebarFieldsTarget below: one form id, wherever its fields
  //   end up rendering.
  titleFieldTarget: string
  // The create and edit views each teleport the sidebar fields (visibility, categoryId) into a
  //   container of their own - this is that container's target selector.
  sidebarFieldsTarget: string
  // Which of the two forms this is - the only thing their field sets differ in, so nothing more
  //   specific is worth asking a caller for: `tags` is create-only, an existing answer being
  //   tagged from its sidebar instead, next to the live Related Tickets list.
  //
  // `visibility` is in both (2026-08-28 clarification of the story's visibility decision): what
  //   the create form leaves out is the *scheduling* of it, which is a sidebar widget of its own
  //   and edit-only - a state to schedule needs an answer to schedule it for.
  edit: boolean
}

// Shared between the create and edit forms: `body`, `attachments` in the content column, `title`
//   teleported into the header, `visibility` and `categoryId` into the sidebar. Callers differ only
//   in where the title and sidebar fields teleport to, and in whether this is the edit form.
export const useAnswerFormSchema = ({
  titleFieldTarget,
  sidebarFieldsTarget,
  edit,
}: AnswerFormSchemaOptions) => {
  const application = useApplicationStore()

  // Whether the `tags` field below offers creating one that does not exist yet, which follows the
  //   `tag_new` setting like the object attribute resolver does for ticket forms. Decided here
  //   rather than taken as an option: it belongs to that field, and only a form that *has* the
  //   field has any use for it.
  //
  // A ref, because the schema is built once and the field's `canCreate` prop is what keeps it live
  //   afterwards - FormKit unwraps a ref prop and re-renders on change. Reading a store is also
  //   what makes this a composable rather than a plain builder.
  const canCreateTags = computed(() => Boolean(application.config.tag_new))

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
  return defineFormSchema([
    {
      // The title lives in the header now (2026-08-26 UX decision), teleported out exactly like
      //   the sidebar fields below - the form keeps a single id, and with it a single auto-save
      //   and upload cache, despite rendering across three different places on screen. No visible
      //   label (the header shows it inline without one), but `labelSrOnly` keeps it an
      //   accessible name for assistive tech - a bare input is not acceptable.
      isLayout: true,
      component: 'Teleport',
      props: {
        to: titleFieldTarget,
        // Same reasoning as the sidebar Teleport below: deferring resolves the target at the end
        //   of the render cycle, by which time the header has already rendered its container.
        defer: true,
      },
      children: [
        {
          isLayout: true,
          component: 'FormGroup',
          props: {
            showDirtyMark: edit,
          },
          children: [
            {
              name: 'title',
              label: __('Title'),
              labelSrOnly: true,
              type: 'text',
              placeholder: __('Answer title'),
              required: true,
            },
          ],
        },
      ],
    },
    {
      isLayout: true,
      component: 'FormGroup',
      props: {
        showDirtyMark: edit,
      },
      children: [
        {
          name: 'body',
          label: __('Text'),
          type: 'editor',
          required: true,
          props: {
            meta: ANSWER_EDITOR_TOOLS,
          },
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
        ...(edit
          ? []
          : [
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
            ]),
      ],
    },
    {
      // The same mechanism the ticket detail view uses to render the attributes of its edit form
      //   into the sidebar (TicketDetailViewContent.vue): a layout node that teleports its children
      //   out of the form's DOM, while they stay part of the form.
      isLayout: true,
      component: 'Teleport',
      props: {
        to: sidebarFieldsTarget,
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
          props: {
            showDirtyMark: edit,
          },
          children: [
            {
              // The state the answer is in, which takes effect as soon as it is saved - the form
              //   carries no date to go with it, and a transition scheduled for later is managed
              //   apart from it (edit only, so a create form shows this field and nothing about
              //   scheduling).
              //
              // The updater seeds the initial value (`draft` for a create, the answer's own state
              //   for an edit) - nothing to enforce here. Where the labels come from is documented
              //   on answerVisibilityOptions.
              name: 'visibility',
              label: __('Visibility'),
              type: 'radioList',
              props: {
                // Shared with the schedule flyout, which offers the same set minus `draft`.
                options: answerVisibilityOptions,
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
}
