# Contributing to RTSP Rotator

Thank you for your interest in contributing to RTSP Rotator! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Style Guide](#style-guide)

## Code of Conduct

This project adheres to a simple code of conduct:

- Be respectful and constructive
- Focus on what is best for the project
- Show empathy towards other contributors
- Accept constructive criticism gracefully

## Getting Started

1. **Fork the repository** (if applicable)
2. **Clone your fork**:
   ```bash
   git clone https://github.com/yourusername/RTSP-Rotator.git
   cd RTSP-Rotator
   ```
3. **Open in Xcode**:
   ```bash
   open "RTSP Rotator.xcodeproj"
   ```

## Development Setup

### Prerequisites

- macOS 10.15 (Catalina) or later
- Xcode 14.0 or later
- VLCKit framework

### Installing VLCKit

#### Option 1: CocoaPods

```bash
# Create Podfile if it doesn't exist
pod init

# Add to Podfile:
# pod 'VLCKit'

pod install
```

#### Option 2: Manual Installation

1. Download VLCKit from https://code.videolan.org/videolan/VLCKit
2. Drag VLCKit.framework into your Xcode project
3. Under "General" > "Frameworks, Libraries, and Embedded Content", set to "Embed & Sign"

### Build Configuration

The project includes two build configurations:
- **Debug**: Development builds with full debugging symbols
- **Release**: Optimized builds for distribution

## Making Changes

### Branch Naming

Use descriptive branch names:
- `feature/add-grid-layout` - New features
- `fix/memory-leak-timer` - Bug fixes
- `docs/api-documentation` - Documentation updates
- `refactor/player-controller` - Code refactoring
- `test/feed-rotation` - Test additions

### Commit Messages

Follow the conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or tooling changes

**Examples:**

```
feat(controller): add configuration file reload support

Implement automatic reload of rtsp_feeds.txt when file changes
are detected. Uses FSEvents API for efficient file monitoring.

Closes #42
```

```
fix(player): prevent crash on invalid RTSP URL

Add URL validation before attempting to create VLCMedia object.
Log error and skip to next feed if URL is malformed.

Fixes #38
```

## Testing

### Running Tests

```bash
# Run all tests in Xcode
⌘U (Command + U)

# Run from command line
xcodebuild test -scheme "RTSP Rotator" -destination "platform=macOS"

# Run specific test
xcodebuild test -scheme "RTSP Rotator" -destination "platform=macOS" -only-testing:RTSP_RotatorTests/testFeedRotation
```

### Writing Tests

- Place test files in `Tests/` directory
- Name test files with `Tests` suffix (e.g., `ControllerTests.m`)
- Group related tests using `#pragma mark`
- Follow the Given-When-Then pattern:

```objc
- (void)testFeedRotation {
    // Given
    NSArray *feeds = @[@"rtsp://feed1", @"rtsp://feed2"];
    Controller *controller = [[Controller alloc] initWithFeeds:feeds];

    // When
    [controller nextFeed];

    // Then
    XCTAssertEqual(controller.currentIndex, 1);
}
```

### Test Coverage Goals

- Aim for 80%+ code coverage
- All public methods should have tests
- Test edge cases and error conditions
- Include performance tests for critical paths

## Documentation

### Code Documentation

Use HeaderDoc/AppleDoc style comments:

```objc
/**
 * Brief description of the method
 *
 * Detailed description providing more context about what the method does,
 * when it should be used, and any important side effects.
 *
 * @param paramName Description of the parameter
 * @return Description of the return value
 */
- (ReturnType)methodWithParameter:(ParamType)paramName;
```

### Inline Comments

- Use `//` for single-line comments
- Explain "why" not "what"
- Keep comments up-to-date with code changes

### README Updates

When adding features, update:
- Features section
- Usage instructions
- Configuration options
- Troubleshooting section (if applicable)

### CHANGELOG Updates

Follow Keep a Changelog format:
- Add entries under "Unreleased" section
- Use categories: Added, Changed, Deprecated, Removed, Fixed, Security
- Move to versioned section when releasing

## Submitting Changes

### Before Submitting

1. **Run all tests**: Ensure all tests pass
2. **Check code style**: Follow the style guide
3. **Update documentation**: README, CHANGELOG, code comments
4. **Test manually**: Run the app and verify changes work
5. **Check for warnings**: Fix any Xcode warnings

### Pull Request Process

1. **Create a pull request** with a clear title and description
2. **Reference related issues**: Use "Fixes #123" or "Relates to #456"
3. **Describe changes**: What, why, and how
4. **Include screenshots**: For UI changes
5. **Wait for review**: Address feedback promptly

### Pull Request Template

```markdown
## Description
Brief description of changes

## Motivation
Why are these changes needed?

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
How were these changes tested?

## Screenshots (if applicable)
[Add screenshots here]

## Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] No new warnings
- [ ] Code follows style guide
```

## Style Guide

### Objective-C Style

#### Naming Conventions

**Classes:**
```objc
@interface RTSPWallpaperController : NSObject
```
- Use UpperCamelCase
- Descriptive names
- Prefix with project identifier if needed

**Methods:**
```objc
- (void)playCurrentFeed;
- (instancetype)initWithFeeds:(NSArray *)feeds rotationInterval:(NSTimeInterval)interval;
```
- Use lowerCamelCase
- Descriptive, readable names
- Start with verb for actions

**Properties:**
```objc
@property (nonatomic, strong) NSArray<NSString *> *feeds;
@property (nonatomic, assign) BOOL isMuted;
```
- Use lowerCamelCase
- Descriptive names
- Specify type with generics when possible

**Constants:**
```objc
static const NSTimeInterval kDefaultRotationInterval = 60.0;
static NSString * const kFeedConfigurationFileName = @"rtsp_feeds.txt";
```
- Use kPascalCase for constants
- Use meaningful names

#### Code Organization

**Import Order:**
```objc
// System frameworks
#import <Cocoa/Cocoa.h>
#import <VLCKit/VLCKit.h>

// Project headers
#import "RTSPController.h"
#import "RTSPWindow.h"
```

**Interface/Implementation Structure:**
```objc
@interface ClassName : SuperClass <Protocol>

// Properties
@property (nonatomic, strong) Type *property;

// Methods
- (void)publicMethod;

@end

@implementation ClassName

#pragma mark - Initialization

- (instancetype)init {
    // ...
}

#pragma mark - Public Methods

- (void)publicMethod {
    // ...
}

#pragma mark - Private Methods

- (void)privateMethod {
    // ...
}

#pragma mark - Protocol Conformance

- (void)protocolMethod {
    // ...
}

@end
```

#### Formatting

**Spacing:**
```objc
// Method spacing
- (void)method1 {
    // code
}

- (void)method2 {
    // code
}

// Control flow spacing
if (condition) {
    // code
}

for (Type *item in collection) {
    // code
}
```

**Braces:**
```objc
// Opening brace on same line
if (condition) {
    doSomething();
} else {
    doSomethingElse();
}
```

**Line Length:**
- Maximum 120 characters per line
- Break long lines at logical points

**Indentation:**
- Use 4 spaces (not tabs)
- Indent continuation lines

### Logging

Use consistent log format:
```objc
NSLog(@"[INFO] Descriptive message: %@", variable);
NSLog(@"[WARNING] Warning message");
NSLog(@"[ERROR] Error message: %@", error.localizedDescription);
```

## Code Review Checklist

When reviewing code, check for:

### Functionality
- [ ] Changes work as intended
- [ ] Edge cases are handled
- [ ] Error conditions are handled gracefully

### Code Quality
- [ ] Code is readable and maintainable
- [ ] No unnecessary complexity
- [ ] Follows DRY principle
- [ ] Appropriate abstractions

### Testing
- [ ] New code has tests
- [ ] Tests are meaningful
- [ ] All tests pass
- [ ] Edge cases are tested

### Documentation
- [ ] Code is well-commented
- [ ] Public APIs are documented
- [ ] README updated if needed
- [ ] CHANGELOG updated

### Performance
- [ ] No obvious performance issues
- [ ] Efficient algorithms used
- [ ] Resources are properly managed

### Security
- [ ] No security vulnerabilities
- [ ] Input validation present
- [ ] Sensitive data handled properly

## Questions?

If you have questions about contributing:
- Check existing issues and pull requests
- Review the README and documentation
- Contact the project maintainer

## Recognition

Contributors will be recognized in:
- CHANGELOG.md
- Project README (if significant contribution)
- Release notes

Thank you for contributing to RTSP Rotator!
