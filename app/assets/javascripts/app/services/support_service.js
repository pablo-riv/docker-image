(function() {
  this.app.service('SupportService', ['$q', '$uibModal', function($q, $uibModal) {
    return {
      getClassifyStatus: function(status) {
        var klass = '';
        switch (status) {
          case 'open':
            klass = 'tag-danger';
            break;
          case 'pending':
            klass = 'tag-info';
            break;
          case 'closed', 'solved':
            klass = 'tag-success';
            break;
          default:
            klass = 'tag-primary';
          break;
        }
        return klass;
      },

      classifySupport: function(priority) {
        var klass = '';
        switch (priority) {
          case 'urgent':
            klass = 'tag-danger';
            break;
          case 'high':
            klass = 'tag-warning';
            break;
          case 'normal':
            klass = 'tag-info';
            break;
          case 'low':
            klass = 'tag-primary';
            break;
          default:
            klass = 'tag-primary';
          break;
        }
        return klass;
      },

      getPriority: function(priority) {
        var name = '';
        switch (priority) {
          case 'urgent':
            name = 'Urgente';
            break;
          case 'high':
            name = 'Alta';
            break;
          case 'normal':
            name = 'Normal';
            break;
          case 'low':
            name = 'Baja';
            break;
          default:
            name = 'Sin Prioridad';
          break;
        }
        return name;
      },

      getKind: function(kind) {
        var name = '';
        switch (kind) {
          case 'problem':
            name = 'Problema';
            break;
          case 'incident':
            name = 'Incidente';
            break;
          case 'question':
            name = 'Pregunta';
            break;
          case 'task':
            name = 'Tarea';
            break;
          default:
            name = 'No especificada';
          break;
        }
        return name;
      },

      getAgent: function(agent) {
        var name = '';
        switch (agent) {
          case 'carolina@shipit.cl':
            name = 'Carolina';
            break;
          case 'macarena@shipit.cl':
            name = 'Macarena';
            break;
          case 'pamela@shipit.cl':
            name = 'Pamela';
            break;
          case 'natalia.pinilla@shipit.cl':
            name = 'Natalia';
            break;
          default:
            name = 'hola@shipit.cl';
          break;
        }
        return name;
      },

      getStatusName: function(status) {
        var name = '';
        switch (status) {
          case 'open':
            name = 'Abierto';
            break;
          case 'pending':
            name = 'Pendiente';
            break;
          case 'closed':
            name = 'Cerrado';
            break;
          case 'solved':
            name = 'Resuelto';
            break;
          default:
            name = 'Sin Estado';
          break;
        }
        return name;
      },

      showDetail: function(id) {
        var defer = $q.defer();
        var modal = $uibModal.open({
          animation: true,
          ariaLabelledBy: 'modal-title',
          ariaDescribedBy: 'modal-body',
          templateUrl: 'support_detail.html',
          controller: 'HelpShowController',
          size: 'lg',
          resolve: {
            supportId: function() {
              return id;
            }
          }
        });
        modal.result.then(function(data) {
          defer.resolve(data);
        }, function(error) {
          defer.resolve(error);
        });
        return defer.promise;
      },
      createModal: function(data) {
        var defer = $q.defer();
        var modal = $uibModal.open({
          animation: true,
          ariaLabelledBy: 'modal-title',
          ariaDescribedBy: 'modal-body',
          templateUrl: 'support_create.html',
          controller: 'HelpCreateController',
          size: 'lg',
          resolve: {
            package: data
          }
        });
        modal.result.then(function(data) {
          defer.resolve(data);
        }, function(error) {
          if (error !== 'backdrop click') {
            defer.reject();
          }
        });
        return defer.promise;
      },

      validate: function(support) {
        var errors = [];
        if (support.subject == '' || support.subject.length <= 3) {
          errors.push({ message: 'Ticket debe tener un motivo...', type: 'danger' });
        }

        if (support.messages[0].message == '' || support.messages[0].message.length <= 3) {
          errors.push({ message: 'Ticket debe tener un mensaje...', type: 'danger' });
        }
        if (support.other_subject == '' || support.other_subject == void(0)) {
          errors.push({ message: 'Ticket debe sub motivo...', type: 'danger' });
        }
        return errors;
      },

      subjects: function () {
        return [{ subject: 'Consulta sobre ingreso de solicitud', id: 1 },
                { subject: 'Consulta sobre un envío', id: 2 },
                { subject: 'Consulta sobre devoluciones', id: 3 },
                { subject: 'Consulta sobre un Retiro', id: 4 },
                { subject: 'Consulta sobre reembolso', id: 5 },
                { subject: 'Cancelar un envío', id: 6 },
                { subject: 'Consulta sobre Facturación', id: 7 },
                { subject: 'Nuevas Dudas comerciales', id: 8 },
                { subject: 'Otro Motivo', id: 9 }];
      },

      otherSubjects: function(id) {
        return [{ subject: 'Tengo un error al ingresar la información', id: 1},
                { subject: 'No se procesan los envíos', id: 1 },
                { subject: 'Necesito saber el estado de mi pedido', id: 2 },
                { subject: 'Quiero cambiar información del envío', id: 2 },
                { subject: 'No se actualiza el tracking', id: 2 },
                { subject: 'Consultar sobre estado', id: 3 },
                { subject: 'Shipit recibió una devolución y necesito reenviar el pedido', id: 3 },
                { subject: 'No se actualiza la información de tracking', id: 3 },
                { subject: 'Quiero cancelar retiro', id: 4 },
                { subject: 'Quiero saber cuándo retirarán', id: 4 },
                { subject: 'No se realizó un retiro solicitado', id: 4 },
                { subject: 'Quiero notificar un pedido extraviado', id: 5 },
                { subject: 'Quiero notificar un pedido dañado', id: 5 },
                { subject: 'No aplica', id: 6 },
                { subject: 'Tengo un problema con el cobro', id: 7 },
                { subject: '¿Cuándo recibiré mi factura?', id: 7 },
                { subject: 'Quiero contratar Fulfillment (Bodegaje)', id: 8 },
                { subject: 'Necesito información sobre el servicio', id: 8 },
                { subject: 'Necesito las tarifas de los servicio', id: 8 },
                { subject: 'No aplica', id: 9 }];
      }

    };
  }]);
}).call(this);
