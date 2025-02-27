#!/usr/bin/env bash

set -e

AZURE_RESOURCE_GROUP="$1"
NEW="$2"

if [ "$AZURE_RESOURCE_GROUP" == "" ]; then
    echo "AZURE_RESOURCE_GROUP is missing"
    exit 1
fi

ansible-playbook generate-templates.yml

if [ "$NEW" == "" ];then

az deployment group create --template-file ./.generated/network.json -g $AZURE_RESOURCE_GROUP
#az deployment group create --template-file ./.generated/storage.json -g $AZURE_RESOURCE_GROUP
az deployment group create --template-file ./.generated/availability-sets.json -g $AZURE_RESOURCE_GROUP
az deployment group create --template-file ./.generated/bastion.json -g $AZURE_RESOURCE_GROUP
az deployment group create --template-file ./.generated/masters.json -g $AZURE_RESOURCE_GROUP
az deployment group create --template-file ./.generated/minions.json -g $AZURE_RESOURCE_GROUP

else
az deployment group create --template-file ./.generated/masters_update.json -g $AZURE_RESOURCE_GROUP
#az deployment group create --template-file ./.generated/minions_update.json -g $AZURE_RESOURCE_GROUP
fi

