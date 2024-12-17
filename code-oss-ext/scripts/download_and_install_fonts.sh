#!/usr/bin/env bash

export FONTS_PATH="/usr/share/fonts/truetype/hacknerdfont"
export FONTS_HACK_VERSION="v3.3.0"
export FONTS_HACK_ZIP="Hack.zip"

if [ ! -d "${FONTS_PATH}" ]; then
  echo "Making fonts directory"

  # Font directory path
  mkdir -p "${FONTS_PATH}"

else
  echo "Fonts directory already exists"

fi

curl --fail --location --show-error https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_HACK_VERSION}/${FONTS_HACK_ZIP} --output ${FONTS_HACK_ZIP}
unzip -o -q -d ${FONTS_PATH} ${FONTS_HACK_ZIP}
rm ${FONTS_HACK_ZIP}

echo "fc-cache -fv"
fc-cache -fv
