"use strict"
var demo = angular.module("demo", []);

demo.factory("endpoints", function($http) {
    return $http({
        url: "https://dal.objectstorage.open.softlayer.com/v1/AUTH_f19aedb29fcf43a8a88f1ff36b3cc25e/static/endpoints.json",
        method: "GET",
        headers: {
            "Content-Type": "application/json"
        }
    }).then(function(endpoints) {
        return endpoints.data;
    });
});

demo.controller("ctrl", function($scope, $http, endpoints) {
    var ctrl = this;

    ctrl.model = {
        endpoints: {},
        activeList: [],
        allTasks: [],
        dailyTasks: [],
        dailyTasksSorted: [],
        err: "Something went wrong processing your request! Try refreshing the page.",
        dataLoaded: false,
        showErr: false
    }

    endpoints.then(function(ep) {
        ctrl.model.endpoints = ep;

        $http({
            url: ctrl.model.endpoints.generateTasks,
            method: "GET",
            headers: {
                "Content-Type": "application/json"
            }
        }).then(function(unsorted) {
            ctrl.model.allTasks = unsorted.data.tasks;
            ctrl.model.dailyTasks = unsorted.data.subset;

            $http({
                url: ctrl.model.endpoints.getTasksByLength,
                method: "GET",
                headers: {
                    "Content-Type": "application/json"
                }
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

angular.bootstrap(document, ["demo", "ngMaterial"]);