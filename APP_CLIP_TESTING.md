# App Clip testing

Open `Incoming2.xcworkspace`. Run the **Incoming2** scheme and sign in with a test performer account. Under **Settings → App Clip Settings**, save a force word such as `Rose` and a different caller name such as `Alex`. Start with a 5-second reveal delay and tap **Set & Save**. Tap **Copy Link**.

To start the Clip, select the **IncomingClip** scheme, then **Product → Scheme → Edit Scheme → Run → Arguments**. Set the enabled environment variable `_XCAppClipURL` to the entire copied link. Newly written tags use compact links under `/c/`. If testing an older link, retain its full `?t=` query. Run on an iPhone simulator or test iPhone. Relaunch the Clip after changing performer settings to start a new session.

| Check | Expected result |
|---|---|
| Open with a blank Inject User ID | Standard Notes shows Rose. Holding the checklist leaves the note open. |
| Edit the note on an iPhone, double-tap it, then press Volume Up | The screen turns black with one vibration, waits for the saved delay after Volume Up, then shows the saved caller Alex. Sliding to answer returns to the edited note after Call Failed. |
| While editing, tap Aa, edit the first nonempty line to Jamie, and perform | The call shows Jamie. With Aa switched off, the previous caller name applies again. |
| Save your Inject User ID in Settings, update the Inject selection, and relaunch the Clip | Holding the checklist previews the current selection with the keyboard open or closed. Holding Share leaves the note open. |
| Choose Close, then perform | The caller is still Alex. |
| Press and hold the checklist, choose Use, and perform | The call shows the accepted selection, including when Aa was previously active. The note keeps its own text. |
| Start a fresh Clip session | The saved performer caller name applies again. |
| Clear the Inject User ID, save, and open a fresh session | Holding the checklist leaves the note open. |
| Reset the test performer's password under Users in the admin site | The old password stops working. The performer can sign in with the new password. |

In the main app, open **Dashboard → Notes Input**. Change the caller name from Alex to Jamie and save. The name should stay in the editor with no confirmation footer. Reopen Notes Input to verify Jamie was saved. Open the same App Clip link again and perform without selecting an Inject value. The note should show Rose and the reveal should show Jamie.

Use a physical iPhone with haptics enabled. Start with media volume near the middle. The Clip listens for changes in output volume. At maximum volume, press Volume Down before starting with Volume Up. Buttons retain their normal volume behavior. The Clip draws no volume bar or countdown digits. iOS may show its transient system volume indicator.

With a five-second delay, run each of these checks with both demo accounts.

| Action on the black screen | Expected result |
|---|---|
| Press Volume Down before starting, then wait six seconds | The screen stays black. |
| Press Volume Up, wait two seconds, then press Volume Down and wait six seconds | The countdown is canceled. Pressing Volume Up starts all five seconds again. |
| Press Volume Up, wait two seconds, and press Volume Up again | The reveal occurs five seconds after the last press. |
| Swipe down with two fingers before or during the countdown | One vibration, then the same edited note reopens. Any pending reveal is canceled. |
| Tap once or swipe down with one finger | The screen stays black. |
| Move the Clip to the background mid-countdown, then return | The Clip waits for a fresh Volume Up. |

Save delays of 0 and 60 seconds in the performer app and reopen the same App Clip link after each save. At 0, Volume Up reveals immediately. At 60, wait the full minute. To check NFC, open **Settings → App Clip Settings → Write NFC Tag** and hold a writable tag near the phone. Use a second iPhone configured for the corresponding App Clip experience to verify the card and launch.

## Test account-specific presentations and settings

Use two test accounts. In the server's `wrangler.toml`, `PLAIN_PRESENTATION_ACCOUNT` selects the plain editor and name reveal. It is currently set to public User ID `105`.

1. Sign in as `105`, save a note and caller name, and copy its App Clip link. Repeat with a second performer account, using a different note and caller name. If testing Inject, give each account its own Inject ID and set a distinct selection in each provider account.
2. Open each link on the same iPhone in turn. Each note and caller name should match the performer who created the link. With Inject enabled, use **Get caller name** in plain Notes or hold the **checklist** in standard Notes to check that performer's selection. Tap **Tools → Use note as caller name** in plain Notes or **Aa** while editing in standard Notes to use that note’s first nonempty line.
3. Double-tap the note, press Volume Up, and wait for that performer’s saved delay. The link for `105` shows a black name on white. Tap to return. The other link shows the standard simulated incoming call.
4. Clear the caller name or Inject ID on one account, save, and reopen both links. The other account should retain its own settings.

For App Review, provide a test login and complete App Clip link for each presentation. Include the gestures above in Notes for Review so the reviewer can reproduce both flows.
