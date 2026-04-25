#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <target-triple>" >&2
  exit 1
fi

target="$1"
binary_name="${BINARY_NAME:-boringtun-cli}"
dist_dir="${DIST_DIR:-dist}"
binary_path="target/${target}/release/${binary_name}"

case "${target}" in
  x86_64-unknown-linux-gnu)
    architecture="amd64"
    ;;
  aarch64-unknown-linux-gnu)
    architecture="arm64"
    ;;
  *)
    printf 'Unsupported release target: %s\n' "${target}" >&2
    exit 1
    ;;
esac

package_name="${binary_name}-${architecture}-linux"
archive_path="${dist_dir}/${package_name}.tar.gz"
checksum_path="${dist_dir}/${package_name}.sha256"
staging_dir="$(mktemp -d)"
packaged_binary_name="${binary_name}"

cleanup() {
  rm -rf "${staging_dir}"
}
trap cleanup EXIT

if [[ ! -f "${binary_path}" ]]; then
  printf 'Built binary not found: %s\n' "${binary_path}" >&2
  exit 1
fi

mkdir -p "${dist_dir}"
cp "${binary_path}" "${staging_dir}/${packaged_binary_name}"
chmod 0755 "${staging_dir}/${packaged_binary_name}"

tar -C "${staging_dir}" -czf "${archive_path}" "${packaged_binary_name}"

(
  cd "${dist_dir}"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${package_name}.tar.gz" > "${package_name}.sha256"
  else
    shasum -a 256 "${package_name}.tar.gz" > "${package_name}.sha256"
  fi
)

printf 'archive=%s\n' "${archive_path}" >> "${GITHUB_OUTPUT:-/dev/null}"
printf 'checksum=%s\n' "${checksum_path}" >> "${GITHUB_OUTPUT:-/dev/null}"
