#!/usr/bin/env bash

get_os() {
  uname | tr '[:upper:]' '[:lower:]'
}

get_cpu() {
  if [[ "$(uname -p)" = "i686" ]]; then
    echo "x86"
  else
    echo "x64"
  fi
}

get_platform() {
  os=$(get_os)
  cpu=$(get_cpu)
  echo "$os-$cpu"
}

create_default_env() {
  export NODE_MODULES_CACHE=${NODE_MODULES_CACHE:-true}
  export NODE_ENV=${NODE_ENV:-production}
  export NODE_VERBOSE=${NODE_VERBOSE:-false}
}

create_build_env() {
  # Set BUN_INSTALL to the build directory
  export BUN_INSTALL="$BUILD_DIR/.scalingo"
  export BUN_DIR="$BUILD_DIR/.scalingo/cache"
}

list_node_config() {
  echo ""
  printenv | grep ^BUN_ || true
  printenv | grep ^NODE_ || true
}

export_env_dir() {
  local env_dir=$1
  if [ -d "$env_dir" ]; then
    local whitelist_regex=${2:-''}
    local blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH|LANG|BUILD_DIR)'}
    # shellcheck disable=SC2164
    pushd "$env_dir" >/dev/null
    for e in *; do
      [ -e "$e" ] || continue
      echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
      export "$e=$(cat "$e")"
      :
    done
    # shellcheck disable=SC2164
    popd >/dev/null
  fi
}

write_profile() {
  local bp_dir="$1"
  local build_dir="$2"
  mkdir -p "$build_dir/.profile.d"
  if [ -d "$bp_dir/profile" ]; then
    cp "$bp_dir"/profile/* "$build_dir/.profile.d/" 2>/dev/null || true
  fi
}

write_ci_profile() {
  local bp_dir="$1"
  local build_dir="$2"
  write_profile "$1" "$2"
  if [ -d "$bp_dir/ci-profile" ]; then
    cp "$bp_dir"/ci-profile/* "$build_dir/.profile.d/" 2>/dev/null || true
  fi
}

write_export() {
  local bp_dir="$1"
  local build_dir="$2"

  # only write the export script if the buildpack directory is writable.
  # this may occur in situations outside of Scalingo, such as running the
  # buildpacks locally.
  if [ -w "$bp_dir" ]; then
    echo "export PATH=\"$build_dir/.scalingo/bin:\$PATH:$build_dir/node_modules/.bin\"" > "$bp_dir/export"
    echo "export BUN_INSTALL=\"$build_dir/.scalingo\"" >> "$bp_dir/export"
    echo "export BUN_DIR=\"$build_dir/.scalingo/cache\"" >> "$bp_dir/export"
  fi
}
