# USAGE 
# $ source ./env.sh
export GOOGLE_USER="pacharanero@gmail.com"
export GOOGLE_PASSWORD="cxn^ka7\$OI3w65df3jmTWnaU\$N1a3V"
export GOOGLE_GROUP_URL="https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fgroups.google.com%2Fd%2Fforum%2Fhealth-cio&hl=en-GB&service=groups2&passive=true"

export DISCOURSE_ADDRESS="https://discourse.digitalhealth.net/"
export DISCOURSE_API_KEY="58751de0bdaeecd5060673c2fe56ea9c5d2f55d666c0a50a150b16dfca3d5483"
export DISCOURSE_API_USER="health_cio_googlegrp"
export DISCOURSE_CATEGORY="Health CIO Network"

env | grep -e GOOGLE_PASSWORD -e GOOGLE_USER -e GOOGLE_GROUP_URL -e DISCOURSE_ADDRESS -e DISCOURSE_API_KEY -e DISCOURSE_API_USER -e DISCOURSE_CATEGORY