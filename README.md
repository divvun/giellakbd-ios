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

## Localization

Localization is automated via [Mozilla Pontoon](https://pontoon.mozilla.org/) and GitHub Actions. Translators use Pontoon to localize the strings in the app, which are synced automatically to the [giellakbd-ios-l10n repo](https://github.com/divvun/giellakbd-ios-l10n). A GitHub Action periodically imports new strings found in the giellakbd-ios-l10n into the Xcode project in this repo using [divvun/LocalizationTools](https://github.com/divvun/LocalizationTools). Likewise, a separate GitHub Action in the giellakbd-ios-l10n repo preiodically checks for any new strings added by a developer in the Xcode project and imports them into giellakbd-ios-l10n so they show up in Pontoon.

## Keyboard layouts

This repo does not include any keyboard layouts. It is intended to be used as a template for [kbdgen](https://github.com/divvun/kbdgen), which consumes among other things this codebase, as well as layouts as listed in e.g. [divvun-keyboard](https://github.com/divvun/divvun-keyboard) to produce the actual keyboard app. The keyboard layout specifications are found in the [GiellaLT](https://github.com/giellalt?q=keyboard-&type=&language=) organisation.

## Testing

Tests require a `se.bhfst` file inside the `dicts.bundle`. If this is missing for you, do this:

1. cd giellakbd-ios
1. `mkdir dicts.bundle`
3. [Download the mobile sme speller](https://pahkat.uit.no/main/download/speller-sme?platform=mobile) and extract the `se.bhfst` into the `dicts.bundle` you just created

## Deploying

Builds can be deployed using the [divvun-keyboard repo](https://github.com/divvun/divvun-keyboard)

## License

`giellakbd-ios` is licensed under either of

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

