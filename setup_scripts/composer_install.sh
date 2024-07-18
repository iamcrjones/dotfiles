#!/bin/bash

# Check if Composer is already installed
if command -v composer &>/dev/null; then
  echo "Composer is already installed."
  exit 0
fi

# Download and install Composer
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('sha384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
  >&2 echo 'ERROR: Invalid installer signature'
  rm composer-setup.php
  exit 1
fi

php composer-setup.php --quiet
RESULT=$?
rm composer-setup.php

# Move composer executable to a directory in your PATH
if [ $RESULT -eq 0 ]; then
  mv composer.phar /usr/local/bin/composer
  echo 'Composer installed successfully.'
else
  >&2 echo 'ERROR: Composer installation failed.'
fi

exit $RESULT
