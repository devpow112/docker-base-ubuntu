#!/bin/bash

set -euo pipefail

INSTALL_FILE="packages/generated/install.txt"
DPKG_QUERY="dpkg-query -W -f '\${Package}=\${Version}\n'"

BASE_IMAGE=$(sed -n 's/^FROM \(ubuntu:[a-z]*-[0-9]*\)$/\1/p' Dockerfile)
REQUIRED=$(sed '/^$/d' packages/required.txt | tr '\n' ' ')
TEMPORARY=$(sed '/^$/d' packages/temporary.txt | tr '\n' ' ')

# get base image package list
BASE_LIST=$(
  docker run --rm "${BASE_IMAGE}" bash -c "${DPKG_QUERY}" |
  LC_ALL=C sort
)

# resolve all packages after update, upgrade, and installing extras
FULL_LIST=$(
  docker run --rm "${BASE_IMAGE}" bash -c "
    export DEBIAN_FRONTEND=noninteractive &&
    apt-get update -qq 2>/dev/null &&
    apt-get upgrade -y > /dev/null 2>&1 &&
    apt-get install --no-install-recommends --no-install-suggests -y \
      ${REQUIRED} ${TEMPORARY} > /dev/null 2>&1 &&
    ${DPKG_QUERY}" |
  LC_ALL=C sort
)

# determine all packages that differ from the base image
NEW_INSTALL=$(
  LC_ALL=C comm -13 <(echo "${BASE_LIST}") <(echo "${FULL_LIST}") |
  sed '/^$/d'
)

# read current packages from install file
OLD_INSTALL=$(sed '/^$/d' "${INSTALL_FILE}" | LC_ALL=C sort)

if [[ "${OLD_INSTALL}" == "${NEW_INSTALL}" ]]; then
  echo "No package updates available"
  exit 0
fi

# write updated install file
printf '%s\n' "${NEW_INSTALL}" > "${INSTALL_FILE}"

# build change summary
ADDED=""
UPDATED=""
REMOVED=""
OLD_SORTED=$(echo "${OLD_INSTALL}" | LC_ALL=C sort)
NEW_SORTED=$(echo "${NEW_INSTALL}" | LC_ALL=C sort)
ALL_PKGS=$(
  printf '%s\n%s' "${OLD_INSTALL}" "${NEW_INSTALL}" |
  sed -e '/^$/d' -e 's/=.*//' |
  LC_ALL=C sort -u
)

while IFS= read -r PKG; do
  [[ -z "${PKG}" ]] && continue
  OLD_VER=$(grep "^${PKG}=" <<< "${OLD_SORTED}" | cut -d= -f2- || true)
  NEW_VER=$(grep "^${PKG}=" <<< "${NEW_SORTED}" | cut -d= -f2- || true)

  if [[ "${OLD_VER}" != "${NEW_VER}" ]]; then
    if [[ -z "${OLD_VER}" ]]; then
      ADDED+="- \`${PKG}\` **${NEW_VER}**"$'\n'
    elif [[ -z "${NEW_VER}" ]]; then
      REMOVED+="- \`${PKG}\` **${OLD_VER}**"$'\n'
    else
      UPDATED+="- \`${PKG}\` from **${OLD_VER}** to **${NEW_VER}**"$'\n'
    fi
  fi
done <<< "${ALL_PKGS}"

BODY=""

if [[ -n "${ADDED}" ]]; then
  BODY+="### Added"$'\n\n'
  BODY+="${ADDED}"$'\n'
fi

if [[ -n "${UPDATED}" ]]; then
  BODY+="### Updated"$'\n\n'
  BODY+="${UPDATED}"$'\n'
fi

if [[ -n "${REMOVED}" ]]; then
  BODY+="### Removed"$'\n\n'
  BODY+="${REMOVED}"$'\n'
fi

echo "Package updates available"

if [[ -n "${BODY}" ]]; then
  {
    echo 'update-body<<EOF'
    echo -n "${BODY}"
    echo 'EOF'
  } >> "${GITHUB_OUTPUT}"
fi
