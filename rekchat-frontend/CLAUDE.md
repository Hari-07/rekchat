# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter desktop application called "rekchat_frontend" that provides a file upload and query interface for CSV data analysis. The app features a two-panel layout with file upload/query controls on the left and data visualization on the right.

## Key Commands

### Development
- `flutter run` - Run the application in development mode
- `flutter build <platform>` - Build for specific platform (macos, linux, windows)
- `flutter analyze` - Run static analysis on the code
- `flutter test` - Run widget tests

### Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Update dependencies
- `flutter clean` - Clean build artifacts

## Architecture

### State Management
The app uses Provider pattern for state management:
- `AppStateViewModel` extends abstract `ViewModel` class (which extends `ChangeNotifier`)
- Main state is managed through `AppStateViewModel` which handles:
  - File upload operations via HTTP POST to `http://127.0.0.1:8001/upload-file`
  - Query submission via HTTP POST to `http://127.0.0.1:8001/submit-query`
  - Data storage and UI updates through `notifyListeners()`

### Project Structure
- `lib/main.dart` - App entry point with MaterialApp and HomePage
- `lib/provider/` - State management classes
  - `view_model.dart` - Abstract base class for ViewModels
  - `app_state_view_model.dart` - Main app state management
- `lib/views/` - UI components
  - `file_uploader.dart` - File picker component (CSV files only)
- `lib/query_input/` - Query input components
  - `query_input_field.dart` - Multi-line text input field
- `lib/services/` - Service layer (currently empty)
- `lib/models/` - Data models (currently empty)

### Backend Integration
The app communicates with a backend server running on `http://127.0.0.1:8001`:
- `/upload-file` endpoint accepts multipart form data with CSV files
- `/submit-query` endpoint accepts query parameters and returns JSON data
- Responses follow format: `{"success": boolean, "result": array|object, "explanation": string}`

### UI Layout
- Two-panel horizontal layout using `Row` with `Expanded` widgets
- Left panel: File upload, file details display, query input, submit button
- Right panel: Data table with headers and virtualized scrolling using `ListView.builder`
- Responsive design with proper overflow handling

## Code Conventions

### Dart/Flutter Specific
- Uses single quotes for strings (enforced by linter)
- Relative imports preferred (enforced by linter)
- Flutter lints package for code quality
- Proper widget key usage with `super.key`
- Follows Flutter naming conventions for widgets and files

### Dependencies
- `dio` for HTTP requests
- `file_picker` for file selection
- `provider` for state management
- `flutter_lints` for code quality

## Platform Support
- Configured for macOS, Linux, and Windows desktop platforms
- macOS configuration includes proper entitlements and Xcode project setup
- Platform-specific build configurations available in respective directories