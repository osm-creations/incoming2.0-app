# App Clip testing

Open `Incoming2.xcworkspace`. Run the **Incoming2** scheme and sign in with a test performer account. Under **Settings → App Clip Settings**, save a force word such as `Rose` and a different caller name such as `Alex`. Tap **Copy Link**.

To start the Clip, select the **IncomingClip** scheme, then **Product → Scheme → Edit Scheme → Run → Arguments**. Set the enabled environment variable `_XCAppClipURL` to the entire copied link, including its `?t=` query. Run on an iPhone simulator or test iPhone. Relaunch the Clip after changing performer settings to start a new session.

| Check | Expected result |
|---|---|
| Open with a blank Inject ID | Notes shows Rose and the Share button is hidden. |
| Edit the note and perform the two triple-taps | The call shows the saved caller Alex. Sliding to answer returns to the edited note after Call Failed. |
| Save your 11z user ID under Inject Input, update the selection in 11z, and relaunch the Clip | Share is visible. Long-pressing it previews the current selection. |
| Choose Close, then perform | The caller is still Alex. |
| Long-press Share, choose Use, and perform | The call shows the accepted selection. The note keeps its own text. |
| Start a fresh Clip session | The saved performer caller name applies again. |
| Clear the 11z ID, save, and open a fresh session | Share is hidden. |
| Reset the test performer's password under Users in the admin site | The old password stops working. The performer can sign in with the new password. |

Use a physical iPhone to check vibration and NFC. In the main app, open **Settings → App Clip Settings → Write NFC Tag** and hold a writable tag near the phone. Use a second iPhone configured for the corresponding App Clip experience to verify the card and launch.
