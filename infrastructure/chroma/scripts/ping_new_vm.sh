#!/bin/bash

curl http://$(terraform output -raw public_ip_address):8000/api/v1/heartbeat