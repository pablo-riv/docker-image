(function() {
  this.app.controller('MailNoticationController', ['$scope', '$sce', 'MailNotification', function($scope, $sce, MailNotification) {
    $scope.alerts = [];
    $scope.mail = {};
    $scope.company = {};
    $scope.helpLogo = 'Para configurar el logo de tu correo debes ir a <u><a href="http://clientes.shipit.cl/notifications" class="font-primary" data-turbolinks="false" target="_blank">Notificaciones</a></u> y pulsar el botón Configurar Formato.';
    $scope.testEmailTemplate = 'popover_email_test.html';
    $scope.testEmails = '';
    $scope.notifications = []
    $scope.api = {
      scope: $scope,
      editorConfig: $scope.editorConfig = {
        sanitize: true,
        fontAwesome: true,
        toolbar: [
          { name: 'basicStyling', items: ['undo', 'redo','bold', 'italic', 'underline', '-', 'leftAlign', 'centerAlign', 'rightAlign', 'blockJustify', '-'] },
          { name: 'paragraph', items: ['orderedList', 'unorderedList', 'outdent', 'indent', '-'] },
          { name: 'styling', items: ['size', 'format'] }
        ]
      }
    };

    $scope.loadCurrentMail = function(id) {
      MailNotification.findBy(id).then(function(data) {
        $scope.mail = data.mail;
        $scope.company = data.company;
        $scope.company.logo = data.logo.replace('//s3', 'https://s3-us-west-2');
        $scope.notifications = data.notifications
      }, function(error) {
        console.error(error);
        $scope.alerts.push({ message: '¡Hubo un problema al intentar obtener tu Información!, favor contactanos a ayuda@shipit.cl indicando tu problema', type: 'danger' });
      });
    };

    $scope.updateCurrentMail = function(mail) {
      MailNotification.update(mail).then(function(data) {
        $scope.alerts.push({ message: '¡Correo actualizado!', type: 'info' });
        $scope.mail = data.mail;
        $scope.company.logo = data.logo.replace('//s3', 'https://s3-us-west-2');
      }, function(error) {
        console.error(error);
        $scope.alerts.push({ message: '¡Hubo un problema al intentar obtener tu Información!, favor contactanos a ayuda@shipit.cl indicando tu problema', type: 'danger' });
      });
    };

    $scope.closeAlert = function(index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.activeColorPicker = function() {
      angular.element('#colorpicker-title').colorpicker();
      angular.element('#colorpicker-tracking-button').colorpicker();
      angular.element('#colorpicker-tracking-font').colorpicker();
      angular.element('#colorpicker-title-font').colorpicker();
    };

    $scope.sanitizeText = function(text) {
      return $sce.trustAsHtml(text);
    };

    $scope.sendEmailTest = function(testEmails) {
      MailNotification.test($scope.mail, testEmails).then(function(data) {
        $scope.alerts.push({ message: '¡Correos de prueba enviados!', type: 'success' });
      }, function(error) {
        console.error(error);
        $scope.alerts.push({ message: '¡Hubo un problema al enviar los correos de prueba!, favor contactanos a ayuda@shipit.cl indicando tu problema', type: 'danger' });
      });
    };

    $scope.activeTooltip = function() {
      angular.element('[data-toggle="tooltip"]').tooltip();
    };

  }]);
}).call(this);
