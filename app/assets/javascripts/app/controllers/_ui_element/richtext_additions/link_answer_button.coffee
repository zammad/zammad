# coffeelint: disable=camel_case_classes
class App.UiElement.richtext.toolButtons.link_answer extends App.UiElement.richtext.additions.RichTextToolButtonLink
  @icon: 'knowledge-base-answer'
  @text: 'Link Answer'
  @klass: -> App.UiElement.richtext.additions.RichTextToolPopupAnswer
  @initializeAttributes:
    model:
      configure_attributes: [
        {
          name: 'link'
          display: 'Answer'
          relation: 'KnowledgeBaseAnswerTranslation'
          tag: 'autocompletion_ajax'
        }
      ]
