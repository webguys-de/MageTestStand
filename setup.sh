#!/bin/bash
set -e
set -x
 
# check if this is a travis environment
function cleanup {
  echo "Removing build directory ${BUILDENV}"
  rm -rf ${BUILDENV}
}

trap cleanup EXIT

echo "zend_extenstion = xdebug.so" >> ~/.phpenv/versions/$(phpenv version-name)/etc/php.ini

if [ ! -z $TRAVIS_BUILD_DIR ] ; then
  WORKSPACE=$TRAVIS_BUILD_DIR
fi

if [ -z $WORKSPACE ] ; then
  echo "No workspace configured, please set your WORKSPACE environment"
  exit
fi
 
BUILDENV=`mktemp -d /tmp/mageteststand.XXXXXXXX`
 
echo "Using build directory ${BUILDENV}"
 
git clone https://github.com/webguys-de/MageTestStand.git ${BUILDENV}
cp -rf ${WORKSPACE} ${BUILDENV}/.modman/
${BUILDENV}/install.sh
 
cd ${BUILDENV}/htdocs
${BUILDENV}/bin/phpunit --coverage-clover ${BUILDENV}/build/logs/clover.xml --colors -d display_errors=1

echo "Exporting test results to code climate"
cd ${BUILDENV}
vendor/codeclimate/php-test-reporter/composer/bin/test-reporter --stdout > codeclimate.json
curl -X POST -d @codeclimate.json -H 'Content-Type: application/json' -H 'User-Agent: Code Climate (PHP Test Reporter v1.0.1-dev)' https://codeclimate.com/test_reports

echo "Done."
