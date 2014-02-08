var shortlyApp = angular.module("shortlyApp", ['ngRoute'])
.config(function($routeProvider){
  $routeProvider
    .when('/', {
      controller: 'LinksController',
      templateUrl: 'client/templates/home.html'
    })
    .otherwise({
      redirectTo: '/'
    });
})
.controller('FrameController', function($scope, $http){

})
.controller('LinksController', function($scope, $http){
  $http({
    method: 'GET',
    url: '/links'
  })
  .then(function(result){
    $scope.links = result.data;
    $scope.links.lastClicked = "never!!"
  });

  $scope.print
});