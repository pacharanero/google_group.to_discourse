# USAGE 
# $ source ./env.sh
export GOOGLE_USER="pacharanero@gmail.com"
export GOOGLE_PASSWORD="cxn^ka7\$OI3w65df3jmTWnaU\$N1a3V"
export GOOGLE_GROUP_URL="https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fgroups.google.com%2Fd%2Fforum%2Fccio&hl=en-GB&service=groups2&passive=true"

export DISCOURSE_ADDRESS="https://discourse.digitalhealth.net/"
export DISCOURSE_API_KEY="29653bcaa028b7335ccf99f7a54aaa338ac2a0a9108140c1b719dc53121c8819"
export DISCOURSE_API_USER="ccio_google_group"
export DISCOURSE_CATEGORY="CCIO Leaders Network"

env | grep -e GOOGLE_PASSWORD -e GOOGLE_USER -e GOOGLE_GROUP_URL -e DISCOURSE_ADDRESS -e DISCOURSE_API_KEY -e DISCOURSE_API_USER -e DISCOURSE_CATEGORY