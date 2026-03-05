#!/bin/bash

set -euo pipefail

BASE_IMAGE=$(
  grep -E '^FROM ubuntu:[a-z]+-[0-9]+$' Dockerfile |
  sed 's/^FROM //'
)
INSTALL_NAMES=$(sed 's/=.*//' packages/installs.txt | tr '\n' ' ')
TEMPORARY_NAMES=$(sed 's/=.*//' packages/temporary.txt | tr '\n' ' ')

# resolve all packages after installing extras
INSTALL_CMD="export DEBIAN_FRONTEND=noninteractive"
INSTALL_CMD+=" && apt-get update -qq 2>/dev/null"
INSTALL_CMD+=" && apt-get install --no-install-recommends"
INSTALL_CMD+=" --no-install-suggests -y"
INSTALL_CMD+=" ${INSTALL_NAMES} ${TEMPORARY_NAMES}"
INSTALL_CMD+=" > /dev/null 2>&1"
INSTALL_CMD+=" && dpkg-query -W -f '\${Package}=\${Version}\n'"
INSTALL_CMD+=" | sort"
FULL_LIST=$(docker run --rm "${BASE_IMAGE}" bash -c "${INSTALL_CMD}")

# get base image package list
BASE_IMG_LIST=$(
  docker run --rm --entrypoint bash "${BASE_IMAGE}" \
    -c "dpkg-query -W -f '\${Package}=\${Version}\n'" | sort
)

# determine updated base packages (exclude explicit installs and temporary)
EXCLUDE_PATTERN=$(
  {
    sed 's/=.*//' packages/installs.txt
    sed 's/=.*//' packages/temporary.txt
  } | sed '/^$/d' | paste -sd'|'
)
NEW_PACKAGE_UPDATES=$(comm -13 <(echo "${BASE_IMG_LIST}") \
  <(echo "${FULL_LIST}") | \
  grep -vE "^(${EXCLUDE_PATTERN})=" || true)
NEW_PACKAGE_UPDATES=$(echo -n "${NEW_PACKAGE_UPDATES}" | sed '/^$/d')

# resolve install package versions
NEW_PACKAGE_INSTALLS=''

for PKG in ${INSTALL_NAMES}; do
  VER=$(echo "${FULL_LIST}" | grep "^${PKG}=" | head -1)

  if [[ -n "${VER}" ]]; then
    NEW_PACKAGE_INSTALLS+="${VER}"$'\n'
  fi
done

NEW_PACKAGE_INSTALLS=$(echo -n "${NEW_PACKAGE_INSTALLS}" | sed '/^$/d')

# resolve temporary package versions
NEW_PACKAGE_TEMPORARY=''

for PKG in ${TEMPORARY_NAMES}; do
  VER=$(echo "${FULL_LIST}" | grep "^${PKG}=" | head -1)

  if [[ -n "${VER}" ]]; then
    NEW_PACKAGE_TEMPORARY+="${VER}"$'\n'
  fi
done

NEW_PACKAGE_TEMPORARY=$(echo -n "${NEW_PACKAGE_TEMPORARY}" | sed '/^$/d')

# compare with current files
OLD_UPDATES_CONTENT=$(cat packages/updates.txt)
OLD_INSTALLS_CONTENT=$(cat packages/installs.txt)
OLD_TEMPORARY_CONTENT=$(cat packages/temporary.txt)
NEW_UPDATES_CONTENT="${NEW_PACKAGE_UPDATES}"$'\n'
NEW_INSTALLS_CONTENT="${NEW_PACKAGE_INSTALLS}"$'\n'
NEW_TEMPORARY_CONTENT="${NEW_PACKAGE_TEMPORARY}"$'\n'

if [[ "${OLD_UPDATES_CONTENT}" == "${NEW_UPDATES_CONTENT}" ]] \
  && [[ "${OLD_INSTALLS_CONTENT}" == "${NEW_INSTALLS_CONTENT}" ]] \
  && [[ "${OLD_TEMPORARY_CONTENT}" == "${NEW_TEMPORARY_CONTENT}" ]]; then
  echo 'No package updates available'
  exit 0
fi

# write updated files
echo -n "${NEW_UPDATES_CONTENT}" > packages/updates.txt
echo -n "${NEW_INSTALLS_CONTENT}" > packages/installs.txt
echo -n "${NEW_TEMPORARY_CONTENT}" > packages/temporary.txt

# build change summary
UPDATE_CHANGES=''
OLD_UPDATES=$(echo "${OLD_UPDATES_CONTENT}" | sort)
NEW_UPDATES=$(echo "${NEW_PACKAGE_UPDATES}" | sort)
ALL_UPDATE_PKGS=$(
  {
    echo "${OLD_UPDATES_CONTENT}"
    echo "${NEW_PACKAGE_UPDATES}"
  } | sed 's/=.*//' | sort -u
)

for PKG in ${ALL_UPDATE_PKGS}; do
  OLD_VER=$(grep "^${PKG}=" <<< "${OLD_UPDATES}" | sed 's/.*=//' || true)
  NEW_VER=$(grep "^${PKG}=" <<< "${NEW_UPDATES}" | sed 's/.*=//' || true)

  if [[ "${OLD_VER}" != "${NEW_VER}" ]]; then
    UPDATE_CHANGES+="- ${PKG} from ${OLD_VER} to ${NEW_VER}"$'\n'
  fi
done

INSTALL_CHANGES=''
OLD_INSTALLS=$(echo "${OLD_INSTALLS_CONTENT}" | sort)
NEW_INSTALLS=$(echo "${NEW_PACKAGE_INSTALLS}" | sort)
ALL_INSTALL_PKGS=$(
  {
    echo "${OLD_INSTALLS_CONTENT}"
    echo "${NEW_PACKAGE_INSTALLS}"
  } | sed 's/=.*//' | sort -u
)

for PKG in ${ALL_INSTALL_PKGS}; do
  OLD_VER=$(grep "^${PKG}=" <<< "${OLD_INSTALLS}" | sed 's/.*=//' || true)
  NEW_VER=$(grep "^${PKG}=" <<< "${NEW_INSTALLS}" | sed 's/.*=//' || true)

  if [[ "${OLD_VER}" != "${NEW_VER}" ]]; then
    INSTALL_CHANGES+="- ${PKG} from ${OLD_VER} to ${NEW_VER}"$'\n'
  fi
done

TEMPORARY_CHANGES=''
OLD_TEMPORARY=$(echo "${OLD_TEMPORARY_CONTENT}" | sort)
NEW_TEMPORARY=$(echo "${NEW_PACKAGE_TEMPORARY}" | sort)
ALL_TEMPORARY_PKGS=$(
  {
    echo "${OLD_TEMPORARY_CONTENT}"
    echo "${NEW_PACKAGE_TEMPORARY}"
  } | sed 's/=.*//' | sort -u
)

for PKG in ${ALL_TEMPORARY_PKGS}; do
  OLD_VER=$(grep "^${PKG}=" <<< "${OLD_TEMPORARY}" | sed 's/.*=//' || true)
  NEW_VER=$(grep "^${PKG}=" <<< "${NEW_TEMPORARY}" | sed 's/.*=//' || true)

  if [[ "${OLD_VER}" != "${NEW_VER}" ]]; then
    TEMPORARY_CHANGES+="- ${PKG} from ${OLD_VER} to ${NEW_VER}"$'\n'
  fi
done

UPDATE_BODY=''

if [[ -n "${UPDATE_CHANGES}" ]]; then
  UPDATE_BODY+="### Package Updates"$'\n\n'
  UPDATE_BODY+="${UPDATE_CHANGES}"$'\n'
fi

if [[ -n "${INSTALL_CHANGES}" ]]; then
  UPDATE_BODY+="### Package Installs"$'\n\n'
  UPDATE_BODY+="${INSTALL_CHANGES}"$'\n'
fi

if [[ -n "${TEMPORARY_CHANGES}" ]]; then
  UPDATE_BODY+="### Temporary Packages"$'\n\n'
  UPDATE_BODY+="${TEMPORARY_CHANGES}"$'\n'
fi

echo "Package updates available"

if [[ -n "${UPDATE_BODY}" ]]; then
  echo "update-title=Bump packages" >> "${GITHUB_OUTPUT}"

  {
    echo 'update-body<<EOF'
    echo -n "${UPDATE_BODY}"
    echo 'EOF'
  } >> "${GITHUB_OUTPUT}"
fi
