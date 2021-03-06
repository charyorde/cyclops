#!/bin/bash
# Copyright (c) 2016. Zuercher Hochschule fuer Angewandte Wissenschaften
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Author: Martin Skoviera

if [[ $# != 2 ]]; then
    echo "Provide RabbitMQ's server IP (or domain name) and port"
    echo "Example: ./bindings.sh localhost 15672"
    exit 1
fi

wget http://$1:$2/cli/rabbitmqadmin >/dev/null 2>&1

if [[ $? != 0 ]]; then
    echo "RabbitMQ Management Plugin was not found, make sure it's installed"
    exit 2
fi

chmod +x rabbitmqadmin


# Create necessary queues
./rabbitmqadmin declare queue --host=$1 --port=$2 --vhost="/" name="cyclops.openstack.event.data" durable=true
./rabbitmqadmin declare queue --host=$1 --port=$2 --vhost="/" name="cyclops.udr.consume" durable=true

# Create necessary exchanges
./rabbitmqadmin declare exchange --host=$1 --port=$2 --vhost="/" name="cyclops.openstack.event.broadcast" type=fanout


# Bind UDR to Rule engine (pushing UDR records)
./rabbitmqadmin declare binding --host=$1 --port=$2 --vhost="/" source="cyclops.openstack.event.broadcast" destination_type="queue" destination="cyclops.udr.consume"
./rabbitmqadmin declare binding --host=$1 --port=$2 --vhost="/" source="nova" destination_type="queue" destination="cyclops.openstack.event.data" routing_key="conductor"
./rabbitmqadmin declare binding --host=$1 --port=$2 --vhost="/" source="neutron" destination_type="queue" destination="cyclops.openstack.event.data" routing_key="notifications.info"
./rabbitmqadmin declare binding --host=$1 --port=$2 --vhost="/" source="cinder" destination_type="queue" destination="cyclops.openstack.event.data" routing_key="notifications.info"
rm rabbitmqadmin
