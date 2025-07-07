# minimal_alma_dc

# rhel8tools

This is a base for a reasonably small devcontainer image to use to configure RHEL.

It's based on the Alma 10 image, which is a RHEL clone but not really RHEL.  So this container config isn't what you would use to configure a real RHEL system, but it is close enough for most purposes.

## RHEL 8

For RHEL 8 configured using ansible, ansible has to be pinned as a specific version, because RHEL 8 ships with an old version of python, and the latest ansible requires a newer version of python.

Use this:
```bash
  pipx install ansible==9.*
```

That should allow you to run ansible playbooks against a RHEL 8 system. Latest packer (already installed here) works fine.
