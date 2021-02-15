#!/bin/bash

docker run --rm -w "$PWD" -v "$PWD":"$PWD" ligolang/ligo:0.9.0 run-function get_packed_address.ligo main unit
