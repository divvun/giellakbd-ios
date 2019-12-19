# giellakbd-ios

An open source reimplementation of Apple's native iOS keyboard with a specific focus on support for localised keyboards.

## Dependencies

In order to build the `divvunspell` dependency, you will need to install the Rust compiler. See https://rustup.rs for instructions.

Run the following commands:

```
rustup target install {aarch64,armv7,armv7s,x86_64,i386}-apple-ios
cargo install cargo-lipo
pod install
```

To enable Sentry, add a `SentryDSN` key to the `HostingApp/Supporting Files/Info.plist` file.

##### Note: the first build will take a while.

## License

`giellakbd-ios` is licensed under either of

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

