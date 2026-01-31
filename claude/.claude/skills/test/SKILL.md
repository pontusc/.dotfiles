---
name: test
description: Run tests for the current project and report failures
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [test-path or test-pattern]
model: sonnet
---

Run the test suite for this project. Arguments: $ARGUMENTS

**Workflow:**

1. **Detect test framework** by checking for:
   - `pytest.ini`, `pyproject.toml` with pytest, or `tests/` with Python files → pytest
   - `package.json` with jest/vitest/mocha → npm test
   - `Cargo.toml` → cargo test
   - `go.mod` → go test
   - `Makefile` with test target → make test

2. **Run tests** with appropriate verbosity:
   - Use `-v` or `--verbose` for detailed output
   - Capture stdout and stderr
   - Report exit codes

3. **On failures**, analyze:
   - Read failing test files
   - Read source code under test
   - Parse error messages and stack traces
   - Identify root cause

4. **Report concisely**:
   - Summary: X/Y tests passed
   - For failures: file:line references
   - Root cause analysis
   - Suggested fixes

5. **Example output format**:
   ```
   ## Test Results: 45/47 passed (2 failed)

   ### test_authentication_flow (tests/auth/test_login.py:23)
   **Error**: AssertionError: Expected 200, got 401
   **Cause**: Mock JWT token expired in test setup
   **Fix**: Update token fixture with longer expiry (tests/auth/conftest.py:15)

   ### test_database_migration (tests/db/test_migrate.py:67)
   **Error**: IntegrityError: duplicate key violates unique constraint
   **Cause**: Test database not properly cleaned between runs
   **Fix**: Add cleanup in tearDown method
   ```

**Keep output focused and actionable.**
