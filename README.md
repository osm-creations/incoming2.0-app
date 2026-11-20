# Incoming 2.0

Open `Incoming2.xcworkspace` in Xcode. The shared schemes are `Incoming2` for the magician’s app and `IncomingClip` for the spectator’s App Clip. Both target iOS 17 or later and use the deployed Incoming API.

## Set up a performance

1. Sign in with the user ID or email and password supplied by the administrator.
2. Open **Settings → App Clip Settings**. Enter the force word or note and the caller name. Tap **Set & Save**. **Notes Input** on the dashboard lets you change the saved caller name independently.
3. To use a live selection, open **Inject Input**, enter your **Inject User ID** and tap **Save**. Clear the ID and save to turn off Inject for the next App Clip session.
4. Return to **App Clip Settings** and choose **Copy Link** or **Write NFC Tag**. Use the signed link for this performer.

## Perform

The Clip opens to an editable note. With Inject enabled, long-press **Share** to preview the current Inject selection. **Use** sets the caller name for this performance. **Close** keeps the previous name. Both choices preserve the note and the performer’s saved settings.

Triple-tap the note to enter the black screen. Triple-tap the black screen again. The simulated incoming call appears five seconds after this second triple-tap. Slide to answer to show **Call Failed** and return to the note. The call uses vibration on supported iPhones.

See [App Clip testing](APP_CLIP_TESTING.md) for the simulator and device checks.
