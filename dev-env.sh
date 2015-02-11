# USAGE 
# $ source ./env.sh
export GOOGLE_USER="pacharanero@gmail.com"
export GOOGLE_PASSWORD="cxn^ka7\$OI3w65df3jmTWnaU\$N1a3V"
export GOOGLE_GROUP_URL="https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fgroups.google.com%2Fd%2Fforum%2Fccio&hl=en-GB&service=groups2&passive=true"

export DISCOURSE_ADDRESS="http://178.62.0.34/"
export DISCOURSE_API_KEY="be8fc0af4aaacfc05bdf6c28020d1d535e0674e4b3a65002067062fb4422e08a"
export DISCOURSE_API_USER="test_import_user"
export DISCOURSE_CATEGORY="CCIO Leaders Network"

env | grep -e GOOGLE_PASSWORD -e GOOGLE_USER -e GOOGLE_GROUP_URL -e DISCOURSE_ADDRESS -e DISCOURSE_API_KEY -e DISCOURSE_API_USER -e DISCOURSE_CATEGORY