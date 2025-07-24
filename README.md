# minimal_alma_dc

A Minimal Alma Linux Devcontainer Image

## Releases

This project uses [bump-my-version](https://pypi.org/project/bump-my-version/) for versioning.

To bump the version, use ONE of the following commands:

```bash
make bump-patch
make bump-minor
make release
```

`bump-patch` will increment the patch version (e.g., from 1.0.0 to 1.0.1).
`bump-minor` will increment the minor version (e.g., from 1.0.0 to 1.1.0).
`release` will increment the patch version, create a tag, commit the changes, and push the tags to the remote repository, which will trigger a new build in the CI/CD pipeline and push a new Docker image to the registry.

## About
This is a base for a reasonably small devcontainer image to use to configure backing systems, generally RHEL.

It's based on the Alma 10 image, which is a RHEL clone but not really RHEL.  So this container config itself isn't what you would use to configure a real RHEL system, but it is close enough for most purposes.

### Configuring RHEL 8

For RHEL 8 configured using `ansible`, `ansible` has to be pinned as a specific version, because RHEL 8 ships with an old version of python, and the latest ansible requires a newer version of python.

Use this:
```bash
  pipx install ansible==9.*
```

That should allow you to run _most_ ansible playbooks against a RHEL 8 system. Latest packer (already installed here) works fine.  However, if your playbook requires a newer version of python, you may need to install a newer version of python in the container, and then use that version of python to run ansible. YMMV.


