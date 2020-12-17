# giellakbd-ios

An open source reimplementation of Apple's native iOS keyboard with a specific focus on support for localised keyboards and support for minority and indigenous languages.

##### Note: the first build will take a while.

## Dependencies

In order to build the `divvunspell` dependency, you will need to install the Rust compiler. See https://rustup.rs for instructions.

Run the following commands:

```
rustup target install {aarch64,armv7,armv7s,x86_64,i386}-apple-ios
cargo install cargo-lipo
pod install
```

To enable Sentry, add a `SentryDSN` key to the `HostingApp/Supporting Files/Info.plist` file.

### Updating localisations

```
npm i -g technocreatives/i18n-eller
i18n-eller generate swift Support/Strings/en.yaml Support/Strings/*.yaml -o HostingApp
```

If you add a new locale, please open an issue to have it added to the language list inside the app.

## Keyboard layouts

This repo does not include any keyboard layouts. It is intended to be used as a template for [kbdgen](divvun/kbdgen), which consumes a.o. this codebase, and layouts as listed in e.g. [divvun-keyboard](/divvun/divvun-keyboard) to produce the actual keyboard app. The keyboard layout specifications are found in the [GiellaLT](https://github.com/giellalt?q=keyboard-&type=&language=) organisation.

## License

`giellakbd-ios` is licensed under either of

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

