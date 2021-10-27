(function() {
  this.app.controller('AnalyticsController', ['$scope', '$q', '$uibModal', '$timeout', 'Analytics', function($scope, $q, $uibModal, $timeout, Analytics) {
    $scope.data = {
      allPackages: {},
      companyPackages: {},
      orders: {},
      notifications: {},
      supports: {},
      charts: {}
    };
    $scope.processedData = {};
    $scope.percentages = {};
    $scope.periods = [
      {id: 'week', name: 'Últimos 7 días'},
      {id: 'two_weeks', name: 'Últimos 15 días'},
      {id: 'month', name: 'Últimos 30 días'},
      {id: 'two_months', name: 'Últimos 60 días'}
    ];
    $scope.packageSortByCommune = [];
    $scope.packageSortByCourier = [];
    $scope.selectedPeriod;
    $scope.loading;

    $scope.setDate = function(dates, periodLength) {
      $scope.search = {
        from: dates.from_date,
        to: dates.to_date,
        lastFrom: dates.last_from_date,
        lastTo: dates.last_to_date,
        periodLength: periodLength
      }
    };

    $scope.searchByDate = function() {
      if ($scope.search.from == "" || $scope.search.from == null || $scope.search.to == "" || $scope.search.to == null) return;
      $scope.loading = true;
      search = { from: $scope.search.from, to: $scope.search.to };
      Analytics.getData(search).then(function(response) {
        $scope.setDate(response.dates, response.period_length);
        fillData(response);
        calculationProcess().then(function(_resolve) {
          $timeout(function() {
            setCharts();
          }, 0);
        }).catch(function() {
          alert('error')
        });
        $scope.loading = false;
      }).catch(function(response){
        alert(response.message);
      });
    };

    $scope.searchByPeriod = function() {
      if ($scope.selectedPeriod == "" || $scope.selectedPeriod == null) return;
      $scope.loading = true;
      search = { from: $scope.selectedPeriod };
      Analytics.getData(search).then(function(response) {
        $scope.setDate(response.dates, response.period_length);
        fillData(response);
        calculationProcess().then(function(_resolve) {
          $timeout(function() {
            setCharts();
          }, 0);
        }).catch(function() {
          alert('error')
        });
        $scope.loading = false;
      }).catch(function(response){
        alert(response.message);
      });
    };

    $scope.showProgramAnalyticsModal = function() {
      var modal = $uibModal.open({
        animation: true,
        ariaLabelledBy: 'modal-title',
        ariaDescribedBy: 'modal-body',
        templateUrl: 'programAnalyticsModal.html',
        controller: 'AnalyticsModalInstanceController',
        size: 'lg',
        resolve: {
        }
      });
      modal.result.then(function() {
      });
    };

    $scope.withDelimiter = function(number){
      try {
        number = (number).toString().split(".");
        return number[0].replace(/\B(?=(\d{3})+(?!\d))/g, ".") + (number[1] ? "," + number[1] : "");
      } catch (e) {
        return 0;
      }
    };

    var fillData = function(data) {
      $scope.data.allPackages.currentPackages = data.all_packages.all_current_packages;
      $scope.data.allPackages.lastPackages = data.all_packages.all_last_packages;
      $scope.data.companyPackages.currentPackages = data.packages.current_period_packages;
      $scope.data.companyPackages.lastPackages = data.packages.last_period_packages;
      $scope.data.orders.currentOrders = data.orders.current_period_orders;
      $scope.data.orders.lastOrders = data.orders.last_period_orders;
      $scope.data.notifications.currentNotifications = data.notifications.current_period_notifications;
      $scope.data.notifications.lastNotifications = data.notifications.last_period_notifications;
      $scope.data.supports.currentSupports = data.supports.current_period_supports;
      $scope.data.supports.lastSupports = data.supports.last_period_supports;
      $scope.data.charts.packages = data.charts.packages;
      $scope.data.charts.orders = data.charts.orders;
    };

    var calculationProcess = function() {
      var defer = $q.defer();
      setQuantity($scope.data);
      setPackageSla($scope.data);
      setTotalPrice($scope.data);
      setOrderAverage($scope.processedData);
      setNotificationsAverage($scope.processedData);
      setPercent($scope.processedData);
      communeGroupPackages();
      courierGroupPackages().then(function(_resolve) {
        defer.resolve(_resolve);
      }, function(_error) {
        defer.reject(error);
      });
      return defer.promise;
    };

    var setQuantity = function(data) {
      $scope.processedData.currentPackageQuantity = quantity(data.companyPackages.currentPackages);
      $scope.processedData.lastPackageQuantity = quantity(data.companyPackages.lastPackages);
      $scope.processedData.allCurrentPackageQuantity = quantity(data.allPackages.currentPackages);
      $scope.processedData.allLastPackageQuantity = quantity(data.allPackages.lastPackages);
      $scope.processedData.currentOrdersQuantity = quantity(data.orders.currentOrders);
      $scope.processedData.lastOrdersQuantity = quantity(data.orders.lastOrders);
      $scope.processedData.currentNotificationsQuantity = quantity(data.notifications.currentNotifications);
      $scope.processedData.lastNotificationsQuantity = quantity(data.notifications.lastNotifications);
      $scope.processedData.currentSupportQuantity = quantity(data.supports.currentSupports);
      $scope.processedData.lastSupportQuantity = quantity(data.supports.lastSupports);
    };

    var setPackageSla = function(data) {
      $scope.processedData.currentSla = $scope.slaCalculation(data.companyPackages.currentPackages);
      $scope.processedData.lastSla = $scope.slaCalculation(data.companyPackages.lastPackages);
      $scope.processedData.currentGlobalSla = $scope.slaCalculation(data.allPackages.currentPackages);
      $scope.processedData.lastGlobalSla = $scope.slaCalculation(data.allPackages.lastPackages);
    };

    var setNotificationsAverage = function(data) {
      $scope.processedData.currentAverageNotifications = calculateAverage(data.currentNotificationsQuantity, data.currentPackageQuantity)
      $scope.processedData.lastAverageNotifications = calculateAverage(data.lastNotificationsQuantity, data.lastPackageQuantity)
    };

    var setPercent = function(data) {
      $scope.percentages.packageNumber = calculatePercent(data.currentPackageQuantity, data.lastPackageQuantity);
      $scope.percentages.companySla = calculatePercent(data.currentSla, data.lastSla);
      $scope.percentages.globalSla = calculatePercent(data.currentGlobalSla, data.lastGlobalSla);
      $scope.percentages.ordersNumber = calculatePercent(data.currentOrdersQuantity, data.lastOrdersQuantity);
      $scope.percentages.ordersAverage = calculatePercent(data.currentAverageOrders, data.lastAverageOrders);
      $scope.percentages.ordersDayAverage = calculatePercent(data.currentDayAverageOrders, data.lastDayAverageOrders);
      $scope.percentages.notificationNumber = calculatePercent(data.currentNotificationsQuantity, data.lastNotificationsQuantity);
      $scope.percentages.notificationAverage = calculatePercent(data.currentAverageNotifications, data.lastAverageNotifications);
      $scope.percentages.supportNumber = calculatePercent(data.currentSupportQuantity, data.lastSupportQuantity);
    };

    var quantity = function(packages) {
      return packages.length;
    };

    $scope.slaCalculation = function(packages) {
      if (packages.length == 0)
        return '-'
      accomplished = packages.filter(function(package) { 
        return package.total == true
      }).length;
      unaccomplished = packages.filter(function(package) { 
        return package.total == false
      }).length;
      total = (accomplished / (accomplished + unaccomplished) * 100).toFixed(1) || 0;
      return total.toString();
    };

    var setTotalPrice = function(data) {
      $scope.processedData.currentTotalPrice = calculateTotalPrice(data.orders.currentOrders[0]);
      $scope.processedData.lastTotalPrice = calculateTotalPrice(data.orders.lastOrders[0]);
    };

    var setOrderAverage = function(data) {
      $scope.processedData.currentAverageOrders = calculateAverage(data.currentTotalPrice, data.currentOrdersQuantity);
      $scope.processedData.lastAverageOrders = calculateAverage(data.lastTotalPrice, data.lastOrdersQuantity);
      $scope.processedData.currentDayAverageOrders = calculateAverage(data.currentOrdersQuantity, $scope.search.periodLength);
      $scope.processedData.lastDayAverageOrders = calculateAverage(data.lastOrdersQuantity, $scope.search.periodLength);
    };

    var calculateTotalPrice = function(orders) {
      if (orders == null) return 0;
      totalPrice = 0;
      orders.forEach(function(order){
        totalPrice += order.total_price;
      });
      return totalPrice;
    };

    var calculateAverage = function(partial, total){
      if (total == 0) return 0;
      return (partial / total).toFixed(1);
    };

    var calculatePercent = function(current, last) {
      if (parseFloat(last) == 0)
        return "100";
      if (current == last || last == '-' || current == '-')
        return "0";
      else {
        parsedCurrentPeriod = parseFloat(current);
        parsedLastPeriod = parseFloat(last);
        return ((parsedCurrentPeriod - parsedLastPeriod) / parsedLastPeriod * 100).toFixed(1).toString();
      }
    };

    var communeGroupPackages = function() {
      packages = $scope.data.companyPackages.currentPackages;
      communeGroup = _.groupBy(packages, 'commune_name');
      $scope.packageSortByCommune = sortPackages(communeGroup);
    };

    var courierGroupPackages = function() {
      var defer = $q.defer();
      packages = $scope.data.companyPackages.currentPackages;
      courierGroup = _.groupBy(packages, 'courier_for_client');
      $scope.packageSortByCourier = sortPackages(courierGroup);
      var sorted = sortPackages(courierGroup);
      if (sorted) {
        defer.resolve(sorted);
      } else {
        defer.reject('error');
      }
      return defer.promise;
    };

    var sortPackages = function(packages) {
      packages = Object.entries(packages);
      packagesArray = [];
      angular.forEach(packages, function(package){
        packagesArray.push({name: setName(package[0]), length: package[1].length, sla: $scope.slaCalculation(package[1])});
      });
      return packagesArray.sort(function(a, b){return b.length - a.length});
    };

    var setName = function(packageName) {
      if (packageName == null || packageName == 'null' || packageName == '') return 'Sin Courier';
      else return packageName;
    };

    var setCharts = function() {
      if (document.querySelector('#chart-package') != null && document.querySelector('#chart-order')  != null) {
        console.log($scope.data.charts.packages);
        new Chartkick.AreaChart(document.querySelector('#chart-package'), $scope.data.charts.packages, { colors: ['rgba(0, 194, 222, 0.6)', 'rgba(72, 74, 125, 0.5)'],
          xtitle: 'Días', ytitle: 'Envíos', curve: false, thousands: ".", decimal: ","});
        new Chartkick.AreaChart(document.querySelector('#chart-order'), $scope.data.charts.orders, { colors: ['rgba(0, 194, 222, 0.6)', 'rgba(72, 74, 125, 0.5)'],
          xtitle: 'Días', ytitle: '$ Ventas', curve: false, thousands: ".", decimal: ",", prefix: '$' });
      }
    }
  }])
}).call(this);
