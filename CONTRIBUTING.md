# Contributing to OpenClaw Bootstrap

Thank you for your interest in contributing to OpenClaw Bootstrap! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## How Can I Contribute?

### Reporting Bugs

- Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md)
- Check existing issues to avoid duplicates
- Include as much detail as possible

### Suggesting Enhancements

- Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md)
- Describe the feature and its use case
- Consider the project scope and goals

### Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following our coding standards
4. Run tests and linting (`make test lint`)
5. Commit with clear, descriptive messages
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a merge request

## Coding Standards

### Shell Scripts
- Use [ShellCheck](https://www.shellcheck.net/) for linting
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use 4-space indentation
- Make scripts executable (`chmod +x`)

### Documentation
- Use Markdown for documentation
- Follow [markdownlint](.markdownlint.json) rules
- Keep README.md up to date
- Update wiki documentation for major changes

### Commit Messages

- Use clear, descriptive commit messages
- Reference issue numbers when applicable
- Keep commits focused on a single change

## Testing

- Run existing tests before submitting
- Add tests for new functionality
- Ensure all tests pass (`make test`)

## Questions?

Feel free to open an issue with your question or contact the maintainers.
