# giellakbd-ios

An open source reimplementation of Apple's native iOS keyboard with a specific focus on support for localised keyboards.

## Dependencies

In order to build the hfst-ospell-rs dependency, you will need to install the Rust compiler. See https://rustup.rs for instructions.

Run the following commands:

```
cargo install cargo-lipo
git submodule update --init
pod install
```

To enable Sentry, add a `SentryDSN` key to the `HostingApp/Supporting Files/Info.plist` file.

## License

BSD 3-Clause - see LICENSE

