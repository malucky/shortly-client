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
    _.each($scope.links, function(link){
      link.sortingTitle = link.title.toLowerCase().trim();
    });
  });

  $scope.displayOptions = {
    reverse: true,
    orderBy: 'sortingTitle'
  };

  $scope.sayHello = function(){
    // alert('hello');
    $scope.displayOptions.reverse = !$scope.displayOptions.reverse;
    // debugger;
  };

  $scope.getLastClicked = function(lastclicked){
    if(lastclicked !== null){
      return new Date(Number(lastclicked) * 1000).toLocaleString();
    } else {
      return 'not visited';
    }
  };
});