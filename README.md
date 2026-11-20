# Incoming 2.0

Open `Incoming2.xcworkspace` in Xcode. The shared schemes are `Incoming2` for the magician’s app and `IncomingClip` for the spectator’s App Clip. Both target iOS 17 or later and use the deployed Incoming API.

## Set up a performance

1. Sign in with your user ID or email and password. Your welcome email contains your user ID, a temporary password and a 7-day setup link. For a new one-hour reset link, choose **Forgot password?** on the login screen and enter your account email.
2. Open **Settings → App Clip Settings**. Enter the force word or note, the caller name, and a reveal delay from 0 to 60 seconds. New accounts start at 5 seconds. Tap **Set & Save**. **Notes Input** on the dashboard lets you change the saved caller name independently.
3. To use a live selection, open **Settings**, enter your **Inject User ID** and tap **Save**. Clear the ID and save to turn off Inject for the next App Clip session.
4. Return to **App Clip Settings** and choose **Copy Link** or **Write NFC Tag**. New tags use a compact link for this performer. On an updated App Clip you can also open tags written by older versions.

## Perform

The Clip opens to an editable note. Tap **Aa** while editing to use the first nonempty line of the note as the caller name. Further edits to that line carry through to the reveal. Tap **Aa** again to return to the previous name. In plain Notes, use **Tools → Use note as caller name**.

With Inject enabled, press and hold the **checklist** icon next to **Aa** to preview the current Inject selection. The same checklist works with the keyboard closed. In plain Notes, tap **Get caller name**. **Use** selects the Inject name for this performance. **Close** preserves the current caller-name choice. These choices apply only to the active App Clip session.

Triple-tap the note to enter the black screen. Press either iPhone volume button once to start the saved delay. At maximum volume use Volume Down, and at minimum use Volume Up. A supported iPhone gives one haptic pulse when the screen goes black and one when the countdown starts. A delay of 0 reveals immediately. Slide to answer the simulated call, or tap the name in the plain presentation, to return to the note.

See [App Clip testing](APP_CLIP_TESTING.md) for the simulator and device checks.
