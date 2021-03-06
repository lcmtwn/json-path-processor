#!/bin/sh

echo "DEBUG ENV: ${TRAVIS_JOB_NUMBER} ${TRAVIS_BUILD_NUMBER} ..."

if [ "${TRAVIS_BUILD_NUMBER}.2" != "${TRAVIS_JOB_NUMBER}" ]; then
  echo "Only run sauce labs 1 time 1 commit... quit."
  exit 0
fi

if [ "${TRAVIS_REPO_SLUG}" != "zordius/json-path-processor" ]; then
  echo "Skip deploy because this is a fork... quit."
  exit 0
fi

# push coverage to codeclimate
npm install codeclimate-test-reporter
npm run-script coverage
node_modules/.bin/codeclimate < coverage/lcov.info

# skip browser build, browser test and deploy when json-path-processor.js not changed.
CODEDIFF=`git show --name-only ${TRAVIS_COMMIT} |grep json-path-processor.js`
if [ -z "$CODEDIFF" ]; then
  echo json-path-proceccor.js is not changed, SKIP browser build/test and deploy.
  exit 0
fi

# build JS files for dist and test
npm install grunt grunt-cli grunt-contrib-connect grunt-saucelabs badge-render
npm run-script lint && npm run-script build_std && npm run-script build_dbg && npm run-script build_min && npm run-script build_req && npm run-script build_tst

CODE=$?
if [ $CODE -ne 0 ]; then
  echo Build failed, abort.
  exit 1
fi

# do sauce labs tests
node_modules/.bin/grunt || exit $?

# Setup git
git config --global user.name "Travis-CI"
git config --global user.email "zordius@yahoo-inc.com"

git add dist
git commit -m "Auto build dist files for ${TRAVIS_COMMIT} [ci skip]"

node badge.js
git add badge.png
git commit -m "Auto commit browser badge for ${TRAVIS_COMMIT} [ci skip]"

# push back dist files
git push "https://${GHTK}@github.com/zordius/json-path-processor.git" HEAD:${TRAVIS_BRANCH} > /dev/null 2>&1

# Skip deploy when not master
if [ "${TRAVIS_BRANCH}" != "master" ]; then
  echo skip deploy because now in branch ${TRAVIS_BRANCH}
  exit 0
fi

# Bump npm version and push back to git
npm version prerelease -m "Auto commit for npm publish version %s [ci skip]"
git push "https://${GHTK}@github.com/zordius/json-path-processor.git" --tags > /dev/null 2>&1

# Deploy to npm
gem install dpl
dpl --provider=npm --email='zordius@yahoo-inc.com' --api-key=${NPM_API_KEY} > /dev/null 2>&1
