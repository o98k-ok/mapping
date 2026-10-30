# Orb development

Mapping is a macOS 14+ app using AppKit, Carbon, and SwiftUI. There are no
third-party package dependencies. Linux Swift cannot build the app or its
language test, whose model imports Carbon.

- `.agents/setup` installs Linux source-check tools into the orb snapshot.
  `.agents/resume` needs no authentication or services.
- For native builds and tests, start a Mac satellite with image `macos-15`
  (Xcode 16.0, matching `project.yml`). Run `bash .agents/setup` on that Mac
  to install XcodeGen if missing. Mac dependencies are separate from the
  Linux orb snapshot; repeat setup for each new satellite, not each build.
- Edit repository files in the Linux orb; Mac commands mirror those edits.
- On the Mac, generate and build without creating a signing identity:
  `xcodegen generate && xcodebuild -project Mapping.xcodeproj -scheme Mapping -configuration Debug -derivedDataPath /tmp/mapping-derived CODE_SIGNING_ALLOWED=NO build`.
- Run the existing language regression test on the Mac:
  `swiftc Mapping/Models/MappingConfig.swift Scripts/test-language.swift -o /tmp/mapping-language-test && /tmp/mapping-language-test`.
- `build.sh` creates a local signing identity; do not run it during setup or
  resume. Signing and installation are separate from environment preparation.
