# Releasing aZen

## Local build

```bash
./build.sh
# Output: build/aZen.app + build/aZen.dmg
```

## GitHub release

Push a version tag — CI builds the `.dmg` and creates a GitHub Release automatically.

```bash
git tag v1.x.x
git push origin v1.x.x
```

## Notes

- Ad-hoc signed (not notarized). Users may need: `xattr -cr /Applications/aZen.app`
- Update `VERSION` in `build.sh` before tagging
- Workflow: `.github/workflows/release.yml`
