#!/bin/sh

base_dir="${BASE_DIR:-/opt/bpe/process}"
plugins_file="${PLUGINS_FILE:-/scripts/process-plugins.yaml}"

if ! command -v yq >/dev/null 2>&1; then
  echo "Required command 'yq' not found."
  exit 1
fi

if [ ! -f "$plugins_file" ]; then
  echo "Plugin configuration file '$plugins_file' not found."
  exit 1
fi

expected_jars_file="$(mktemp)"
trap 'rm -f "$expected_jars_file"' EXIT

download_plugin() {
  name="$1"
  version="$2"
  repo_url="$3"
  file="${name}-${version}.jar"
  if [ -f "$base_dir/$file" ]; then
    echo "Plugin '$file' is already installed."
  else
    echo "Plugin '$file' is not installed. Downloading..."
    if wget -q -O "$base_dir/$file" "${repo_url}/releases/download/v${version}/${file}"; then
      echo "Plugin '$file' installed."
    else
      echo "Failed to download plugin '$file'."
      rm -f "$base_dir/$file"
    fi
  fi
}

# Install plugins if not already installed.
plugin_count="$(yq -r '.processPlugins | length' "$plugins_file")"
i=0
while [ "$i" -lt "$plugin_count" ]; do
  name="$(yq -r ".processPlugins[$i].name" "$plugins_file")"
  repo_url="$(yq -r ".processPlugins[$i].repositoryUrl" "$plugins_file")"

  yq -r ".processPlugins[$i].version[]" "$plugins_file" | while IFS= read -r version; do
    [ -n "$version" ] || continue
    file="${name}-${version}.jar"
    download_plugin "$name" "$version" "$repo_url"
    printf '%s\n' "$file" >> "$expected_jars_file"
  done

  i=$((i + 1))
done

# Delete any .jar file in the directory that is not in the expected plugin list
for f in "$base_dir"/*.jar; do
  [ -f "$f" ] || continue
  basename_f="$(basename "$f")"
  if grep -qxF "$basename_f" "$expected_jars_file"; then
    : # keep
  else
    echo "Deleting unexpected file '$basename_f'"
    rm -f "$f"
  fi
done
