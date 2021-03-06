# apic-devops

## Introduction
This repo is being shared as a way to do devops for API Connect. Note that the default is with API Gateway.

## Required Setup
- clone this repo
- update scripts/.env per your environment
- make sure readlink or greadlink is installed; for Mac you can install via brew by command `brew install coreutils`
- the scripts need APIC toolkit `apic` to be installed
- though not required, you can create Draft APIs via `apic create:api` command, example: `apic create:api --title "Test API" --api_type "rest" --target-url "https://httpbin.org/get" --gateway_type "datapower-api-gateway"`

## Files
- scripts/.env - update this to your environment
- scripts/publish - main file being used to demonstrate end to end devops pipeline
- scripts/pre-commit - example git pre-commit hook that can be used to make sure changes are good
- scripts/apis - APIs should be stored here, right now this contains 1 API as an example
