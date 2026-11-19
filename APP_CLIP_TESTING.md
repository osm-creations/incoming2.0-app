# App Clip testing

Open `Incoming2.xcworkspace`. Run the **Incoming2** scheme and sign in with a test performer account. Under **Settings → App Clip Settings**, save a force word such as `Rose` and a different caller name such as `Alex`. Tap **Copy Link**.

To start the Clip, select the **IncomingClip** scheme, then **Product → Scheme → Edit Scheme → Run → Arguments**. Set the enabled environment variable `_XCAppClipURL` to the entire copied link, including its `?t=` query. Run on an iPhone simulator or test iPhone. Relaunch the Clip after changing performer settings to start a new session.

| Check | Expected result |
|---|---|
| Open with a blank Inject User ID | Notes shows Rose and the Share button is hidden. |
| Edit the note and perform the two triple-taps | The screen stays black for five seconds after the second triple-tap, then the call shows the saved caller Alex. Sliding to answer returns to the edited note after Call Failed. |
| Save your Inject User ID under Inject Input, update the Inject selection, and relaunch the Clip | Share is visible. Long-pressing it previews the current selection. |
| Choose Close, then perform | The caller is still Alex. |
| Long-press Share, choose Use, and perform | The call shows the accepted selection. The note keeps its own text. |
| Start a fresh Clip session | The saved performer caller name applies again. |
| Clear the Inject User ID, save, and open a fresh session | Share is hidden. |
| Reset the test performer's password under Users in the admin site | The old password stops working. The performer can sign in with the new password. |

Use a physical iPhone to check vibration and NFC. In the main app, open **Settings → App Clip Settings → Write NFC Tag** and hold a writable tag near the phone. Use a second iPhone configured for the corresponding App Clip experience to verify the card and launch.

## Test both presentations with one account

After deploying the updated Worker, set its `PLAIN_PRESENTATION_ACCOUNT` text variable to the performer's email or the exact **User ID** shown in **Settings → Account**. Open **Notes Input** and confirm the plain editor loads. Type and save a note, then reopen it to check the saved text.

Open that account's App Clip link. Triple-tap inside the note, then triple-tap the black screen. After five seconds the caller name appears in black on white. Tap the name screen to return to the edited note.

In the App Clip note, tap **Use standard presentation** and repeat the gestures to see the standard Notes layout and simulated incoming call. Reopening the link starts a fresh plain session. The main app's Notes Input has the same choice for its own editor.

For App Review, include the demo login, its complete App Clip link, and the steps above in Notes for Review.
