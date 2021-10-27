//Info cliente para recuperar el key y secret_key
var ss = SpreadsheetApp.getActiveSpreadsheet();
var planilla_data_client = ss.getSheetByName("Only For Shipit");
var data_client = planilla_data_client.getRange(2,1,1,3).getValues();
this.key = data_client[0][0];
this.secret_key = data_client[0][1];

function test(){
  set_triggers();
  var shipit = new Shipit(false, key, secret_key);
  var request = shipit.createMassPackage();
};

function send(key,secret_key){
  set_triggers();
  var shipit = new Shipit(true, this.key, this.secret_key)
  var request = shipit.createMassPackage();
};

function other_settings(){

}

function check_production(){
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var planilla_pickup = ss.getSheetByName("Pickup");
  var startRow_pickup = planilla_pickup.getLastRow();
  var number_pickup = startRow_pickup - 1;
  var startColumn_pickup = planilla_pickup.getLastColumn();
  var datos_pickup = planilla_pickup.getRange(2,1,number_pickup,startColumn_pickup);
  var info_pickup = datos_pickup.getValues();
  var message = "";

  for (var i = 0; i < number_pickup ; i++)
  {

    if (info_pickup[i][0] == ""){
      message += "Falta el ID en la linea " + (i+2) + " | ";}
      else {

       if (info_pickup[i][5] == "Domicilio" && info_pickup[i][15] == "Chilexpress" && info_pickup[i][13].toLowerCase() == "si") {
         message += "No puedes realizar envios a domicilio por pagar mediante Chilexpress"}
         else{

           if (info_pickup[i][1] == ""){
             message += "Falta el número de bultos en la linea " + (i+2) + " | ";}
             else{

              if (info_pickup[i][3] == ""){
                message += "Falta el tiempo de envío en la linea " + (i+2) + " | ";}

                else{
                  if (info_pickup[i][3] == "Sábado" && info_pickup[i][15] == "Si" ){
                    message += "No se puede enviar el producto en la linea " + (i+2) + " el por pagar el Sábado | ";}

                    else{

                      if (info_pickup[i][4] == ""){
                        message += "Falta la comuna en la linea " + (i+2) + " | ";}

                        else{

                          if (info_pickup[i][5] == ""){
                            message += "Falta envio a sucursal o domicilio en la linea " + (i+2) + " | ";}

                            else{

                              if (info_pickup[i][6] == ""){
                                message += "Falta el destinatario en la linea " + (i+2) + " | ";}

                                else{

                                  if (info_pickup[i][7] == ""){
                                    message += "Falta la calle en la linea " + (i+2) + " | ";}

                                    else{
                                      planilla_pickup.getRange(2+i,8).clearDataValidations();
                                      if (info_pickup[i][8] == ""){
                                        message += "Falta el número en la dirección en la linea " + (i+2) + " | ";}

                                        else{
                                          planilla_pickup.getRange(2+i,14).clearDataValidations();
                                          if (info_pickup[i][14] == ""){
                                            message += "Debes seleccionar un tipo de empaque en la linea " + (i+2) + " | ";}

                                            else{
                                              planilla_pickup.getRange(2+i,9,1,2).clearDataValidations();
                                              if (info_pickup[i][10] == ""){
                                                message +="Falta el tamaño en la linea " + (i+2) + " | ";}

                                                else{
                                                  if (info_pickup[i][15] == "Chilexpress" && info_pickup[i][5] == "Sucursal Starken-Turbus"){
                                                    message +="Tu courier de preferiencia no coincide con el de la sucursal seleccionada en la linea " + (i+2) + " | ";}

                                                    else{
                                                      if (info_pickup[i][15] == "Starken" && info_pickup[i][5] == "Sucursal Chilexpress"){
                                                        message +="Tu courier de preferiencia no coincide con el de la sucursal seleccionada en la linea " + (i+2) + " | ";}
                                                      else{
                                                        if (info_pickup[i][15] != "") {
                                                          if (info_pickup[i][15].toLowerCase() != "chilexpress" && info_pickup[i][15].toLowerCase() != "starken" && info_pickup[i][15].toLowerCase() != "correoschile") {
                                                            message += "Por favor, ingresar Chilexpress/Starken/CorreosChile como courier o dejar casilla " + (i+2) + " en blanco" + " \\n ";}
                                                        }
                                                        else {
                                                          if (info_pickup[i][0].length > 10) {
                                                            message += "El largo del ID de Pedido no puede superar los 10 caracteres. \\n "
                                                          }
                                                        }
                                                       }
                                                      }
                                                    }
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            }


  if (message == ""){
    datos_pickup.setBackground("white");
    ss.toast("Generando el pickup en la plataforma");
    send();

    Browser.msgBox("Solicitud enviada. En los próximos minutos te enviaremos un correo con la información del Héroe asignado.");
  }
  else{
   Browser.msgBox(message);
  }
}

function check_test(){
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var planilla_pickup = ss.getSheetByName("Pickup");
  var startRow_pickup = planilla_pickup.getLastRow();
  var number_pickup = startRow_pickup - 1;
  var startColumn_pickup = planilla_pickup.getLastColumn();
  var datos_pickup = planilla_pickup.getRange(2,1,number_pickup,startColumn_pickup);
  var info_pickup = datos_pickup.getValues();
  var message = "";

  for (var i = 0; i < number_pickup ; i++)
  {

    if (info_pickup[i][0] == ""){
      message += "Falta el ID en la linea " + (i+2) + " | ";}

    else{

      if (info_pickup[i][1] == ""){
        message += "Falta el número de bultos en la linea " + (i+2) + " | ";}

      else{

        if (info_pickup[i][3] == ""){
          message += "Falta el tiempo de envío en la linea " + (i+2) + " | ";}

        else{
          if (info_pickup[i][3] == "Sábado" && info_pickup[i][15] == "Si" ){
            message += "No se puede enviar el producto en la linea " + (i+2) + " el por pagar el Sábado | ";}

          else{

            if (info_pickup[i][4] == ""){
              message += "Falta la comuna en la linea " + (i+2) + " | ";}

            else{

              if (info_pickup[i][5] == ""){
                message += "Falta envio a sucursal o domicilio en la linea " + (i+2) + " | ";}

              else{

                if (info_pickup[i][6] == ""){
                  message += "Falta el destinatario en la linea " + (i+2) + " | ";}

                else{

                  if (info_pickup[i][7] == ""){
                    message += "Falta la calle en la linea " + (i+2) + " | ";}

                  else{
                    planilla_pickup.getRange(2+i,8).clearDataValidations();
                    if (info_pickup[i][8] == ""){
                      message += "Falta el número en la dirección en la linea " + (i+2) + " | ";}

                    else{
                    planilla_pickup.getRange(2+i,14).clearDataValidations();
                    if (info_pickup[i][14] == ""){
                      message += "Debes seleccionar un tipo de empaque en la linea " + (i+2) + " | ";}

                      else{
                        planilla_pickup.getRange(2+i,9,1,2).clearDataValidations();
                        if (info_pickup[i][10] == ""){
                          message +="Falta el tamaño en la linea " + (i+2) + " | ";}

                        else{
                          if (info_pickup[i][16] == "Chilexpress" && info_pickup[i][5] == "Sucursal Starken-Turbus"){
                            message +="Tu courier de preferiencia no coincida con el de la sucursal seleccionada en la linea " + (i+2) + " | ";}

                          else{
                            if (info_pickup[i][16] == "Starken" && info_pickup[i][5] == "Sucursal Chilexpress"){
                              message +="Tu courier de preferiencia no coincida con el de la sucursal seleccionada en la linea " + (i+2) + " | ";}
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }


  if (message == ""){
    datos_pickup.setBackground("white");
    ss.toast("Generando el pickup en la plataforma");
    test();

    Browser.msgBox("Solicitud enviada. En los próximos minutos te enviaremos un correo con la información del Héroe asignado.");
  }
  else{
   Browser.msgBox(message);
  }
}

function clean_temporary(){
  var planilla_pickup = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Pickup");
  var LastRow_pickup = planilla_pickup.getLastRow();
  var LastColumn_pickup = planilla_pickup.getLastColumn();
  planilla_pickup.getRange(2,1,LastRow_pickup,LastColumn_pickup).clear();
}

function set_triggers(){
  var allTriggers = ScriptApp.getProjectTriggers();
  var ss = SpreadsheetApp.getActive();

  if (allTriggers.length <= 0){
    ScriptApp.newTrigger("clean").timeBased().atHour(01).everyDays(1).create();
    ScriptApp.newTrigger('getSettings').forSpreadsheet(ss).onOpen().create();
  }
}

function menuItems(){

  var options = [
                 ["Enviar correo de solicitud (Acepto Términos y Condiciones)", "enviar"]
                // ["Enviar a staging", "enviar_staging"]
  ]
  Browser.msgBox("Hola! Evita los siguientes errores para poder ingresar una solicitud correctamente: \\n \\n 1.- Pegar incorrectamente el contenido (correctamente con ctrl+shift+v para mantener el formato).\\n 2.- Ingresar comunas con letra minúscula y/o caracteres especiales (correctamente con mayúscula).\\n 3.- No seleccionar un tipo de empaque, dejando el campo en blanco (correctamente cualquier opción).\\n 4.- No puedes enviar a una sucursal con un courier distinto. \\n \\n IMPORTANTE: En caso de no aparecer el botón 'shipit', por favor, recargar la página.");
  return options;

}


function getPacking(){
  var packagings = ["Sin empaque","Caja de Cartón","Film Plástico", "Caja + Burbuja", "Bolsa Courier"]
  var packings_size = packagings.length;
  var hoja_packings = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Packings");

  hoja_packings.getRange(1, 1, packings_size, 1).clear();

  for(var l = 0;l<packings_size;l++){
          hoja_packings.getRange(1+l,1).setValue(packagings[l]);
  };
}


function getCouriers(){
  var couriers = ["Chilexpress","Starken"]
  var couriers_size = couriers.length;
  var hoja_couriers = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Couriers");

  hoja_couriers.getRange(1, 1, couriers_size, 1).clear();

  for(var l = 0;l<couriers_size;l++){
          hoja_couriers.getRange(1+l,1).setValue(couriers[l]);
  };
}

function getShipping(){
  var shipping = ["Normal",""]
  var hoja_shipping = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Shipping");

  var shipping_size = shipping.length;

  hoja_shipping.getRange(1,1,shipping_size,1).clear();

  for(var l = 0;l<shipping_size;l++){
      hoja_shipping.getRange(1+l,1).setValue(shipping[l]);
  };
}


function getCommunes(){
  var planilla_data_client = ss.getSheetByName("Only For Shipit");
  var data_client = planilla_data_client.getRange(2,1,1,3).getValues();
  var key = data_client[0][0];
  var secret_key = data_client[0][1];

  var key = key;
  var version = "2";
  var secret_key = secret_key;
  var hoja_comunas = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Comunas");

  var header = {
    "Accept": "application/vnd.shipit.v2",
    "X-Shipit-Email": key,
    "X-Shipit-Access-Token": secret_key
  };

  var options_identification = {
    "method" : "get",
    "contentType" : "application/json",
    "headers": header
  }

  var URL = UrlFetchApp.fetch("http://api.shipit.cl/v/communes", options_identification);
  var response = JSON.parse(URL.getContentText());

  var communes = response;
  var count_communes = communes.length;

  hoja_comunas.getRange(1, 1, 1000, 3).clear();
  var counter = 0;

  for(var l = 0;l<count_communes;l++){
    if(communes[l].couriers_availables.starken != null){
      counter++;
      hoja_comunas.getRange(counter,1).setValue(communes[l].name);
      hoja_comunas.getRange(counter,2).setValue("Starken");
    }
    if(communes[l].couriers_availables.chilexpress != null){
      counter++;
      hoja_comunas.getRange(counter,1).setValue(communes[l].name);
      hoja_comunas.getRange(counter,2).setValue("Chilexpress");
    }
    if(communes[l].couriers_availables.correoschile != null){
      counter++;
      hoja_comunas.getRange(counter,1).setValue(communes[l].name);
      hoja_comunas.getRange(counter,2).setValue("CorreosChile");
    }
  }
}

function SmartDataValidation(event) {
//  var TargetSheet = 'Pickup' // name of the sheet where you want to verify the data
//  var LogSheet = 'Comunas' // name of the sheet with information
//  var NumOfLevels = 2 // number of associated drop-down list levels
//  var lcol = 5; // number of the leftmost column, in which the changes are checked; A = 1, B = 2, etc.
//  var lrow = 2; //

//  var ts = event.source.getActiveSheet();
//  var sname = ts.getName();
//
//  if (sname == TargetSheet)
//  {
//
//    var ss = SpreadsheetApp.getActiveSpreadsheet();
//
//    var ls = ss.getSheetByName(LogSheet); // data sheet
//    //

//    var br = event.source.getActiveRange();
//    var scol = br.getColumn();
//    var srow = br.getRow()
//    if (scol >= lcol)
//    {
//      if (srow >= lrow)
//      {
//        var CurrentLevel = scol-lcol+2;//

//        var ColNum = br.getLastColumn() - scol + 1;
//        CurrentLevel = CurrentLevel + ColNum - 1;
//
//        if (ColNum > 1)
//        {
//          br = br.offset(0,ColNum-1);
//        }
//
//        var HeadLevel = CurrentLevel - 1;
//
//        var RowNum = br.getLastRow() - srow + 1;
//
//        var X = NumOfLevels - CurrentLevel + 1;//

//        //

//        if (CurrentLevel <= NumOfLevels )
//        {
//          var KudaCol = NumOfLevels + 2
//          var KudaNado = ls.getRange(1, KudaCol);
//          var lastRow = ls.getLastRow();
//          var ChtoNado = ls.getRange(1, KudaCol, lastRow, KudaCol);//

//          for (var j = 1; j <= RowNum; j++)
//          {
//            for (var k = 1; k <= X; k++)
//            {
//
//              HeadLevel = HeadLevel + k - 1;
//              CurrentLevel = CurrentLevel + k - 1;
//
//              var r = br.getCell(j,1).offset(0,k-1,1);
//              var SearchText = r.getValue(); //

//              if (SearchText != '')
//              {
//                //

//                var IndCodePart = 'INDIRECT("R1C' + HeadLevel + ':R' + lastRow + 'C';
//                IndCodePart = IndCodePart + HeadLevel + '",0)';
//                // the formula
//                var code = '=UNIQUE(INDIRECT("R" & MATCH("';
//                code = code + SearchText + '",';
//                code = code + IndCodePart;
//                code = code + ',0) & "C" & "' + CurrentLevel
//                code = code + '" & ":" & "R" & COUNTIF(';
//                code = code + IndCodePart;
//                code = code + ',"' + SearchText + '") + MATCH("';
//                code = code + SearchText + '";';
//                code = code + IndCodePart;
//                code = code + ',0) - 1';
//                code = code + '& "C" & "' ;
//                code = code + CurrentLevel + '",0))';
//
//                KudaNado.setFormulaR1C1(code);
//                var values = [];
//                for (var i = 1; i <= lastRow; i++)
//                {
//                  var currentValue = ChtoNado.getCell(i,1).getValue();
//                  if (currentValue != '')
//                  {
//                    values.push(currentValue);
//                  }
//                  else
//                  {
//                    var Variants = i-1;
//                    i = lastRow;
//                  }
//                }
//
//                var cell = r.offset(0,11);
//                var rule = SpreadsheetApp
//                .newDataValidation()
//                .requireValueInList(values, true)
//                .setAllowInvalid(false)
//                .build();
//                cell.setDataValidation(rule);
//                if (Variants == 1)
//                {
//                  cell.setValue(KudaNado.getValue());
//                }
//                else
//                {
//                  k = X+1;
//                }
//
//
//              }
//              else
//              {
//                if (CurrentLevel <= NumOfLevels )
//                {
//                  for (var i = 1; i <= NumOfLevels; i++)
//                  {
//                    var cell = r.offset(0,i);
//                    cell.clear({contentsOnly: true});
//                    cell.clear({validationsOnly: true});
//                  }
//                }
//              }
//            }
//          }
//
//        }
//
//      }
//    }
//  }
}

var Shipit = function(is_production, key, secret_key){
  this.is_production = is_production;
  this.key = key;
  this.protocol = "http";
  this.domain = "shipit.cl";
  this.version = "2";
  this.secret_key = secret_key;
  this.base;
  this.method;
  this.uri;

  this.initializer = function(){
    this.setApiBase();
  };

  this.setApiBase = function(){
    this.base = this.setBaseUrl(this.is_production);
  };

  this.setBaseUrl = function(is_production){
    var subdomain = "";
    if(is_production==true){
      subdomain = "clientes";
    }else{
      subdomain = "staging";
    };
    return this.protocol+"://"+subdomain+"."+this.domain+"/v/";
  };

  this.createRequest = function(method,uri){
    var options = {"method": method};
    var url_request = this.base
  };

  this.options = function(){
    var options = {
      "method" : "post",
      "contentType": "application/json"
    };

    return options;
  };

  this.optionsPayload = function(payload, method){

  var options = {
    "method" : method,
    "payload" : payload,
    "contentType": "application/json",
    "headers": {
      "Accept": "application/vnd.shipit.v"+this.version,
      "X-Shipit-Email": key,
      "X-Shipit-Access-Token": secret_key
    }
  };

    return options;
  };

  this.MassData = function(){
    var spread = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Pickup");
    var start_row = spread.getLastRow();
    var num_column = spread.getLastColumn();
    var num_row = start_row - 1;
    var id_list = spread.getSheetValues(2,1,num_row,num_column);
    var params_attributes = new Array(num_row);

    for(var i=0; i < num_row; i++){
      params_attributes[i] = {
         //"commune_id": id_list[i][4],
         "reference":id_list[i][0],
         "full_name": id_list[i][6],
         "email": id_list[i][11],
         "length": 10,
         "width": 10,
         "height": 10,
         "weight": 1,
         "items_count": id_list[i][1],
         "cellphone" : id_list[i][12],
         "is_payable" : this.validatePacking("Por Pagar", id_list[i][13]),
//        "is_fragile" : this.validatePacking( id_list[i][14],"Empaque"),
         "packing" : id_list[i][14],
         "shipping_type" : id_list[i][3],
         "destiny" : this.validatePacking("Sucursal", id_list[i][5]),
         "courier_for_client": id_list[i][15].toLowerCase(),
         "sku_supplier": id_list[i][2],
         "approx_size": id_list[i][10],
//         "address_validated_by_client": id_list[i][18],
//         "is_wrapper_paper" : this.validatePacking( id_list[i][14],"Empaque" ),
         "address_attributes": {
           "commune_id": this.cleanedUppercaseString(id_list[i][4]),
           "street": id_list[i][7],
           "number": id_list[i][8],
           "complement": id_list[i][9]
        }
      }
    }

    var data = {
      "packages": params_attributes
    }

    return data;
  };

  this.createMassPackage = function(){
    var URL = this.base + "packages/mass_create";
    //Esto lo obtiene bien
    var data = this.MassData();
    var payload = JSON.stringify(data);
    var options = this.optionsPayload(payload, "post");

    var response = UrlFetchApp.fetch(URL, options);
    var result = JSON.parse(response.getContentText());
  };

    this.cleanedUppercaseString = function(cadena){
		// Caracteres a eliminar
		var specialChars = "!@#$^&%*()+=-[]/{}|:<>?,.";

  		// Se eliminan caracteres especiales
   		for (var i = 0; i < specialChars.length; i++) {
   		cadena = cadena.replace(new RegExp("\\" + specialChars[i], 'gi'), '');
  		 }
   		// Convertimos la cadena en mayúscula
  		cadena = cadena.toUpperCase();

  		// Remplazamos acentos y "ñ"
   		cadena = cadena.replace(/Á/g,"A");
  	    cadena = cadena.replace(/É/g,"E");
  		cadena = cadena.replace(/Í/g,"I");
  		cadena = cadena.replace(/Ó/g,"O");
  		cadena = cadena.replace(/Ú/g,"U");
  	    cadena = cadena.replace(/Ñ/g,"N");
        return cadena;
	};

    this.validatePacking = function(attribute, value){
    var response = null;
    switch (attribute){
      case 'Por Pagar':
        if(value == "Si"|| value == "si"|| value == "sI" || value == "SI"){
          response = true;
        }else{
          response = false;
        };
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
        if(value == "Sucursal Chilexpress"){
          response = "Chilexpress";
        }else if(value=="Sucursal Starken-Turbus"){
          response = "Starken-Turbus";
        }else{
          response = "Domicilio"
        };
        break;
      default:
        response = "Error";
    }

    return response;
  };

  this.createPackage;
  this.createPickup;
  this.updatePackage;

  this.initializer();
}
