//Info cliente para recuperar el key y secret_key
// LAST MODIFICATION:
// REF: https://shipitchile.atlassian.net/browse/APPS-964
// DATE: 10/15/2020

var ss = SpreadsheetApp.getActiveSpreadsheet();
var planilla_data_client = ss.getSheetByName('Only For Shipit');
var data_client = planilla_data_client.getRange(2, 1, 1, 3).getValues();
this.key = data_client[0][0];
this.secret_key = data_client[0][1];

function send(is_production) {
  set_triggers();
  var shipit = new Shipit(is_production, this.key, this.secret_key);
  return shipit.createMassPackage();
}

function check_production(is_production = true) {
  set_triggers();
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var planilla_pickup = ss.getSheetByName('Pickup');
  var startRow_pickup = planilla_pickup.getLastRow();
  var number_pickup = startRow_pickup - 1;
  var startColumn_pickup = planilla_pickup.getLastColumn();
  var datos_pickup = planilla_pickup.getRange(2, 1, number_pickup, startColumn_pickup);
  var info_pickup = datos_pickup.getValues();
  var message = '';
  for (var i = 0; i < number_pickup; i++) {
    if (info_pickup[i][0] == "") {
      message += 'Falta el ID, en la línea ' + (i + 2) + '\\n';
    }

    if (info_pickup[i][1] == '') {
      message += 'Falta el número de bultos, en la línea ' + (i + 2) + ' \\n'
    }

    if (info_pickup[i][3] == '') {
      message += 'Falta el tiempo de envío, en la línea ' + (i + 2) + ' \\n';
    }

    if (info_pickup[i][3].toLowerCase() == 'sábado' && info_pickup[i][15].toLowerCase() == 'si') {
      message += 'No se puede enviar el producto, en la línea ' + (i + 2) + ' el por pagar el Sábado \\n';
    }

    if (info_pickup[i][4] == '') {
      message += 'Falta la comuna, en la línea ' + (i + 2) + ' \\n';
    }

    if (info_pickup[i][5] == '') {
      message += 'Falta envío a sucursal o domicilio, en la línea ' + (i + 2) + '\\n';
    }

    if (info_pickup[i][6] == '') {
      message += 'Falta envío a sucursal o domicilio, en la línea ' + (i + 2) + '\\n';
    }

    if (info_pickup[i][7] == '') {
      message += 'Falta la calle, en la línea ' + (i + 2) + '\\n';
      planilla_pickup.getRange(2 + i, 8).clearDataValidations();
    }

    if (info_pickup[i][8] == '') {
      message += 'Falta el número de la dirección, en la línea ' + (i + 2) + '\\n';
      planilla_pickup.getRange(2 + i, 14).clearDataValidations();
    }

    if (info_pickup[i][10] == '') {
      message += 'Falta el tamaño, en la línea ' + (i + 2) + '\\n';
    }

    if (info_pickup[i][15].toLowerCase() == 'chilexpress' && info_pickup[i][5] == 'Sucursal Starken-Turbus') {
      message += 'Tu courier de preferencia no coincide con el de la sucursal seleccionada en la línea ' + (i + 2) + '\\n';
    }

    if (info_pickup[i][15].toLowerCase() == 'starken' && info_pickup[i][5] == 'Sucursal Chilexpress') {
      message += 'Tu courier de preferencia no coincide con el de la sucursal seleccionada en la línea ' + (i + 2) + '\\n';
    }

    if (info_pickup[i][15] != '') {
      if (!['Chilexpress', 'Starken', 'Chileparcels', 'Motopartner', 'Bluexpress', 'Shippify', 'Muvsmart'].includes(info_pickup[i][15].toLowerCase())) {
        message += 'Por favor, ingresar Chilexpress/Starken/CorreosChile como courier o dejar casilla ' + (i + 2) + ' en blanco' + '\\n';
      }
    }

    if (info_pickup[i][0].length > 15) {
      message += 'El largo del ID de Pedido no puede superar los 15 caracteres. \\n'
    }

    if (info_pickup[i][13].toLowerCase() == 'si' && !['starken'].includes(info_pickup[i][15].toLowerCase())) {
      message += 'El envío no puede ser despachado bajo el courier: ' + info_pickup[i][15] + '. \\n'
    }

    if (info_pickup[i][16].toLowerCase() == 'si') {
      if (info_pickup[i][17] == '' || info_pickup[i][18] == '' || info_pickup[i][19] == '') {
        message += 'Por favor, ingresar información adicional del seguro o dejar casilla ' + (i + 2) + ' en blanco' + ' \n';
      }
    } else {
      info_pickup[i][17] = '';
      info_pickup[i][18] = '';
      info_pickup[i][19] = '';
      ss.toast('El envío ' + info_pickup[i][0] + ' no será considerado en posibles indemnizaciones');
    }
  }
  if (message == '') {
    datos_pickup.setBackground('white');
    ss.toast('Generando la solicitud de retiro en la plataforma');
    try {
      var response = send(is_production);
      if (response.code >= 400 && response.code <= 404) {
        throw response.result;
      } else {
        Browser.msgBox('Solicitud enviada. En los próximos minutos te enviaremos un correo con la información del Héroe asignado.');
      }
    } catch (error) {
      Browser.msgBox(error.message);
    }
  } else {
    Browser.msgBox(message);
  }
}

function clean_temporary() {
  var planilla_pickup = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Pickup');
  var LastRow_pickup = planilla_pickup.getLastRow();
  var LastColumn_pickup = planilla_pickup.getLastColumn();
  planilla_pickup.getRange(2, 1, LastRow_pickup, LastColumn_pickup).clear();
}

function set_triggers() {
  var allTriggers = ScriptApp.getProjectTriggers();
  var ss = SpreadsheetApp.getActive();

  if (allTriggers.length <= 0) {
    ScriptApp.newTrigger('clean').timeBased().atHour(01).everyDays(1).create();
    ScriptApp.newTrigger('getSettings').forSpreadsheet(ss).onOpen().create();
  }
}

function menuItems() {
  try {
    getCouriers();
    var message = "Hola! Evita los siguientes errores para poder ingresar una solicitud correctamente: \\n" +
      "\\n 1.- Pegar incorrectamente el contenido. (Puedes utilizar el atajo ctrl+shift+v para mantener el formato)." +
      "\\n 2.- Ingresar comunas con letra minúscula y/o caracteres especiales (correctamente con mayúscula)." +
      "\\n 3.- ¡Ahora puedes asegurar el reembolso de tu envío!¡Solo debes marcar la opción 'Asegurar Envío' y completar la información adicional!" +
      "\\n \\n IMPORTANTE: En caso de no aparecer el botón 'Shipit', por favor, recarga la página.";
    Browser.msgBox(message);
    var options = [
      ['Enviar correo de solicitud (Acepto Términos y Condiciones)', 'create_shipments']
    ]
  } catch (e) {
    Browser.msgBox(e);
  }
  return options;
}

function getPacking() {
  var packagings = ['Sin empaque', 'Caja de Cartón', 'Film Plástico', 'Caja + Burbuja', 'Bolsa Courier']
  var packings_size = packagings.length;
  var hoja_packings = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Packings');
  hoja_packings.getRange(1, 1, packings_size, 1).clear();
  for (var l = 0; l < packings_size; l++) {
    hoja_packings.getRange(1 + l, 1).setValue(packagings[l]);
  };
}

function getCouriers() {
  var couriers = ['Chilexpress', 'Starken', 'Chileparcels', 'Motopartner', 'Bluexpress', 'Shippify', 'Muvsmart'];
  var couriers_size = couriers.length;
  var hoja_couriers = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Couriers');
  hoja_couriers.getRange(1, 1, couriers_size, 1).clear();
  for (var l = 0; l < couriers_size; l++) {
    hoja_couriers.getRange(1 + l, 1).setValue(couriers[l]);
  }
}

function insertNewFields() {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Pickup');
  if (sheet.getLastColumn() < 16) {
    SpreadsheetApp.getActiveSpreadsheet().toast('Actualizando Planilla a la version 6', 'Actualización en curso');
    sheet.insertColumnsAfter(sheet.getLastColumn(), 5);
    sheet.getRange('Q:U').clearFormat()
    sheet.getRange('Q:U').clearDataValidations();
    sheet.getRange('q1').setValue('¿Asegurar Envío?');
    sheet.getRange('r1').setValue('Contenido del Pedido');
    sheet.getRange('s1').setValue('Número Documento \n BOLETA / FACTURA / GUÍA DESPACHO');
    sheet.getRange('t1').setValue('Valor Declarado');
    sheet.getRange('u1').setValue('¿Seguro Adicional?');
    sheet.getRange('q1:u1').setFontWeight('bold');
    sheet.getRange('q1:u1').setFontSize(10);
    sheet.getRange('q1:u1').setBackground('#00b8de');
    sheet.getRange('q1:u1').setFontColor('#ffffff');
    sheet.getRange('q1:u1').setHorizontalAlignment('center');
  }
}

function getPurchaseDetails() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();

  var setDetails = function () {
    var sheetPurchaseType = ss.getSheetByName('Tipo Productos');
    var details = ['Accesorios de Moda', 'Accesorios y repuestos para autos/motos.', 'Artículos de Deporte',
      'Bolsas, Maletas y Accesorios de Viaje', 'Cámaras, Videocámaras y/o Accesorios',
      'CD, casetes, vinilos y otras grabaciones de sonido', 'Celulares y/o Accesorios',
      'Computadoras personales y/o Accesorios', 'Enganches, suministros científicos y/o de laboratorio',
      'Herramientas y Mejoras del hogar', 'Instrumentos Musicales', 'Insumos de Oficina y Papelería',
      'Juguetes y Juegos', 'Libros y/o Revistas', 'Productos de Bebé', 'Productos de Belleza y Salud',
      'Productos de Hogar y Cocina', 'Productos de Mascotas', 'Relojes', 'Ropa',
      'Software empresarial, de educación, de utilidades, de seguridad y para niños',
      'Televisores, equipos de música y GPS', 'Video, DVD y Blu-ray', 'Videojuegos', 'Zapatos', 'Otros productos de venta online'
    ];
    for (var i = 0; i < details.length; i++) {
      sheetPurchaseType.getRange('A' + (i + 1)).setValue(details[i]);
    }
    sheetPurchaseType.hideSheet();
    var pickup = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Pickup')
    var cellDetail = pickup.getRange('R2:R952');
    var cellSecure = pickup.getRange('Q2:Q952');
    var cellExtra = pickup.getRange('U2:U952');
    var range = ss.getRange("Tipo Productos!A1:A26");
    var ruleDetails = SpreadsheetApp.newDataValidation().requireValueInRange(range, true).build();
    var ruleSecure = SpreadsheetApp.newDataValidation().requireValueInList(['Si', 'No'], true).build();
    cellDetail.setDataValidation(ruleDetails);
    cellSecure.setDataValidation(ruleSecure);
    cellExtra.setDataValidation(ruleSecure);
  }

  try {
    var sheetPurchaseType = ss.getSheetByName('Tipo Productos');
    if (sheetPurchaseType == undefined) {
      ss.insertSheet('Tipo Productos');
      setDetails();
    }
  } catch (e) {
    ss.insertSheet('Tipo Productos');
    setDetails();
  }
}


function getShipping() {
  var shipping = ['Normal', '']
  var hoja_shipping = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Shipping');
  var shipping_size = shipping.length;
  hoja_shipping.getRange(1, 1, shipping_size, 1).clear();
  for (var l = 0; l < shipping_size; l++) {
    hoja_shipping.getRange(1 + l, 1).setValue(shipping[l]);
  };
}

function getCommunes() {
  var planilla_data_client = ss.getSheetByName('Only For Shipit');
  var data_client = planilla_data_client.getRange(2, 1, 1, 3).getValues();
  var key = data_client[0][0];
  var secret_key = data_client[0][1];

  var key = key;
  var version = '2';
  var secret_key = secret_key;
  var hoja_comunas = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Comunas');

  var header = {
    'Accept': 'application/vnd.shipit.v2',
    'X-Shipit-Email': key,
    'X-Shipit-Access-Token': secret_key
  };

  var options_identification = {
    'method': 'get',
    'contentType': "application/json",
    'headers': header
  }

  var URL = UrlFetchApp.fetch('http://api.shipit.cl/v/communes', options_identification);
  var response = JSON.parse(URL.getContentText());

  var communes = response;
  var count_communes = communes.length;

  hoja_comunas.getRange(1, 1, 1000, 3).clear();
  var counter = 0;

  for (var l = 0; l < count_communes; l++) {
    if (communes[l].couriers_availables.starken != null) {
      counter++;
      hoja_comunas.getRange(counter, 1).setValue(communes[l].name);
      hoja_comunas.getRange(counter, 2).setValue('Starken');
    }
    if (communes[l].couriers_availables.chilexpress != null) {
      counter++;
      hoja_comunas.getRange(counter, 1).setValue(communes[l].name);
      hoja_comunas.getRange(counter, 2).setValue('Chilexpress');
    }
    if (communes[l].couriers_availables.correoschile != null) {
      counter++;
      hoja_comunas.getRange(counter, 1).setValue(communes[l].name);
      hoja_comunas.getRange(counter, 2).setValue('CorreosChile');
    }
  }
}

var Shipit = function (is_production, key, secret_key) {
  this.is_production = is_production;
  this.key = key;
  this.protocol = 'https';
  this.domain = 'shipit.cl';
  this.version = '2';
  this.secret_key = secret_key;
  this.base;
  this.method;
  this.uri;

  this.initializer = function () {
    this.setApiBase();
  };

  this.setApiBase = function () {
    this.base = this.setBaseUrl(this.is_production);
  };

  this.setBaseUrl = function (is_production) {
    var subdomain = is_production == true ? subdomain = 'clientes' : 'staging.clientes';
    return this.protocol + '://' + subdomain + '.' + this.domain + '/v/';
  };

  this.createRequest = function (method, uri) {
    var options = { 'method': method };
    var url_request = this.base
  };

  this.options = function () {
    var options = {
      'method': 'post',
      'contentType': 'application/json'
    };
    return options;
  };

  this.optionsPayload = function (payload, method) {
    var options = {
      'method': method,
      'payload': payload,
      'muteHttpExceptions': true,
      'contentType': 'application/json',
      'headers': {
        'Accept': 'application/vnd.shipit.v' + this.version,
        'X-Shipit-Email': key,
        'X-Shipit-Access-Token': secret_key
      }
    };

    return options;
  };

  this.MassData = function () {
    var spread = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Pickup');
    var start_row = spread.getLastRow();
    var num_column = spread.getLastColumn();
    var num_row = start_row - 1;
    var id_list = spread.getSheetValues(2, 1, num_row, num_column);
    var params_attributes = new Array(num_row);

    for (var i = 0; i < num_row; i++) {
      if (id_list[i][16].toLowerCase() == 'si') {
        id_list[i][16] = true
      } else {
        id_list[i][16] = false
      }
      params_attributes[i] = {
        // "commune_id": id_list[i][4],
        'reference': id_list[i][0],
        'full_name': id_list[i][6],
        'email': id_list[i][11],
        'length': 10,
        'width': 10,
        'height': 10,
        'weight': 1,
        'items_count': id_list[i][1],
        'cellphone': id_list[i][12],
        'is_payable': this.validatePacking('Por Pagar', id_list[i][13]),
        // "is_fragile" : this.validatePacking( id_list[i][14],"Empaque"),
        'packing': id_list[i][14],
        'shipping_type': id_list[i][3],
        'destiny': this.validatePacking('Sucursal', id_list[i][15]),
        'courier_for_client': id_list[i][15].toLowerCase(),
        'sku_supplier': id_list[i][2],
        'approx_size': id_list[i][10],
        // 'address_validated_by_client': id_list[i][18],
        // "is_wrapper_paper" : this.validatePacking( id_list[i][14],"Empaque" ),
        'address_attributes': {
          'commune_id': this.cleanedUppercaseString(id_list[i][4]),
          'street': id_list[i][7],
          'number': id_list[i][8],
          'complement': id_list[i][9]
        },
        'with_purchase_insurance': id_list[i][16] && id_list[i][17] && id_list[i][18] && id_list[i][19],
        'insurance_attributes': {
          'extra': id_list[i][16],
          'ticket_amount': id_list[i][17],
          'ticket_number': id_list[i][18],
          'detail': id_list[i][19]
        }
      }
    }
    var data = {
      'packages': params_attributes
    }

    return data;
  };
  this.createMassPackage = function () {
    var URL = this.base + 'packages/mass_create';

    var data = this.MassData();
    var payload = JSON.stringify(data);
    var options = this.optionsPayload(payload, 'post');

    var response = UrlFetchApp.fetch(URL, options);
    var result = JSON.parse(response.getContentText());
    return {
      result: result,
      code: response.getResponseCode()
    }
  };

  this.cleanedUppercaseString = function (cadena) {
    // Caracteres a eliminar
    var specialChars = "!@#$^&%*()+=-[]/{}|:<>?,.";

    // Se eliminan caracteres especiales
    for (var i = 0; i < specialChars.length; i++) {
      cadena = cadena.replace(new RegExp("\\" + specialChars[i], 'gi'), '');
    }
    // Convertimos la cadena en mayúscula
    cadena = cadena.toUpperCase();

    // Remplazamos acentos y "ñ"
    cadena = cadena.replace(/Á/g, "A");
    cadena = cadena.replace(/É/g, "E");
    cadena = cadena.replace(/Í/g, "I");
    cadena = cadena.replace(/Ó/g, "O");
    cadena = cadena.replace(/Ú/g, "U");
    cadena = cadena.replace(/Ñ/g, "N");
    return cadena;
  };

  this.validatePacking = function (attribute, value) {
    var response = null;
    switch (attribute) {
      case 'Por Pagar':
        if (value.toLowerCase() == 'si') {
          response = true;
        } else {
          response = false;
        }
        break;
      case 'Solo Fragil':
        response = true;
        break;
      case 'Fragil y Regalo':
        response = true;
        break;
      case 'Regalo':
        response = true;
        break;
      case 'Sucursal':
        if (value == 'Chilexpress') {
          response = value;
        } else if (value == 'Starken') {
          response = value;
        } else {
          response = 'Domicilio'
        }
        break;
      default:
        response = 'Error';
    }

    return response;
  };

  this.createPackage;
  this.createPickup;
  this.updatePackage;

  this.initializer();
}
