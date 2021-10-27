(function() {
  this.app.controller('MassiveController', ['$scope', '$q', '$uibModal', 'Package', 'Commune', 'Sku', 'Setting', 'CourierBranchOffice', 'PackageService', function($scope, $q, $uibModal, Package, Commune, Sku, Setting, CourierBranchOffice, PackageService) {
    var communes = [];
    var skus = [];
    $scope.hasFulfillment;
    $scope.packages = [];
    var prevLoadPackages = [];

    var validateStock = function(sku, amount, package) {
      if (sku.amount < amount) {
        alert('El pedido "' + package.reference + '" no se pudo cargar ya que el sku asociado no tiene stock suficiente.');
        return false;
      }
    }

    $scope.init = function() {
      Commune.all('').then(function(data) {
        communes = data.communes;
      }, function(error) {
        console.error(error);
      });

      Setting.current(4).then(function(data) {
        $scope.hasFulfillment = data;
        if ($scope.hasFulfillment) {
          Sku.by_client().then(function(data) {
            skus = data.client_skus;
          }, function(error) {
            alert('No se pudo obtener la lista de skus, intente denuevo mas tarde.');
          });
        }
      }, function(error) {
        alert('Tuvimos problemas corroborando tu cuenta fulfillment.');
      });
    };

    $scope.showLoadModal = function() {
      PackageService.launchLoadMassivePackagesModal(skus, communes, $scope.hasFulfillment).then(function(packages) {
        prevLoadPackages.push(packages);
        angular.forEach(packages, function(package) {
          $scope.addNewPackageToList(package);
        });
      }, function(error) {
        alert('No se han cargado pedidos', { type: 'warning' });
      });
    };

    $scope.undo = function() {
      if (prevLoadPackages.length > 0) {
        angular.forEach(prevLoadPackages[prevLoadPackages.length - 1], function(package) {
          $scope.packages = _.reject($scope.packages, function(current) {
            return current.reference == package.reference;
          });
        });
      }
    };

    $scope.addNewPackageToList = function(package) {
      var foundPackage = _.find($scope.packages, function(current) {
        return current.reference == package.reference;
      });
      if ($scope.hasFulfillment) {
        if (foundPackage == null) {
          foundPackage = package;
          foundPackage.inventory_activity = {};
          foundPackage.inventory_activity.inventory_activity_orders_attributes = [];
        }

        var foundSku = _.find(skus, function(sku) {
          return sku.name == package.skus;
        });

        if (foundSku == null) {
          alert('El pedido "' + package.reference + '" no se pudo cargar ya que el sku asociado no se encuentra.');
          return false;
        }


        if (foundPackage.inventory_activity.inventory_activity_orders_attributes.length > 0) {
          var foundIaoa = _.find(foundPackage.inventory_activity.inventory_activity_orders_attributes, function(iaoa) {
            return iaoa.id == foundSku.id;
          });

          if (foundIaoa != null) {
            validateStock(foundSku, (foundIaoa.amount + package.amount), package)
            foundIaoa.amount = foundIaoa.amount + package.amount;
          } else {
            validateStock(foundSku, (package.amount), package)
            foundPackage.inventory_activity.inventory_activity_orders_attributes.push({ name: foundSku.name, sku_id: foundSku.id, amount: package.amount, warehouse_id: foundSku.warehouse_id });
          }

        } else {
          validateStock(foundSku, (foundPackage.amount), package)
          foundPackage.inventory_activity.inventory_activity_orders_attributes.push({ name: foundSku.name, sku_id: foundSku.id, amount: foundPackage.amount, warehouse_id: foundSku.warehouse_id });
          $scope.packages.push(foundPackage);
        }
      } else {
        if (!foundPackage) {
          $scope.packages.push(package);
        }
      }
      console.info(package);
    };

    $scope.sendPackages = function() {
      $scope.loading = true;
      Package.sendMassive($scope.packages).then(function(data) {
        $scope.loading = false;
        alert('Envíos creados exitosamente');
        window.location.href = '/packages';
      }, function(error) {
        $scope.loading = false;
        alert('Hubo un problema intentando crear los pedidos:');
        window.location.reload();
      });
    };
  }]).
  controller('LoadMassivePackagesModalInstanceController', ['$scope', '$uibModalInstance', 'XlsService', 'Package', 'skus', 'communes', 'hasFulfillment', function($scope, $uibModalInstance, XlsService, Package, skus, communes, hasFulfillment) {
    $scope.skus = skus;
    $scope.communes = communes;
    $scope.filePackages = [];
    $scope.hasFulfillment = hasFulfillment;

    $scope.loadFile = function(event) {
      var files = event.files,
        i, f;
      for (i = 0, f = files[i]; i != files.length; ++i) {
        var reader = new FileReader();
        reader.onload = function(e) {
          var data = e.target.result;
          $scope.workbook = XLSX.read(data, { type: 'binary' });
          $scope.$apply(function functionName() {
            $scope.filePackages = XlsService.processPackageMassive($scope.workbook, $scope.filePackages, Package.new({ platform: 4 }), $scope.communes, { id: 0 }, $scope.hasFulfillment);
          });
        };
        reader.readAsBinaryString(f);
      }
    };

    $scope.sumPackagesList = function() {
      $uibModalInstance.close($scope.filePackages);
    };

    $scope.closeAlert = function(index) {
      window.location.reload();
    };
  }]);
}).call(this);
