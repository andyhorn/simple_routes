# Simple Routes Improvements Tracker

This file tracks potential improvements for the `simple_routes` project.

## 🛠 Quality of Life & DX
- [ ] **Support for ShellRoutes**: Investigate and implement base classes for `ShellRoute` and `StatefulShellRoute`.

## 🏗 Code Generation Enhancements
- [ ] **Multi-field "Extra" Support**: Support multiple `@Extra` annotations by bundling them into a generated wrapper class.
## 🛡 Robustness & Bug Fixes
*Completed!*

---

## Completed
- [x] **Enhanced Type Support**: Add support for `bool`, `enum`, `double`/`num`, and `DateTime` in path/query parameters.
- [x] **Path Parameter Validation**: Throw build errors if `@Path` fields don't match the `@Route` path template.
- [x] **URI Encoding for Path Parameters**: Ensure path parameters are URI encoded when injected into the path.
- [x] **Generator Integration Tests**: Add `build_test` integration tests to verify generator output.
