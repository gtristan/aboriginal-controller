#!/bin/bash

# This is expected to be sourced by both sides of
# the protocol
#
# Each side defines COMM_IN and COMM_OUT differently

# This is a timeout we wait between reading an ACK
# and sending a message, we should not need this,
# it possibly indicates a bug with qemu/virtio.
SB_WAIT_SEND=0.3

# This is a timeout to wait between retries
SB_WAIT_RETRY=1.5

# Also same issue, in case that the wait is not enough
# and we fail to get our ACK, we try the whole command
# over again.
SB_RETRIES=20

function printStderr() {
    echo "$@" 1>&2;
}

function printVerbose() {
    if $SB_VERBOSE; then
	printStderr $@
    fi
}

# Send the ACK back to the caller
function sendAck() {
    printVerbose "Writing back ACK to ${COMM_OUT}"
    echo "${SB_PROTO_ACK}" > ${COMM_OUT}
}

function sendAndWait() {
    local sendData="$@"
    local readAck="z"

    printVerbose "Sending to ${COMM_OUT}: ${sendData}"
    echo ${sendData} > ${COMM_OUT};
    printVerbose "Waiting for ACK from ${COMM_IN}"
    read -t 5 -r readAck < ${COMM_IN};
    printVerbose "Read ack: $readAck"

    if [ "${readAck}" != "${SB_PROTO_ACK}" ]; then
	echo "1"
    else
	echo "0"
    fi
}

# This will send a sequence defined by an array COMMAND_SEQUENCE
# and will retry SB_RETRIES times before giving up.
#
# It will send the success status to stdout of the function after
# the message is either sent of we give up.
#
# Usage example:
#
#  COMMAND_SEQUENCE=()
#  COMMAND_SEQUENCE+=("BEGIN")
#  COMMAND_SEQUENCE+=("EXIT")
#  COMMAND_SEQUENCE+=("END")
#
#  status=$(sendSequence)
#
#  if [ "${status}" -eq 0 ]; then
#     echo "Success !"
#  else
#     echo "Failed !"
#  fi
#
function sendSequence() {
    local status=0;
    local tries=0;

    while [ "${tries}" -lt ${SB_RETRIES} ]; do

	for line in "${COMMAND_SEQUENCE[@]}"; do
	    status=$(sendAndWait ${line})
	    if [ "${status}" -ne 0 ]; then
		break
	    fi

	    sleep ${SB_WAIT_SEND}
	done

	if [ "${status}" -eq 0 ]; then
	    break
	fi

	sleep ${SB_WAIT_RETRY}
	let tries=${tries}+1;
    done

    if [ "${status}" != "0" ]; then
	printStderr "Failed to send message after ${tries} tries"
	echo "1";
    else
	echo "0";
    fi
}
