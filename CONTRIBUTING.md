# Contributing to ProImageEditor

First off, thank you for considering contributing to ProImageEditor! Your support helps make this project better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Submitting Pull Requests](#submitting-pull-requests)
- [Development Setup](#development-setup)
- [Style Guides](#style-guides)
  - [Git Commit Messages](#git-commit-messages)
  - [Dart Code Style](#dart-code-style)
- [Additional Resources](#additional-resources)

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project, you agree to abide by its terms.

## How Can I Contribute?

### Reporting Bugs

If you encounter a bug, please report it by [opening a bug report](https://github.com/hm21/pro_image_editor/issues/new?template=bug_report.yml). The bug report template will guide you to provide the necessary details, such as:

- Steps to reproduce the issue.
- Expected and actual behavior.
- Screenshots or code snippets.
- Environment details (e.g., OS, Flutter version, etc.).

### Suggesting Enhancements

We welcome suggestions to improve ProImageEditor! To propose an enhancement, [open a feature request](https://github.com/hm21/pro_image_editor/issues/new?template=feature_request.yml). The feature request template includes fields for:

- A description of the proposed enhancement.
- The problem it solves or the benefit it provides.
- Any relevant examples, mockups, or use cases.

### Submitting Pull Requests

To contribute code:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/YourFeatureName`).
3. Make your changes, ensuring they adhere to the project's coding standards.
4. Run `dart analyze` to ensure no static analysis issues.
5. Run `flutter test` to ensure all tests pass.
6. Commit your changes with a [conventional git commit](https://www.conventionalcommits.org/en/v1.0.0/).
7. Push to your forked repository (`git push origin feature/YourFeatureName`).
8. [Open a pull request](https://github.com/hm21/pro_image_editor/compare) against the `stable` branch.


In your pull request:

- Reference any related issues.
- Provide a clear description of the changes and their purpose.
- Highlight any areas that may need special attention during review.

## Development Setup

To set up a local development environment:

1. Ensure you have [Flutter](https://flutter.dev/docs/get-started/install) installed.
2. Clone the repository: `git clone https://github.com/hm21/pro_image_editor.git`
3. Navigate to the project directory: `cd pro_image_editor`
4. Install dependencies: `flutter pub get`
5. Run the example app to test: `flutter run`

## Style Guides

### Git Commit Messages

We use **conventional commits** for commit messages. Please follow this format: `<type>(scope): <subject>`

Examples:

- `feat(editor): add new filter options`
- `fix(image_processing): resolve crash on iOS devices`
- `docs(contributing): update contributing guidelines`

Valid commit types include:

- `feat`: A new feature.
- `fix`: A bug fix.
- `docs`: Documentation changes.
- `style`: Code style changes (white-space, formatting, etc.).
- `refactor`: Code refactoring without changing functionality.
- `test`: Adding or updating tests.
- `chore`: Maintenance tasks (e.g., updating dependencies).

### Dart Code Standards

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- Use `flutter format` to format your code.
- Ensure that **`dart analyze`** runs without any warnings or errors.
- Ensure that **`flutter test`** passes without failures.
- Write documentation comments for public APIs.

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Effective Dart](https://dart.dev/effective-dart)

Thank you for contributing to ProImageEditor!
