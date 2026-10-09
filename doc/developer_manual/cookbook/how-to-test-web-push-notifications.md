# How to Test Web Push Notifications

Agents can receive online notifications as web push messages on their devices, through the mobile view installed as an
app. Push only works under conditions the default development stack does not meet: a real device, HTTPS with a
certificate the device trusts, and a service worker, which development mode leaves out. This guide sets them up.

## What You Need

- A device that supports web push for installed web apps: an iPhone or iPad with iOS/iPadOS 16.4 or later, or an
  Android device with Chrome. A desktop browser works for most checks, but not for the installed-app behaviour.
- A way for the device to reach the development stack over HTTPS with a certificate it trusts, see step 1.
- An agent user. The toggle needs both `ticket.agent` and `user_preferences.notifications`, which every agent has by
  default.
- Outgoing internet access from the development machine, as the backend delivers through the push services of Apple,
  Google, Mozilla or Microsoft.

The key pair for signing pushes (VAPID) is created by a migration, so a migrated development database already has it.

## 1. Serve the Stack Over Trusted HTTPS

iOS installs no service worker and refuses to subscribe when it does not trust the certificate, so a self-signed one
is not enough. Any setup works that gives the device an HTTPS address of the stack with a certificate it trusts.
Common options:

- **Certificate from a local certificate authority**, for example created with
  [mkcert](https://github.com/FiloSottile/mkcert), for the name and address the device uses to reach your machine in
  the same network. The device has to trust that authority: on iOS install its root certificate as a profile and turn
  on full trust under Settings → General → About → Certificate Trust Settings, on Android install it as a CA
  certificate in the security settings.
- **[Tailscale](https://tailscale.com/kb/1153/enabling-https)** with the device in the same tailnet. Its machine names
  under `ts.net` get publicly trusted certificates, either served by `tailscale serve` or issued with `tailscale cert`.
  Nothing has to be installed on the device apart from the Tailscale app.
- **A tunnel** such as [ngrok](https://ngrok.com/) or Cloudflare Tunnel, which gives the stack a public HTTPS address.
  The device needs no setup, but the stack is reachable from the internet while the tunnel runs.

When the stack terminates HTTPS itself, with a certificate from a local authority or from `tailscale cert`, put the
certificate and its key as `localhost.crt` and `localhost.key` into `~/.local/state/localhost.rb/`. Puma, Vite and the
websocket server all read them from there.

> [!WARNING]
> Running the RSpec suite regenerates `localhost.crt` and `localhost.key` with a self-signed certificate. Keep a copy
> of your files and copy them back after a test run, otherwise the device rejects the stack again.

## 2. Start the Stack

With a certificate in `~/.local/state/localhost.rb/`, start the stack with HTTPS and reachable from the network:

```screen
env -u VITE_TEST_MODE ZAMMAD_BIND_IP=0.0.0.0 pnpm dev:https
```

Behind `tailscale serve` or a tunnel, which terminate HTTPS themselves, start it with `pnpm dev` instead and point them
to port 3000. In both cases `VITE_TEST_MODE` must not be set, it turns the service worker into a no-op.

Open the HTTPS address of the stack with the path `/mobile/` on the device. If the browser warns about the certificate,
step 1 is not complete.

## 3. Build the Service Worker

Development mode serves the service worker from a build artefact, not from Vite. Build it once, and again after every
change to `app/frontend/apps/mobile/sw/sw.ts` or the files it imports:

```screen
env -u VITE_TEST_MODE RAILS_ENV=development bundle exec vite build --mode development
```

Rails then serves the result from `public/assets/frontend/vite-dev/sw.js` as `/mobile/sw.js`.

In development, the app registers the service worker only when it runs installed from the home screen, as such an app
has no console to enable it. In a desktop browser, enable it in the console and reload, and remove it again when you
are done, so it does not interfere with other work:

```screen
sw.allow()
sw.unregister()
```

## 4. Install the App and Turn On Push

- **iOS:** open the address in Safari, tap Share → Add to Home Screen, and open the app from the home screen. On iOS,
  push is only available in the installed app, a Safari tab shows the toggle locked with a hint.
- **Android:** open the address in Chrome and install the app from the menu.

Log in as an agent, open the account page and turn on "Push notifications on this device". When the toggle stays
locked, the text below it names what is missing.

## 5. Send a Push

Every new online notification is sent to all devices on which the recipient turned on push. Create one for a ticket
the agent can see:

```screen
RAILS_ENV=development bundle exec rails r '
  agent  = User.find_by!(email: "agent@example.com")
  ticket = Ticket.where(group: agent.groups_access("full")).last
  OnlineNotification.add(type: "update", object: "Ticket", o_id: ticket.id, seen: false,
                         user_id: agent.id, created_by_id: 1)
'
```

No push is sent when the notification is already seen, when the agent cannot see the ticket, or while the agent had
contact in the desktop app within the last five minutes. Close desktop tabs of the same agent, or wait, before you
test.

## Debugging

- **Delivery:** the background worker logs every run of `WebPushNotificationJob`, and every failed or rejected push
  with its reason as `Web push to subscription …`:
  `grep -E 'WebPushNotificationJob|Web push to subscription' log/development.log`.
- **Subscriptions:** `PushSubscription.where(user: agent)` in the Rails console lists the registered devices. A
  subscription the push service reports as gone is removed on the next delivery.
- **Console of the installed app on iOS:** connect the device by cable, turn on Settings → Apps → Safari → Advanced → Web
  Inspector, and open Develop → your device → the app in Safari on the Mac. After the app was closed, pick the newest
  entry, the old one shows stale values.
- **Console of the installed app on Android:** turn on USB debugging in the developer options of the device, connect
  it by cable and open `chrome://inspect/#devices` in Chrome on the computer. The installed app and its service
  worker are listed there with an inspect link.
- **Service worker in a desktop browser:** the application or storage tab of the developer tools shows the registered
  worker and lets you send a test push to it.

## Platform Behaviour Worth Knowing

- iOS reports notifications turned off in its settings as not asked yet (`default`), not as `denied`.
- iOS sends no `notificationclick` to an installed app that was started from its icon and runs in the background. The
  app detects the tapped push on its own when it comes back to the front, see
  `app/frontend/shared/sw/shownPushNotifications.ts`.
- iOS ignores the `tag` of a web push, so several pushes about the same ticket stay as separate notifications.
- iPhones and iPads below version 16.4 have no web push at all.
