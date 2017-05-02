# This is used as an extension of the task factory to sort tasks
# by string length and returns only the sorted subset parameter

def main(params):
	l = len(params['subset'])

	for i in range(l):
		for j in range(i + 1, l):
			if len(params['subset'][i]) > len(params['subset'][j]):
				t = params['subset'][i]
				params['subset'][i] = params['subset'][j]
				params['subset'][j] = t

	return {'subset': params['subset']}