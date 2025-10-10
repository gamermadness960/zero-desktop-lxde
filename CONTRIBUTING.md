# Contributing to zero-desktop-lxde

Thanks for your interest in improving zero-desktop-lxde!

## How to Contribute

- **Bug reports:** Open an issue with reproduction steps
- **Feature requests:** Open an issue to discuss first
- **Pull requests:** Submit PRs with clear descriptions
- **Documentation:** Improvements always welcome

## Development

This is the base image for the zero-desktop ecosystem. Changes here affect all projects that extend this image.

```bash
# Test changes locally
docker build -t zero-desktop-lxde:test .
docker run -d -p 5900:5900 -e VNC_PASS=test zero-desktop-lxde:test

# Connect with VNC client to verify
```

## Guidelines

- Keep changes focused and atomic
- Test before submitting PR
- Update README if adding features
- Maintain backward compatibility when possible

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

