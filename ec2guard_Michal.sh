#!/bin/bash

# Get EC2 IP address from "hostname":
EC2_IP_ADDRESS=$(echo `hostname` \
    | sed -e "s/^ip-//" \
    | tr - . \
    )

# Get the instance ID:
EC2_INSTANCE_ID=$(aws ec2 describe-instances \
    --filter Name=private-ip-address,Values=$(echo "${EC2_IP_ADDRESS}") \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text \
    )

# Get a list of all tags assigned to this EC2 machine:
TAG_LIST=$(aws ec2 describe-instances \
    --filter Name=private-ip-address,Values=$(echo "${EC2_IP_ADDRESS}") \
    --query 'Reservations[].Instances[].Tags[]' \
    --output json \
    )

# From the above list filter down the "Name" of the EC2:
TAG_EC2_NAME=$(echo "${TAG_LIST}" \
    | jq -r '.[] | select(.Key | contains("Name")) | .Value' \
    )

# And the "Owner":
TAG_EC2_OWNER=$(echo "${TAG_LIST}" \
    | jq -r '.[] | select(.Key | contains("Owner")) | .Value' \
    )

# Now, check if the AWS "Owner" TAG was set:
if [ ! -z "${TAG_EC2_OWNER}" ]; then
    # Get the name only form provided email address:
    OWNER_NAME=$(echo "${TAG_EC2_OWNER}" | sed 's/@siili.com//')
else
    # The "Owner" AWS TAG was not set, so will communicate that:
    TAG_EC2_OWNER="unknown! :alert:"
    echo "[ERROR] This EC2 machine (${EC2_INSTANCE_ID}) doesn't have the OWNER TAG!"
fi

# Sends a status message to Slack:
# - usage: SendSlackMessage MESSAGE
function SendSlackMessage() {
    local SLACK_MESSAGE=${1}
    local WEBHOOKDEC=$(echo 'aHR0cHM6Ly9ob29rcy5zbGFjay5jb20vc2VydmljZXMvVDBGR1FIVjg4L0IwNDhKRUtQOUZVL3E2M0FsN1N5dXFMd3hpc0VCeXExd3dNYgo=' | base64 --decode)

    if [ ! -z "${SLACK_MESSAGE}" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data '{"text":"'"${SLACK_MESSAGE}"'"}' \
            ${WEBHOOKDEC}
    else
        echo "[ERROR] Message param has not been provided! Unable to send this Slack message."
    fi
}

UPTIME_LIMIT=240
UPTIME_SECONDS=$(cat /proc/uptime | grep -o '^[0-9]\+')
UPTIME_MINUTES=$((${UPTIME_SECONDS} / 60))
UPTIME_DIFF=$((${UPTIME_LIMIT} - ${UPTIME_MINUTES}))

# Check whether it should say "? minute" or "? minutes":
[[ "${CURRENT_UPTIME}" -gt 1 ]] && S_FOR_CURRENT_MINUTES="s" || S_FOR_CURRENT_MINUTES=""
# The same here:
[[ "${TIME_LEFT}" -gt 1 ]] && S_FOR_SHUTDOWN_MINUTES="s" || S_FOR_SHUTDOWN_MINUTES=""
# Check machine's uptime and time left to machine's shutdown
[[ "${UPTIME_DIFF}" -lt 0 ]] && TIME_LEFT="0" || TIME_LEFT=${UPTIME_DIFF}

# Send Slack message with machine status:
SendSlackMessage "EC2 machine *${EC2_INSTANCE_ID}* status:\n\t- :point_right: Owner: ${TAG_EC2_OWNER}\n\t- :stopwatch: Uptime: ${UPTIME_MINUTES} minute${S_FOR_CURRENT_MINUTES}\n\t- :hourglass_flowing_sand: Time left to shutdown: ${TIME_LEFT} minute${S_FOR_SHUTDOWN_MINUTES}"