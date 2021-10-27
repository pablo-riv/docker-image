(function() {
  this.app.controller('BranchOfficesController', ['$scope', '$uibModal', 'BranchOffice', 'Commune', function($scope, $uibModal, BranchOffice, Commune) {
    $scope.branchOffices = [];
    $scope.communes = [];

    $scope.loadBranchOffices = function(company) {
      BranchOffice.all(company).then(function(data) {
        $scope.branchOffices = data.branch_offices;
      }, function(data) {
        console.error(data);
      });

      Commune.all('branch_offices').then(function(data) {
        $scope.communes = data.communes;
      }, function(data) {
        console.error(data);
      });
    };

    $scope.lunchModal = function(type, branchOffice) {
      var modal = $uibModal.open({
        animation: true,
        ariaLabelledBy: 'modal-title',
        ariaDescribedBy: 'modal-body',
        templateUrl: (angular.equals({}, branchOffice) ? 'marketplace_request' : 'branch_offices') + '.html',
        controller: 'BranchOfficeModalInstanceController',
        size: 'lg',
        resolve: {
          communes: function() {
            return $scope.communes;
          },
          branchOffice: function() {
            return branchOffice;
          },
          type: function() {
            return type;
          }
        }
      });
      modal.result.then(function(branchOffices) {
        $scope.branchOffices = branchOffices;
      }, function(error) {
        if (error !== 'backdrop click') {
          window.location.reload(true);
        }
      });
    };

  }]).
  controller('BranchOfficeModalInstanceController', ['$scope', '$uibModalInstance', 'BranchOffice', 'communes', 'branchOffice', 'type', function($scope, $uibModalInstance, BranchOffice, communes, branchOffice, type) {
    $scope.communes = communes;
    $scope.branchOffice = type == 'new' ? BranchOffice.new() : branchOffice;
    $scope.type = type;
    $scope.request = { email: '', full_name: '', phone: '', message: '' };
    $scope.createBranchOffice = function(branchOffice) {
      if (BranchOffice.valid($scope.branchOffice)) {
        BranchOffice.create($scope.branchOffice).then(function(data) {
          $uibModalInstance.close(data.branch_offices);
        }, function(data) {
          $uibModalInstance.dismiss(data);
          console.error(data);
        });
      } else {
        alert('Todos los datos son obligatorios');
      }
    };

    $scope.updateBranchOffice = function(branchOffice) {
      var valid = false;
      if (branchOffice.password !== undefined || branchOffice.password_confirmation !== undefined) {
        valid = branchOffice.password === branchOffice.password_confirmation ? true : false;
      } else {
        valid = branchOffice.password === undefined && branchOffice.password_confirmation == undefined ? true : false;
      }
      if (valid) {
        BranchOffice.update(branchOffice).then(function(data) {
          $uibModalInstance.close(data.branch_offices);
        }, function(data) {
          $uibModalInstance.dismiss(data);
          console.error(data);
        });
      } else {
        alert('Datos incorrectos, favor validar');
      }
    };

    $scope.loadCommunes = function() {
      angular.element('#communes').select2({ width: '100%' });
    };

    $scope.loadAccountData = function(data) {
      $scope.request.email = data.email;
      $scope.request.phone = data.entity_specific.phone;
      $scope.request.full_name = data.person.first_name + ' ' + data.person.last_name;
    };

    $scope.sendMarketPlaceRequest = function(data) {
      if (data.email != '' && data.full_name != '' && data.phone != '' && data.message != '') {
        BranchOffice.marketPlaceRequest(data).then(function(data) {
          alert('Solicitud recibida, pronto se contactarán para finalizar el proceso.', { type: 'success' });
          window.location.href = '/dashboard';
        }, function(data) {
          alert('Hubo un error en el proceso, favor intentar más tarde');
          console.error(data);
        });
      } else {
        alert('Todos los campos son obligatorios!', { type: 'error' });
      }
    }
  }]);
}).call(this);