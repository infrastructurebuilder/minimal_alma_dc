# Makefile for minimal_alma_dc

.PHONY: bump-patch bump-minor release

.bump:
	@bump-my-version bump $(COMMAND) $(FLAGS)

# Bump patch version
bump-patch:
	$(MAKE) .bump COMMAND=patch FLAGS="--no-tag --no-commit --allow-dirty"

# Bump minor version
bump-minor:
	$(MAKE) .bump COMMAND=minor	FLAGS="--no-tag --no-commit --allow-dirty"

# Release: bump version with tag and commit, then push with tags
release:
	$(MAKE) .bump COMMAND=patch FLAGS="--tag --commit"
	@git push --tags
