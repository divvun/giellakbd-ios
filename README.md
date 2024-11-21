# giellakbd-ios

An open source reimplementation of Apple's native iOS keyboard with a specific focus on support for localised keyboards and support for minority and indigenous languages.


## Building & Running

##### Note: the first build will take a while.

1. [Install Cocoapods](https://cocoapods.org/)
2. `pod install`. This may fail. If it does - see rexml solution below
3. Open `GiellaKeyboard.xcworkspace`
4. From the target menu in Xcode, select `HostingApp`
5. Run
6. Follow the instructions to enable the keyboard on your device/simulator
7. After enabling, open an app that uses the keyboard, such as Messages, and tap a text field to bring up the keyboard
8. Tap and hold the globe button in the bottom left corner of the keyboard and select "Template Keyboard"
9. Done. You should now see the Divvun nordsamisk keyboard

### Building Locally in Xcode 16.1

1. Apply all the changes found in [this commit](https://github.com/divvun/giellakbd-ios/commit/a9d0112d2b710130e82c17801b0b5315e8cae0d2#diff-53c0193e8eb071b0f176311374cb19a7ce0dce7cdfe1a11cd986989ca835ce63L1) (remove Sentry, typealias SQLite.Expression)
2. Remove the `-framework` and `"Sentry"` flags from the Other Linker Flags section in the project build settings

Now it should build. You may need to run `pod install` as well. Remember not to commit these changes. An actual fix will need to happen when the build system's version of Xcode is upgraded.

### rexml

Macos ships with a "broken" version of rexml.

If you error is "REXML::ParseException - #<TypeError: wrong argument type String (expected Regexp)>", you can try:

```bash
sudo gem install rexml -v 3.2.6
sudo gem uninstall rexml -v 3.2.9
```


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

## Deploying

Builds can be deployed using the [divvun-keyboard repo](https://github.com/divvun/divvun-keyboard)

## License

`giellakbd-ios` is licensed under either of

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

