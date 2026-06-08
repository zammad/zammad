# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AITextToolTranslate < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    translate

  end

  private

  def translate
    AI::TextTool.create_if_not_exists(
      name:          'Translate section to English',
      instruction:   "You are a text translation AI assistant.

You are given a text in HTML format or simple plain text.

Your task is to translate the content into English.

Follow these rules:
- Never translate technical elements such as commands, code snippets, function names, file paths, URLs, API names, environment variables, or identifiers.
- Correct only the text content, neither the HTML tags nor the given structure.
- Always preserve all HTML tags and formatting exactly as in the original text.",
      note:          'Example translation tool. Duplicate and adapt it to change or add languages.',
      active:        false,
      updated_by_id: 1,
      created_by_id: 1
    )
  end
end
