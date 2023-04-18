# giellakbd-ios

An open source reimplementation of Apple's native iOS keyboard with a specific focus on support for localised keyboards and support for minority and indigenous languages.


## Building & Running

##### Note: the first build will take a while.

1. [Install Cocoapods](https://cocoapods.org/)
2. `pod install`
3. Open `GiellaKeyboard.xcworkspace`
4. From the target menu in Xcode, select `HostingApp`
5. Run
6. Follow the instructions to enable the keyboard on your device/simulator
7. After enabling, open an app that uses the keyboard, such as Messages, and tap a text field to bring up the keyboard
8. Tap and hold the globe button in the bottom left corner of the keyboard and select "Template Keyboard"
9. Done. You should now see the Divvun nordsamisk keyboard

## Sentry

To enable Sentry, add a `SentryDSN` key to the `HostingApp/Supporting Files/Info.plist` file.

### Updating localisations

```
npm i -g technocreatives/i18n-eller
i18n-eller generate swift Support/Strings/en.yaml Support/Strings/*.yaml -o HostingApp
```

If you add a new locale, please open an issue to have it added to the language list inside the app.

## Keyboard layouts

This repo does not include any keyboard layouts. It is intended to be used as a template for [kbdgen](https://github.com/divvun/kbdgen), which consumes among other things this codebase, as well as layouts as listed in e.g. [divvun-keyboard](https://github.com/divvun/divvun-keyboard) to produce the actual keyboard app. The keyboard layout specifications are found in the [GiellaLT](https://github.com/giellalt?q=keyboard-&type=&language=) organisation.

## License

`giellakbd-ios` is licensed under either of

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

