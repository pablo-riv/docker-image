(function () {
  this.app.value('cgBusyDefaults',{
    message:'Cargando',
    backdrop: false,
    templateUrl: 'loading.html',
    delay: 300,
    minDuration: 700,
    wrapperClass: 'center'
  });
}).call(this);