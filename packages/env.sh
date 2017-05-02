# note: include this in all of your package & action files
# as well as any future variables you end up needing during
# deployments. 
# package: (. ../env.sh) // action (. ../../env.sh)

# location of config assets (i.e: service credentials, flat files, etc.)
export assets="../../config"

# used to scrape pwd output for action directory names
action=${PWD##*/}

# package & event variables
seq=sequences
trig=triggers
rule=rules

# package names
js=javascript
py=python
