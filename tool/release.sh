#!/usr/bin/env bash
# Release helper. Run from anywhere in the repo.
#
#   tool/release.sh prepare <version>  Set <version> in pubspec.yaml and add
#                                      a CHANGELOG section.
#   tool/release.sh check [<tag>]      Check the version files agree (and match
#                                      <tag>, if given). CI runs this too.
#   tool/release.sh tag                Check main is ready, then create and push
#                                      the v<version> tag that starts publishing.
set -euo pipefail
cd "$(dirname "$0")/.."

SEMVER='^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'

fail() {
  echo "error: $*" >&2
  exit 1
}

pubspec_version() { sed -n 's/^version: *//p' pubspec.yaml; }

# Prints the CHANGELOG section for $1, without its heading.
changelog_section() {
  awk -v heading="## $1" '
    $0 == heading { found = 1; next }
    found && /^## / { exit }
    found { print }
  ' CHANGELOG.md
}

prepare() {
  local version=${1:-}
  [[ -n $version ]] || fail "usage: tool/release.sh prepare <version>"
  [[ $version =~ $SEMVER ]] || fail "'$version' is not a version like 1.2.3"
  [[ $version != "$(pubspec_version)" ]] || fail "pubspec.yaml is already at $version"

  perl -pi -e "s/^version: .*/version: $version/" pubspec.yaml
  if ! grep -qx "## $version" CHANGELOG.md; then
    { printf '## %s\n\n* TODO: describe the changes.\n\n' "$version"; cat CHANGELOG.md; } > CHANGELOG.md.tmp
    mv CHANGELOG.md.tmp CHANGELOG.md
  fi

  echo "Set version $version in pubspec.yaml and CHANGELOG.md."
  echo "Next: describe the changes in CHANGELOG.md, open a PR, merge it, then run tool/release.sh tag."
}

check() {
  local tag=${1:-}
  local version
  version=$(pubspec_version)

  [[ $version =~ $SEMVER ]] || fail "pubspec.yaml version '$version' is not a version like 1.2.3"
  grep -qx "## $version" CHANGELOG.md || fail "CHANGELOG.md has no '## $version' section"
  [[ -n $(changelog_section "$version" | tr -d '[:space:]') ]] ||
    fail "the CHANGELOG.md section for $version is empty"
  ! changelog_section "$version" | grep -q 'TODO' ||
    fail "the CHANGELOG.md section for $version still contains a TODO"
  if [[ -n $tag && $tag != "v$version" ]]; then
    fail "tag $tag does not match pubspec.yaml version $version (expected v$version)"
  fi

  echo "Version $version is consistent."
}

tag() {
  check
  local version tag
  version=$(pubspec_version)
  tag="v$version"

  [[ $(git branch --show-current) == main ]] || fail "switch to main first"
  [[ -z $(git status --porcelain) ]] || fail "the working tree has uncommitted changes"
  git fetch --quiet origin main --tags
  [[ $(git rev-parse HEAD) == $(git rev-parse origin/main) ]] ||
    fail "local main is not the same as origin/main; pull or push first"
  ! git rev-parse -q --verify "refs/tags/$tag" >/dev/null || fail "tag $tag already exists"
  [[ -z $(git ls-remote --tags origin "refs/tags/$tag") ]] || fail "tag $tag already exists on origin"

  echo "Checking the package with pub..."
  flutter pub publish --dry-run

  echo
  git log -1 --format='Tagging %h %s' HEAD
  read -r -p "Create and push $tag? This starts the publish workflow. [y/N] " answer
  [[ $answer == [yY] ]] || fail "cancelled"

  git tag -a "$tag" -m "nav_dock $version"
  git push origin "$tag"
  echo "Pushed $tag. Approve the run in the pub.dev environment to publish."
}

case ${1:-} in
  prepare) prepare "${2:-}" ;;
  check) check "${2:-}" ;;
  tag) tag ;;
  *)
    sed -n '2,9s/^# \{0,1\}//p' "$0"
    exit 1
    ;;
esac
