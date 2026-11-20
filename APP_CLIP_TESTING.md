# App Clip testing

Open `Incoming2.xcworkspace`. Run the **Incoming2** scheme and sign in with a test performer account. Under **Settings → App Clip Settings**, save a force word such as `Rose` and a different caller name such as `Alex`. Tap **Copy Link**.

To start the Clip, select the **IncomingClip** scheme, then **Product → Scheme → Edit Scheme → Run → Arguments**. Set the enabled environment variable `_XCAppClipURL` to the entire copied link, including its `?t=` query. Run on an iPhone simulator or test iPhone. Relaunch the Clip after changing performer settings to start a new session.

| Check | Expected result |
|---|---|
| Open with a blank Inject User ID | Standard Notes shows Rose and a dim Share icon. Long-pressing Share leaves the note open. |
| Edit the note and perform the two triple-taps | The screen stays black for five seconds after the second triple-tap, then the call shows the saved caller Alex. Sliding to answer returns to the edited note after Call Failed. |
| Save your Inject User ID under Inject Input, update the Inject selection, and relaunch the Clip | Share is visible. Long-pressing it previews the current selection. |
| Choose Close, then perform | The caller is still Alex. |
| Long-press Share, choose Use, and perform | The call shows the accepted selection. The note keeps its own text. |
| Start a fresh Clip session | The saved performer caller name applies again. |
| Clear the Inject User ID, save, and open a fresh session | The standard Share icon is dim and Inject lookup is off. |
| Reset the test performer's password under Users in the admin site | The old password stops working. The performer can sign in with the new password. |

In the main app, open **Dashboard → Notes Input**. Change the caller name from Alex to Jamie and save. The name should stay in the editor with no confirmation footer. Reopen Notes Input to verify Jamie was saved. Open the same App Clip link again and perform without selecting an Inject value. The note should show Rose and the reveal should show Jamie.

Use a physical iPhone to check vibration and NFC. In the main app, open **Settings → App Clip Settings → Write NFC Tag** and hold a writable tag near the phone. Use a second iPhone configured for the corresponding App Clip experience to verify the card and launch.

## Test account-specific presentations and settings

Use two test accounts. In the server's `wrangler.toml`, `PLAIN_PRESENTATION_ACCOUNT` selects the plain editor and name reveal. It is currently set to public User ID `105`.

1. Sign in as `105`, save a note and caller name, and copy its App Clip link. Repeat with a second performer account, using a different note and caller name. If testing Inject, give each account its own Inject ID and set a distinct selection in each provider account.
2. Open each link on the same iPhone in turn. Each note and caller name should match the performer who created the link. With Inject enabled, use **Get caller name** in plain Notes or long-press **Share** in standard Notes to check that performer's selection.
3. Triple-tap the note, triple-tap the black screen, and wait five seconds. The link for `105` shows a black name on white. Tap to return. The other link shows the standard simulated incoming call.
4. Clear the caller name or Inject ID on one account, save, and reopen both links. The other account should retain its own settings.

For App Review, provide a test login and complete App Clip link for each presentation. Include the gestures above in Notes for Review so the reviewer can reproduce both flows.
