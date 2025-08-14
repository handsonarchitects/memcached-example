# Contributing to Memcached Example

Thank you for your interest in contributing to this project! This guide will help you set up your development environment and understand our development workflow.

## Development Setup

### Prerequisites

- Python 3.11 or 3.12
- Docker
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured

### Install Development Dependencies

For each module, install both runtime and development dependencies:

```bash
# For cache-api module
cd modules/cache-api
pip install -r requirements.txt -r requirements-dev.txt

# For cache-generator module
cd modules/tools/cache-generator
pip install -r requirements.txt -r requirements-dev.txt
```

### Local Testing

Run the same checks locally before pushing:

```bash
# Code formatting
black --check .
black .  # to fix formatting

# Import sorting
isort --check-only .
isort .  # to fix imports

# Linting
flake8 .

# Type checking
mypy . --ignore-missing-imports

# Unit tests
pytest -v

# Security checks
# Note: safety check command is deprecated but safety scan requires authentication
safety check
bandit -r .
```

### Security Scanning Notes

**Safety Command**: The `safety check` command is deprecated but still functional. The new `safety scan` command requires authentication which isn't suitable for CI/CD environments. We continue using `safety check` until a better solution is available.

**Alternative**: Consider using `pip-audit` as a modern alternative:
```bash
pip install pip-audit
pip-audit
```

## Code Quality Standards

- **Line Length**: Maximum 120 characters
- **Import Sorting**: Using `isort` with Black profile
- **Type Hints**: Required for all functions (enforced by mypy)
- **Test Coverage**: Unit tests required for new functionality
- **Security**: No known vulnerabilities allowed in dependencies

## Configuration Files

This project uses a hybrid configuration approach for optimal tool support:

### **pyproject.toml** (Modern Tools)
Contains configuration for:
- **Black** (code formatter)
- **isort** (import sorter)
- **mypy** (type checker)
- **pytest** (test runner)

### **setup.cfg** (Traditional Tools)
Contains configuration for:
- **flake8** (linter)

**Why this hybrid approach?**
- `pyproject.toml` is the modern Python standard (PEP 518) for newer tools
- `setup.cfg` provides native flake8 support without requiring additional plugins
- This combination is reliable, widely used, and doesn't require flake8-pyproject dependencies
- Both files are automatically discovered by their respective tools

## CI/CD Pipeline

The project uses GitHub Actions for continuous integration with the following workflow:

### Pipeline Triggers
- **Push** to `main` branch
- **Pull requests** targeting `main` branch

### Pipeline Jobs

#### 1. Test Job
- **Matrix Strategy**: Tests against Python 3.11 and 3.12
- **Modules Tested**: `cache-api` and `tools/cache-generator`
- **Steps**:
  - Dependency caching for faster builds
  - Code linting with `flake8`
  - Code formatting validation with `black`
  - Import sorting validation with `isort`
  - Type checking with `mypy`
  - Unit testing with `pytest`

#### 2. Docker Build Job
- Builds Docker images for both modules
- Validates that containers can be created successfully
- Runs only after tests pass

#### 3. Security Scan Job
- Vulnerability scanning with `safety`
- Security linting with `bandit`
- Generates security reports

## Development Workflow

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create** a feature branch from `main`
4. **Make** your changes
5. **Run** local tests and quality checks
6. **Commit** your changes with clear commit messages
7. **Push** to your fork
8. **Create** a pull request to the main repository

## Testing

### Running Tests Locally

```bash
# Run all tests for cache-api
cd modules/cache-api
pytest -v

# Run all tests for cache-generator
cd modules/tools/cache-generator
pytest -v
```

### Writing Tests

- Use descriptive test function names that explain what is being tested
- Include comprehensive docstrings
- Mock external dependencies (like Memcached, HTTP requests)
- Test both success and failure scenarios

## Docker Development

### Building Images Locally

```bash
# Build cache-api image
cd modules/cache-api
docker build -t memcached-cache-api:dev .

# Build cache-generator image
cd modules/tools/cache-generator
docker build -t memcached-cache-generator:dev .
```

## Submitting Changes

### Pull Request Guidelines

- **Clear Description**: Explain what your PR does and why
- **Small Changes**: Keep PRs focused on a single feature or fix
- **Tests**: Include tests for new functionality
- **Documentation**: Update documentation if needed
- **Code Quality**: Ensure all CI checks pass

### Commit Message Format

Use clear, descriptive commit messages:

```
feat: add range calculator class for cache-generator
fix: handle missing environment variables gracefully
docs: update configuration documentation
test: add comprehensive payload validation tests
```

## Getting Help

If you have questions or need help:

1. Check existing [Issues](https://github.com/handsonarchitects/memcached-example/issues)
2. Review the [README.md](README.md) for basic usage
3. Open a new issue if you can't find what you're looking for

## Code of Conduct

Please be respectful and professional in all interactions. We're here to learn and build something great together!
