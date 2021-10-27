(function () {
  this.app.service('StatusService', ['$q', function ($q) {
    return {
      color: function (status) {
        var klass = '';
        switch (status) {
          case 'created':
            klass = 'created';
            break;
          case 'in_preparation':
            klass = 'process';
            break;
          case 'in_route':
            klass = 'route';
            break;
          case 'by_retired', 'at_shipit':
            klass = 'by-retired';
            break;
          case 'delivered':
            klass = 'delivery';
            break;
          case 'failed':
            klass = 'fail';
            break;
          case 'indemnify', 'other', 'returned':
            klass = 'other';
            break;
          case 'ready_to_dispatch':
            klass = 'ready_to_dispatch';
            break;
          case 'dispatched':
            klass = 'dispatched';
            break;
          case 'returned_in_route':
            klass = 'returned_in_route';
            break;
          default:
            klass = 'process';
            break;
        }
        return klass;
      },

      text: function (status) {
        var name = '';
        switch (status) {
          case 'created':
            name = 'Creado';
            break;
          case 'in_preparation':
            name = 'Preparando';
            break;
          case 'in_route':
            name = 'En Ruta';
            break;
          case 'delivered':
            name = 'Entregado';
            break;
          case 'failed':
            name = 'Rechazado';
            break;
          case 'by_retired':
            name = 'Por Retirar';
            break;
          case 'at_shipit':
            name = 'En Shipit';
            break;
          case 'returned':
            name = 'Devuelto';
            break;
          case 'ready_to_dispatch':
            name = 'Listo para Despachar';
            break;
          case 'dispatched':
            name = 'Entregado a Courier';
            break;
          case 'returned_in_route':
            name = 'Devolución en Ruta';
            break;

          default:
            name = 'Preparando';
            break;
        }
        return name;
      }

    };
  }]);
}).call(this);