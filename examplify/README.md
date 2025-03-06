
# EXAMPLIFY

  This folder contains the working demo of Boxify (similar to the private Weezify repository).  
  If you want to run or contribute to Boxify, **this** is where to start!

## Table of Contents

  1. [Overview](#overview)
  2. [Features](#features)
  3. [Project Structure](#project-structure)
  4. [Getting Started](#getting-started)
     - [Prerequisites](#prerequisites)
     - [Firebase Setup](#firebase-setup)
     - [Running the App](#running-the-app)
  5. [Contributing](#contributing)
  6. [Updating Images](#updating-images)
  7. [License](#license)
  8. [Contact](#contact)

  ---

## Overview

  **Examplify** is a fully runnable version of the base Boxify code. It demonstrates how all the pieces fit together and connects to Firebase for authentication, Firestore, etc. Note: the primary color is a little different from the actual Weezify app, just to make it easier to distinguish.

  ---

## Features

- **User Authentication** (Firebase)
- **Playlist Creation & Management**
- **Track Management** (add/remove/listen)
- **Metadata Handling**
- **Support for Dev/Staging Firebase Environments** (so we don’t touch production data)

  ---

## Project Structure

- `lib/`  
    Contains the configuration for this app's implementation of Boxify. To develop the app, you'll mostly be working in Boxify's `lib/` folder.
- `assets/`  
    Holds image assets for the UI.
- `android/` and `ios/`  
    Platform-specific configuration.
- `firebase_options.dart`  
    manually inserted.  
- `google-services.json`  
    Placed in `android/app` after you download from Firebase console.  
- `GoogleService-Info.plist`  
    Placed in `ios/Runner` after you download it.

  ---

## Getting Started

### Prerequisites

If this is your first time using Flutter, make sure you can run the Flutter example app. Getting all of that set up properly is a huge process and it doesn't have anything to do with this project. Better get that work out of the way before you start here. (Very important, make sure to install the version of Flutter specified in `pubspec.yaml`. It's likely not the version that will be installed by default.)

  1. **Confirm your existing setup**

      ```bash
      flutter doctor -v
      ```

  2. **Align your Flutter version**

  If you need to make a change to your Flutter version to make it match the version specified in `pubspec.yaml`, in your terminal, change directory to your flutter installation folder, then:

```bash
   git checkout x.x.x # where x.x.x ia the required Flutter version
   ```

  3. **Align your Java version**

  If you need to make a change to your Java version (hint, [Java SDK 17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) is currently compatible with most Flutter projects):

  - Download and install the required Java version (note the installation path as it is required in the next step)
  - Configure Flutter to use the required Java version

     ```bash
     flutter config --jdk-dir <javasdk17-path-dir> # where <javasdk17-path-dir> is the location you installed the required Java version, e.g. flutter config --jdk-dir /Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
     ```

  - If you are using Android Studio, shut down and re-open for the changes to take effect

### Firebase Setup

  This example requires a **Firebase project** (development/staging).  

  1. **Contact the maintainer** to be added to the 'boxify-dev' Firebase console.
  2. **Download**:
     - `google-services.json` into `android/app` from the Firebase console <https://console.firebase.google.com/u/0/project/boxify-dev-96c50/settings/general/android:com.boxify.dev>
     - `GoogleService-Info.plist` into `ios/Runner` (if you'll be developing on iOS)
     - Go to <https://console.firebase.google.com/u/0/project/boxify-dev-96c50/settings/general/web:ZmNlM2QyYjQtMGRlNC00N2QzLWJkZDktYjYwOWE1NzZhZWYz> and click on Config. Copy the code. Create a new file called `firebase_options.dart` in `lib/config/`. Use the example file for instructions on how to paste the information you copied.
  3. Make sure those files **are not** committed to GitHub if they contain sensitive info. Check `.gitignore`.

### Running the App

  1. **Install dependencies**:

     ```bash
     flutter pub get
     ```

  2. **Run**:

     ```bash
     flutter run
     ```

  3. **Select a platform**:

     ```bash
     flutter run -d android
     # or flutter run -d ios
     ```

  ---

## Contributing

  Contributions are welcome! Steps:

  1. Fork & create a new branch.
  2. Commit changes with a clear message.
  3. Open a Pull Request into `main` (or whichever branch we use).

### Guidelines

- Follow the existing code style (see `analysis_options.yaml`).
- Submit small, focused PRs.
- For major changes, open an issue first to discuss.

  ---

## Updating Images

  Add your new images to the `assets/` folder. Then ensure `pubspec.yaml` lists them under `assets:` so Flutter can access them.

## License
  <!-- 
    If you have a specific license, link it here, e.g.:
    [MIT License](LICENSE.md)
  -->

  ---

## Contact

- **Maintainer:** Rivers
- **Email:** <rivers@riverscuomo.com>
- **Discord:** <https://discord.com/channels/@me/1325992565278900285>
