#!/usr/bin/env bash
# Release helper for the packages in this workspace. Run from anywhere in the
# repo. <package> is nav_dock or nav_dock_window_placement; tags are
# <package>-v<version>.
#
#   tool/release.sh prepare <package> <version>  Set <version> in the package's
#                                                pubspec.yaml and add a
#                                                CHANGELOG section.
#   tool/release.sh check <package> [<tag>]      Check the version files agree
#                                                (and match <tag>, if given).
#                                                CI runs this too.
#   tool/release.sh tag <package>                Check main is ready, then create
#                                                and push the tag that starts
#                                                publishing.
#   tool/release.sh dir <package>                Print the package directory.
set -euo pipefail
cd "$(dirname "$0")/.."

SEMVER='^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'

fail() {
  echo "error: $*" >&2
  exit 1
}

usage() {
  sed -n '2,15s/^# \{0,1\}//p' "$0"
  exit 1
}

# Prints the directory of package $1, relative to the repo root.
package_dir() {
  case ${1:-} in
    nav_dock) echo . ;;
    nav_dock_window_placement) echo packages/nav_dock_window_placement ;;
    '') usage ;;
    *) fail "unknown package '$1' (nav_dock or nav_dock_window_placement)" ;;
  esac
}

pubspec_version() { sed -n 's/^version: *//p' "$1/pubspec.yaml"; }

# Prints the CHANGELOG section for version $2 of the package in $1, without its
# heading.
changelog_section() {
  awk -v heading="## $2" '
    $0 == heading { found = 1; next }
    found && /^## / { exit }
    found { print }
  ' "$1/CHANGELOG.md"
}

prepare() {
  local package=${1:-} version=${2:-} dir
  dir=$(package_dir "$package")
  [[ -n $version ]] || fail "usage: tool/release.sh prepare <package> <version>"
  [[ $version =~ $SEMVER ]] || fail "'$version' is not a version like 1.2.3"
  [[ $version != "$(pubspec_version "$dir")" ]] || fail "$package is already at $version"

  perl -pi -e "s/^version: .*/version: $version/" "$dir/pubspec.yaml"
  if ! grep -qx "## $version" "$dir/CHANGELOG.md"; then
    { printf '## %s\n\n* TODO: describe the changes.\n\n' "$version"; cat "$dir/CHANGELOG.md"; } > "$dir/CHANGELOG.md.tmp"
    mv "$dir/CHANGELOG.md.tmp" "$dir/CHANGELOG.md"
  fi

  echo "Set $package $version in $dir/pubspec.yaml and $dir/CHANGELOG.md."
  echo "Next: describe the changes in the CHANGELOG, open a PR, merge it, then run tool/release.sh tag $package."
}

check() {
  local package=${1:-} tag=${2:-} dir version
  dir=$(package_dir "$package")
  version=$(pubspec_version "$dir")

  [[ $version =~ $SEMVER ]] || fail "$dir/pubspec.yaml version '$version' is not a version like 1.2.3"
  ! grep -q '^publish_to: *none' "$dir/pubspec.yaml" || fail "$package is not published yet (publish_to: none)"
  grep -qx "## $version" "$dir/CHANGELOG.md" || fail "$dir/CHANGELOG.md has no '## $version' section"
  [[ -n $(changelog_section "$dir" "$version" | tr -d '[:space:]') ]] ||
    fail "the CHANGELOG section for $package $version is empty"
  ! changelog_section "$dir" "$version" | grep -q 'TODO' ||
    fail "the CHANGELOG section for $package $version still contains a TODO"
  if [[ -n $tag && $tag != "$package-v$version" ]]; then
    fail "tag $tag does not match $package $version (expected $package-v$version)"
  fi

  echo "$package $version is consistent."
}

tag() {
  local package=${1:-} dir version tag
  dir=$(package_dir "$package")
  check "$package"
  version=$(pubspec_version "$dir")
  tag="$package-v$version"

  [[ $(git branch --show-current) == main ]] || fail "switch to main first"
  [[ -z $(git status --porcelain) ]] || fail "the working tree has uncommitted changes"
  git fetch --quiet origin main --tags
  [[ $(git rev-parse HEAD) == $(git rev-parse origin/main) ]] ||
    fail "local main is not the same as origin/main; pull or push first"
  ! git rev-parse -q --verify "refs/tags/$tag" >/dev/null || fail "tag $tag already exists"
  [[ -z $(git ls-remote --tags origin "refs/tags/$tag") ]] || fail "tag $tag already exists on origin"

  echo "Checking the package with pub..."
  (cd "$dir" && flutter pub publish --dry-run)

  echo
  git log -1 --format='Tagging %h %s' HEAD
  read -r -p "Create and push $tag? This starts the publish workflow. [y/N] " answer
  [[ $answer == [yY] ]] || fail "cancelled"

  git tag -a "$tag" -m "$package $version"
  git push origin "$tag"
  echo "Pushed $tag. Approve the run in the pub.dev environment to publish."
}

case ${1:-} in
  prepare) prepare "${2:-}" "${3:-}" ;;
  check) check "${2:-}" "${3:-}" ;;
  tag) tag "${2:-}" ;;
  dir) package_dir "${2:-}" ;;
  *) usage ;;
esac
