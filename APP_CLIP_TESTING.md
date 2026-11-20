# App Clip testing

Open `Incoming2.xcworkspace`. Run the **Incoming2** scheme and sign in with a test performer account. Under **Settings → App Clip Settings**, save a force word such as `Rose` and a different caller name such as `Alex`. Start with a 5-second reveal delay and tap **Set & Save**. Tap **Copy Link**.

To start the Clip, select the **IncomingClip** scheme, then **Product → Scheme → Edit Scheme → Run → Arguments**. Set the enabled environment variable `_XCAppClipURL` to the entire copied link, including its `?t=` query. Run on an iPhone simulator or test iPhone. Relaunch the Clip after changing performer settings to start a new session.

| Check | Expected result |
|---|---|
| Open with a blank Inject User ID | Standard Notes shows Rose. Holding the checklist leaves the note open. |
| Edit the note on an iPhone, triple-tap it, then press a volume button that changes the media volume | The screen turns black on the triple-tap, stays black for the saved delay after the volume change, then shows the saved caller Alex. Sliding to answer returns to the edited note after Call Failed. |
| While editing, tap Aa, edit the first nonempty line to Jamie, and perform | The call shows Jamie. With Aa switched off, the previous caller name applies again. |
| Save your Inject User ID in Settings, update the Inject selection, and relaunch the Clip | Holding the checklist previews the current selection with the keyboard open or closed. Holding Share leaves the note open. |
| Choose Close, then perform | The caller is still Alex. |
| Press and hold the checklist, choose Use, and perform | The call shows the accepted selection, including when Aa was previously active. The note keeps its own text. |
| Start a fresh Clip session | The saved performer caller name applies again. |
| Clear the Inject User ID, save, and open a fresh session | Holding the checklist leaves the note open. |
| Reset the test performer's password under Users in the admin site | The old password stops working. The performer can sign in with the new password. |

In the main app, open **Dashboard → Notes Input**. Change the caller name from Alex to Jamie and save. The name should stay in the editor with no confirmation footer. Reopen Notes Input to verify Jamie was saved. Open the same App Clip link again and perform without selecting an Inject value. The note should show Rose and the reveal should show Jamie.

Use a physical iPhone with haptics enabled. Triple-tap inside the note to go black, then press either volume button once. At maximum volume press Volume Down, and at minimum press Volume Up. Each accepted step gives one haptic pulse. Additional presses during the countdown do not restart it. Tapping the black screen leaves it waiting.

Save delays of 0, 5, and 60 seconds in the performer app, reopening the same App Clip link after each save. Check for an immediate reveal at 0 and the selected wait at 5 and 60. Move the Clip to the background during a countdown. On returning to the black screen, a fresh volume change must be required. To check NFC, open **Settings → App Clip Settings → Write NFC Tag** and hold a writable tag near the phone. Use a second iPhone configured for the corresponding App Clip experience to verify the card and launch.

## Test account-specific presentations and settings

Use two test accounts. In the server's `wrangler.toml`, `PLAIN_PRESENTATION_ACCOUNT` selects the plain editor and name reveal. It is currently set to public User ID `105`.

1. Sign in as `105`, save a note and caller name, and copy its App Clip link. Repeat with a second performer account, using a different note and caller name. If testing Inject, give each account its own Inject ID and set a distinct selection in each provider account.
2. Open each link on the same iPhone in turn. Each note and caller name should match the performer who created the link. With Inject enabled, use **Get caller name** in plain Notes or hold the **checklist** in standard Notes to check that performer's selection. Tap **Tools → Use note as caller name** in plain Notes or **Aa** while editing in standard Notes to use that note’s first nonempty line.
3. Triple-tap the note, press either volume button to change the media volume, and wait for that performer’s saved delay. The link for `105` shows a black name on white. Tap to return. The other link shows the standard simulated incoming call.
4. Clear the caller name or Inject ID on one account, save, and reopen both links. The other account should retain its own settings.

For App Review, provide a test login and complete App Clip link for each presentation. Include the gestures above in Notes for Review so the reviewer can reproduce both flows.
