#  Zammad Localization

## Zammad GUI Translations - `i18n/*.po`

Zammad translations are managed exclusively via [translations.zammad.org](https://translations.zammad.org/).

You are welcome to contribute. Please get a free account there if you want to do so.

Any pull requests modifying translation files directly will be rejected.

## Zammad Text Modules - `i18n/text_modules/*.yml`

Zammad text modules are automatically imported when the first admin user is created, according to this user's language.
This is just meant to provide for a smooth start with some existing helpful text modules. They can be modified later on;
no subsequent import from the example files will be performed.

Feel free to send pull requests to add more helpful examples to existing files or even files for new languages.

## Zammad Chat - `public/assets/chat`

The Zammad chat currently has its own build pipeline and also a custom translation handling.
Messages and translations are directly baked into [chat.coffee](../public/assets/chat/chat.coffee) and have to be maintained
there.

## Zammad Notification Templates - `app/views/mailer/*`

Zammad contains a number of different notification templates which are currently stored directly in language-specific `ERB`
template files. Modifications of existing or addition of new translations must be made in these files directly.

# Developer Workflows

## Weblate Process Overview

- The codebase has a translation catalog file [i18n/zammad.pot](zammad.pot), which must be kept up-to-date.
- Weblate automatically picks this file up from git and updates its database. Now translators see the new/changed strings and can work on them.
- From time to time, Weblate pushes the new/updated translations via merge request to git.
- After the merge, the translation files in `i18n/zammad.*.po` are updated.
- Zammad will pick them up as soon as `Translation.sync` gets called, which happens for example during a package update.

## Updating the Source String Catalog

If changes to translatable strings are made during the development process, developers can just run the following to
re-extract the strings to the catalog file:

`rails generate translation_catalog`

This will update the `i18n/zammad.pot` file in Zammad. To do this for an existing addon module, call

`rails generate translation_catalog --addon-path /path/to/addon`

## Testing Translation Changes from Weblate

To test any changes made to translations in Weblate that are not yet published to Zammad,
you can use this workflow:

- Download the current state of the language from Weblate as po file.
- Save it locally in the Zammad folder as `i18n/zammad.pt-br.po` (for `pt-br` in this case, use corresponding file names for other languages).
- Run `rails r Translation.sync` to import the latest state to the database.
- Now the changes should appear in the GUI.

## Known Issues With Localization

- There is currently no support for plural forms.
