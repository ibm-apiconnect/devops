#!/bin/bash

# Source default environment variables
export BASE=/Users/sumanto/apic-devops # FIXME
. $BASE/scripts/.env

# Environment variables specific to this script
export management=${management}
export gateway=${gateway}
export provider_idp=${provider_idp}
export provider_username=${provider_username}
export provider_password=${provider_password}
export porg=${porg}
export catalog=sandbox
export api_tm_client_key=${api_tm_client_key}
export api_tm_client_secret=${api_tm_client_secret}
export test_url=${test_url}


echo
echo Step 2a: Create the Test Product referencing the API to test
echo ------------------------------------------------------------
rm -f test100-product.yaml
apic create:product --name "test-product" --version "1.0.0" --gateway-type "datapower-api-gateway" --title "Test Product" --apis "$1" --filename test100-product.yaml


echo
echo Step 2b: Authenticate
echo ---------------------
apic login --username ${provider_username} --password ${provider_password} --server ${management} --realm ${provider_idp}


echo
echo Step 2c: Publish the Test Product to the Catalog with the API to be tested
echo --------------------------------------------------------------------------
response=`apic products:publish --server ${management} --org ${porg} --catalog sandbox test100-product.yaml --format json | jq -r '.url'`
echo Product published with url $response


echo
echo Step 2d: Create Automated Test Consumer User
echo --------------------------------------------
owner_url=`apic users:create --server ${management} --org ${porg} --user-registry sandbox-catalog $BASE/scripts/consumer_user.json --format json | jq -r '.url'`
echo User url is $owner_url


echo
echo Step 2e: Create Automated Test Consumer Org
echo -------------------------------------------
tmp=$(mktemp)
jq --arg a "$owner_url" '.owner_url = $a' $BASE/scripts/consumer_org.json > "$tmp" && mv "$tmp" $BASE/scripts/consumer_org.json
apic consumer-orgs:create --server ${management} --org ${porg} --catalog sandbox $BASE/scripts/consumer_org.json


echo
echo Step 2f: Create Automated Test App
echo ----------------------------------
client_id=`apic apps:create --server ${management} --org ${porg} --catalog sandbox --consumer-org test-consumer-org $BASE/scripts/app.json --format json | jq -r '.client_id'`
echo Client id to use is $client_id

echo
echo Step 2g: Create Subscription to Test Product
echo --------------------------------------------
apic subscriptions:create --server ${management} --org ${porg} --catalog sandbox --consumer-org test-consumer-org --app test-consumer-app $BASE/scripts/subscription.json
echo
sleep 10


echo
echo Step 2h: Run Test Suite
echo -----------------------
response=`curl -X POST -H "X-API-Key:${api_tm_client_key}" -H "X-API-Secret:${api_tm_client_secret}" -H "Content-Type:application/json" --data "{'options':{'allAssertions':false,'JUnitFormat':false},'variables':{'endpointUrl':'${gateway}/${porg}/sandbox','XIBMClientId':'${client_id}'}}" ${test_url}`
echo Test response: $response


echo
echo
echo Step 2i: Delete Test Product
echo ----------------------------
apic products:delete --server ${management} --org ${porg} --catalog sandbox --scope catalog test-product:1.0.0


echo
echo Step 2j: Delete Automated Test Consumer Org
echo -------------------------------------------
apic consumer-orgs:delete --server ${management} --org ${porg} --catalog sandbox test-consumer-org


echo
echo Step 2k: Delete Automated Test Consumer User
echo --------------------------------------------
apic users:delete --server ${management} --org ${porg} --user-registry sandbox-catalog automated-test-user


echo
echo Step 2l: Cleanup remaining artifacts
echo ------------------------------------
rm test100-product.yaml
