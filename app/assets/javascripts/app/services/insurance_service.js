(function() {
  this.app.service('InsuranceService', ['$q', function($q) {
    var CXP_MIN_INSURANCE = 100000;
    var CXP_MAX_INSURANCE = 100000;
    var CXP_EXTRA_INSURANCE = 1000000;
    var CXP_INSURANCE_PERCENT = 0.01;

    var STK_MIN_INSURANCE = 100000;
    var STK_MAX_INSURANCE = 500000;
    var STK_EXTRA_INSURANCE = 1000000;
    var STK_INSURANCE_PERCENT = 0.01;

    var CC_MIN_INSURANCE = 50000;
    var CC_MAX_INSURANCE = 500000;
    var CC_EXTRA_INSURANCE = 1000000;
    var CC_INSURANCE_PERCENT = 0.03;

    var OTHER_MIN_INSURANCE = 50000;
    var OTHER_MAX_INSURANCE = 100000;
    var OTHER_EXTRA_INSURANCE = 1000000;
    var OTHER_INSURANCE_PERCENT = 0.01;

    return {
      new: function(object) {
        var min = 0, max = 0, extra = 0, percent = 0, price = 0, maxSecure = 0;
        var extraInsurance = object.purchase.extra_insurance == '' ? false : object.purchase.extra_insurance;
        try {
          switch (object.courier_for_client.toLowerCase()) {
            case 'chilexpress':
              min = CXP_MIN_INSURANCE,
              max = CXP_MAX_INSURANCE,
              extra = CXP_EXTRA_INSURANCE,
              percent = CXP_INSURANCE_PERCENT;
              break;
            case 'starken':
              min = STK_MIN_INSURANCE,
              max = STK_MAX_INSURANCE,
              extra = STK_EXTRA_INSURANCE,
              percent = STK_INSURANCE_PERCENT;
              break;
            case 'correoschile':
              min = CC_MIN_INSURANCE,
              max = CC_MAX_INSURANCE,
              extra = CC_EXTRA_INSURANCE,
              percent = CC_INSURANCE_PERCENT;
              break;
            default:
              throw 'without courier'
              break;
          }          
        } catch (error) {
          min = OTHER_MIN_INSURANCE, 
          max = OTHER_MAX_INSURANCE,
          extra = OTHER_EXTRA_INSURANCE,
          percent = OTHER_INSURANCE_PERCENT;
        }
        var data = {
          insurance: this.active(object.with_purchase_insurance, object.purchase),
          min: min,
          max: max,
          extra: extra,
          extraInsurance: extraInsurance,
          percent: percent
        }
        price = this.price(data, object.purchase);
        maxSecure = this.maxSecure(data, object.courier_for_client, object.purchase);
        return angular.extend(price, maxSecure);
      },

      price: function(data, purchase) {
        var amount = data.insurance ? data.max : data.min;
        var price = 0;
        if (data.insurance && data.extraInsurance && parseInt(purchase.amount) > amount) {
          price = parseInt(purchase.amount) >= data.extra ? (data.extra * data.percent) : (parseInt(purchase.amount) * data.percent)
          amount = parseInt(purchase.amount) >= data.extra ? data.extra : parseInt(purchase.amount);
        } else if (data.insurance) {
          amount = parseInt(purchase.amount) >= data.max ? data.max : parseInt(purchase.amount);
        } else {
          amount = data.min;
        }
        return { price: price, amount: amount };
      },

      maxSecure: function(data, courier, purchase) {
        var value = 0;
        if (this.valid(purchase) && purchase.extra_insurance) {
          value = data.extra;
        } else if (this.valid(purchase)) {
          value = data.max;
        } else if (!this.valid(purchase) && courier == 'CorreosChile') {
          value = 0;
        } else if (!this.valid(purchase) && courier == '' || courier == undefined) {
          value = data.min;
        } else if (!this.valid(purchase) && courier == 'Starken' || courier == 'Chilexpress') {
          value = data.max;
        } else {
          value = data.min;
        }
        return { maxSecure: (value >= (parseInt(purchase.amount) || value) ? (parseInt(purchase.amount) || value) : value) };
      }, 
      
      active: function (withPurchaseInsurance, purchase) {
        var valid = false;
        if (withPurchaseInsurance) {
          valid = true;
        }

        if (purchase.ticket_number == '' || purchase.detail == '' || purchase.amount == '') {
          return false;
        }
        return valid;
      },

      valid: function (purchase) {
        if (purchase.ticket_number == '' || purchase.detail == '' || purchase.amount == '') {
          return false;
        } else {
          return true;
        }
      }
      
    };
  }]);
}).call(this);