// This is used in the main pipeline to generate a subset of tasks
// using a shuffle algorithm

function main(params) {
	return new Promise((resolve, reject) => {
	    let l = params.tasks.length;

	    for(var i = 4; i--;) {
	        let idx = Math.floor(Math.random()*(l));
	        let tmp = params.tasks[idx];
	        params.tasks[idx] = params.tasks[i];
	        params.tasks[i] = tmp;
	    }

	    params.subset = params.tasks.slice(0, 4);

		resolve(params);
	});
}