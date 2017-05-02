. ../env.sh

# Create the package
wsk package create ${py} 2>&1 | grep -v "resource already exists"

# Run each child script in all package sub-directories
for action in */; do
	(cd $action && ./initialize.sh) &
done

wait

echo -e "\x1B[34mFinished initializing ${package} package.\x1B[0m\n"