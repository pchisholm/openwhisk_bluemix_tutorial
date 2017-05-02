# OpenWhisk & Bluemix Tutorial
**How to get started building stateless web APIs hosted on the Bluemix platform**

### Important

This tutorial is designed to show the user how they might structure a serverless web application using OpenWhisk. It is meant to be very simple and my intention is to demonstrate one possible organization for a small-scale web application / IoT project. Some basic familiarity with bash is assumed (both Bluemix and OpenWhisk have respective command line interfaces). You also need a Bluemix account before you get started: [sign up here](https://console.ng.bluemix.net/registration/).

It would be beneficial to read about the OpenWhisk ecosystem [here](https://console.ng.bluemix.net/docs/openwhisk/index.html#getting-started-with-openwhisk) before starting this tutorial to familiarize yourself with the jargon tossed around. There is a great tutorial on the OpenWhisk cli which can be found [here](https://learnwhisk.mybluemix.net/). OpenWhisk also depends on Docker for siloing your code. You don't need to know how to configure docker to get started although knowing a bit about it beforehand will certainly help you conceptualize the platform architecture. You will need to install it and run the daemon though.
 
You will need to install: 
- [Docker](https://docs.docker.com/docker-for-mac/)
- [OpenWhisk (Requires Dependencies)](https://github.com/openwhisk/openwhisk/blob/master/tools/macos/README.md)
- [OpenWhisk cli](https://console.ng.bluemix.net/openwhisk/cli)
- [CloudFoundry cli (For Bluemix)](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)
- [Python (2/3)](https://www.python.org/downloads/mac-osx/)
- [NodeJS & NPM (Latest)](http://blog.teamtreehouse.com/install-node-js-npm-mac)

### Notes

Please feel free to use this project as a primer for an OpenWhisk web application if you are not interested in doing a tutorial but looking for a basic scaffold with a deploy process. The initial setup instructions should get you started. 

### Preface

Just to quickly gloss over what you've probably read in the docs, *serverless is not truly serverless*. The term meant to denote the existence of an API host that activates remote, 'dockerized' compute events per request. These events remain inactive outside of near real-time usage so rely on a persistence layer for the state machine when required. OpenWhisk uses a swagger esque syntax for managing routes/CORS that you can read about [here](https://github.com/openwhisk/openwhisk/blob/master/docs/reference.md#rest-api). This layer of abstraction makes it easy for the developer(s) to assemble a centralized web API relying on *n* number of supporting environments with very little technical overhead outside their language(s) of choice. 

If you are wondering why there is a NodeJS/Express server and CF app deployment in this repo, this is only intended to serve static content. Setting up a serverless front-end is very do-able but to I wanted to keep this tutorial centered around how to cobble together back end assets. Some considerations being:

- For local front-end developement you will want to serve static on localhost without having to deploy your files every time you want to observe changes & on the cloud you need to serve the files from a store. 
- If your front-end application becomes large and complex by requiring many libraries (large framework extensions in particular) it is almost non-sensical to map tons of dependencies to respective endpoints. You need to consider using a minification process to avoid clutter.

*TL; DR: Consider deploying static content this way if you are planning to build a production ready UI for your OpenWhisk API. I have added links to the bottom that expand upon the subject.*

### Simple Use Case

I have a made up list of tasks, found in: `root/packages/config/tasks.json` and my core goal is to display this original task list and a random subset of 'daily tasks' via a web app. I want to provide an endpoint that responds with the task list data in NodeJS. I also want to create secondary endpoints that can sort the subset of tasks arbitrarily using python.
  
### Getting Started / Project Overview

Assuming you've installed all the dependencies, go ahead and run `./setup.sh local` in the root directory. This will create and deploy all the OpenWhisk assets found in the `/packages` directory. `/packages` contains a `env.sh` script and `/config` directory and handle pushing/serving the front-end.

Each package directory and action sub-directory contains an `initialize.sh` script which will simply run the appropriate wsk deployment command. If the action is to be web exported (meaning it requires an API endpoint) we map this action name to the appropriate url in `root/public/endpoints.json`. Also as a note, I am using `root/packages/config/tasks.json` which is just a flat file meant to emulate a store of some kind. With this in mind the general flow for this deployment is: 

`validate args on setup -> login to Bluemix to get OpenWhisk namespace -> configure the environment variables needed by *.sh scripts -> execute package and action scripts -> execute event deployment script -> serve the front-end on localhost or push it up to Bluemix`

- `packages/.env.sh` is where you should store any package level bash variables required in child scripts. In terms of package structure, follow this: `root/packages/<package>/<action>`. Declare `${any_package_name}` inside `.env.sh` so it can be accessed in `<package>/intialize.sh` and actions can be `${any_package_name}/${action}` inside `<package>/<any_action_name>/initialize.sh`. The variable `${action}` is scraped from the output of `pwd` to ensure that the directory and action names stay in sync. I've also added a var `${assets}` which is used to point to the location of the config directory to reduce verbosity. 
- `packages/config` is where you should place service/dependency credential files, flat files and other static assets for parameterizing actions & packages with default values. If you were hosting a DB somewhere for example, you could add the credentials to a json file here and use it to parameterize actions that execute DB functionality. The wsk cli uses `--param-file <file.json>` or `-p param_name 'your_string_here'` flags on create and update commands to achieve this. Parameters passed between OpenWhisk actions are always resolved in a single default parameter (json object) of a main method. 

I've parameterized the javascript/generateTasks action with the data contained in tasks.json to get started so lets imagine this is our hypothetical 'task factory' which our python code will extend. This action by default has the original task list accessible in `params` and performs some logic to chunk a subset of tasks that is appended to params and resolved down the chain.

### Adding a new action

Note: If you run into errors, run `wsk activation list` and you will see a stack of action names coupled with uuids that identify an instance of event execution. Copy the uuid value for the event instance you wish to see logs from and run `wsk activation logs 'id_value'` or `wsk activation get 'id_value'` for full verbosity.

Change directories to `root/packages/python` and run `mkdir sortAlphabetically && cd sortAlphabetically`. Confirm this worked and run `touch index.py && touch intialize.sh && chmod 776 intialize.sh`. 

The next step will be to set up the deployment script or `sortAlphabetically/initialize.sh`. We are keeping things bare minimum here. This action will always be parameterized by a successful invocation of javascript/generateTasks so worry about web-exporting when we make a sequence for it. `initialize.sh` should be as follows: 

```
. ../../env.sh

# deploy action
wsk action update ${py}/${action} index.py

wait
```

Congrats, even though you haven't added any code to index.py yet, you have just created the infrastructure for your first OpenWhisk action :cool:. The next step is to write our main python function to sort the incoming task-subset array alphabetically. `index.py` should be as follows: 

```
# This is used as an extension of the task factory to sort tasks
# alphabetically and returns only the sorted subset parameter

def main(params):
	
	return {'subset': sorted(params['subset'])}
```

Now that the function is written out it needs to be deployed and tested. Run `./intialize.sh` while you are still in this action directory to create the action. You should expect the output `ok: updated action python/sortAlphabetically`.

### Adding a new sequence and API endpoint

The next step is to chain this action onto `javaScript/generateTasks` so we can confirm that it works once parameterized. Change directories to `/root/packages/event_config.sh` and take a look at the comments I've left there for code pertinent details. All that needs to be done to accomplish the sequencing is to mimick the commands I used to create the getTasksByLength sequence. The commands should be added be as follows:

```
wsk action update --sequence ${seq}/getTasksAZ \
${js}/generateTasks,\
${py}/sortAlphabetically \
--web true

if [[ -n ${rest_endpoints} ]]; then 
	echo '"getTasksAZ":"'"${base_gateway_url}""${seq}"'/getTasksAZ.json",' >> ${rest_endpoints}
fi
```

Run `./event_config.sh` to create all events. To test our new sequence, run `wsk action invoke sequences/getTasksAZ -br`. The output should in the format of:

```
{
    "subset": [
        "Add Bluemix service credentials to a package.",
        "Add a swift package to the project.",
        "Try creating a custom docker environment for a blackbox action.",
        "Try creating a virtual python environment with an action."
    ]
}
```

If you are error free :clap:, return to the root directory and run `./setup.sh 'local | cloud'` to update the endpoints file and UI assets. Open the endpoints file and copy the url for sequences/getTasksAZ and run `curl url` to confirm the results.

It should be clear from looking at `root/public/index.js` how to use the endpoints file with AJAX style requests if you're used to front-end development. I suggest implementing some functionality that uses the getTasksAZ sequence if the pieces don't click there. Since this is not a front-end focused tutorial I don't plan to expand any further on the topic. Feel free to replace whatever you want in public or completely get rid of the directory / UI deployment code in `./setup.sh` if you are just looking to create web hooks. 

### Final Comments 

Hopefully the tutorial is helpful to those who are curious about stateless web development but are a little bit put off by idiosyncrasies that are not entirely addressed by the platform/documentation in terms of how you should organize your code base. This style of ad-hoc development can be very purposeful in that it allows freedom of control over verbiage used in orchestration. I know in this example I've named things 'python', 'javascript' or 'sequences' but only to help illustrate the ease of deploying a range of environments and to promote the policies of OpenWhisk. You can get as creative as you'd like once you feel comfortable with the tools!

Feel free to open issues / pull requests or contact me with suggestions & improvements. I will continue to expand this tutorial to include setting up a composeDB instance and follow that up with a demonstration of how you can use triggered events and rules to manage state.

### Further Reading

- [Setting up python virtual environments with non-default pip packages](http://jamesthom.as/blog/2017/04/27/python-packages-in-openwhisk/)
- [Setting up javascript actions with non-default npm packages](http://jamesthom.as/blog/2016/11/28/npm-modules-in-openwhisk/)
- [Setting up an nginx proxy for OpenWhisk web applications](https://medium.com/openwhisk/semi-custom-domains-for-openwhisk-web-apps-1ef1bd5bc437)
- [openwhisk-objectstore: One way to use objectstore to host static and deploy a stateless front-end, check the demo](https://github.com/starpit/openwhisk-objectstore)
- [Improving the performance of OpenWhisk applications](https://medium.com/openwhisk/squeezing-the-milliseconds-how-to-make-serverless-platforms-blazing-fast-aea0e9951bd0)
