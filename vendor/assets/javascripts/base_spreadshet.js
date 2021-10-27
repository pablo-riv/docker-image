function onOpen() {
  makemenu();
}

function create_shipments() {
  Shipit.check_production();
}

function staging_create_shipments() {
  Shipit.check_production(false);
}

function makemenu() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();  
  var sui = SpreadsheetApp.getUi();
  var items = Shipit.menuItems();
  var items_size = items.length;
  var menu = sui.createMenu("Shipit");
  for (var i = 0; i<items_size;i++){
    menu.addItem(items[i][0], items[i][1]);
  }

  menu.addToUi();
  return;
}

function getSettings() {
  Shipit.getPurchaseDetails();
  Shipit.getShipping();
  Shipit.getCouriers();
  Shipit.getCommunes();
}

function updateFields() {
  Shipit.insertNewFields();
}

function clean() {
  Shipit.clean_temporary();
}

function onEdit(event) {
  Shipit.SmartDataValidation(event);
}
