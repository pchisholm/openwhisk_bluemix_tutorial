. ../../env.sh

# deploy action
wsk action update ${py}/${action} index.py

wait