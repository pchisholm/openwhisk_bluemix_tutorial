var demo = angular.module('demo', ['ngMaterial']);

demo.factory('endpoints', function ($http) {
  return $http(
  	{
  		url: 'endpoints.json',
  		method: 'GET'
  	}).then(function(endpoints) {
    	return endpoints.data;
  	});
});

demo.controller('ctrl', function($scope, $http, endpoints) {
    var ctrl = this;
    
    ctrl.model = {
    	endpoints: {},
        activeList: [],
    	allTasks: [],
    	dailyTasks: [],
    	dailyTasksSorted: [],
    	err: 'Something went wrong processing your request! Try refreshing the page.',
        dataLoaded: false,
    	showErr: false
    }

    endpoints.then(function(ep) {
    	ctrl.model.endpoints = ep;

    	$http({
    		url: ctrl.model.endpoints.generateTasks,
    		method: 'GET'
    	}).then(function(init) {
    		ctrl.model.allTasks = init.data.tasks;
    		ctrl.model.dailyTasks = init.data.subset;

    		$http({
    			url: ctrl.model.endpoints.getSortedTasks,
    			method: 'GET'
    		}).then(function(sorted) {
    			ctrl.model.dailyTasksSorted = sorted.data.subset;
    			ctrl.model.activeList = ctrl.model.allTasks;
                ctrl.model.dataLoaded = true;
    		}, function(err) {
                ctrl.model.showErr = true;
            });
    	}, function(err) {
            ctrl.model.showErr = true;
        });
    }, function(err) {
        ctrl.model.showErr = true;
    });

    ctrl.setAllTasks = function() {
        ctrl.model.activeList = ctrl.model.allTasks;
    };

    ctrl.setDailyTasks = function() {
        ctrl.model.activeList = ctrl.model.dailyTasks;
    };

    ctrl.setDailyTasksSorted = function() {
        ctrl.model.activeList = ctrl.model.dailyTasksSorted;
    };
});