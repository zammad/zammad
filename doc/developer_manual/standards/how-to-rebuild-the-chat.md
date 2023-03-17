# How to Rebuild the Chat

The chat related code lived in [public/assets/chat](/public/assets/chat).

After any changes, the chat must be rebuilt to static files. There are two builds of the chat,
one version which uses JQuery and one without. The look and feel is the same for both.

## Code changes

The javascript code changes should be done in the following files, for the solution with JQuery and without:

- [public/assets/chat/chat.coffee](/public/assets/chat/chat.coffee)
- [public/assets/chat/chat-no-jquery.coffee](/public/assets/chat/chat-no-jquery.coffee)

The chat assets then need to be regenerated via gulp, which is explained in [public/assets/chat/README.md](/public/assets/chat/README.md).

## Manual Testing

First you need to generate the Javascript-Files after you changed something in the Coffee-Script files.

For testing, you can use the HTML-files which are used in the chat tests:

- [public/assets/chat/znuny.html](/public/assets/chat/znuny.html)
- [public/assets/chat/znuny-no-jquery.html](/public/assets/chat/znuny-no-jquery.html)

## Selenium Testing

For selenium two browser tests exist, one for the version with JQuery and one without JQuery.
The improvements for the tests needs to be done in both files.

## Backporting to stable

Don't forget to recompile Chat assets when backporting a fix to `stable`. Git does not track compiled files changes well.
