var jsTag = angular.module('jsTag');

// TODO: Maybe add A to 'restrict: E' for support in IE 8?
jsTag.directive('jsTag', ['$templateCache', function($templateCache) {
  return {
    restrict: 'E',
    scope: true,
    controller: 'JSTagMainCtrl',
    templateUrl: function($element, $attrs) {
      var mode = $attrs.jsTagMode || "default";
      return 'jsTag/source/templates/' + mode + '/js-tag.html';
    }
  };
}]);

// TODO: Replace this custom directive by a supported angular-js directive for blur
jsTag.directive('ngBlur', ['$parse', function($parse) {
    return {
        restrict: 'A',
        link: function(scope, elem, attrs) {
          // this next line will convert the string
          // function name into an actual function
          var functionToCall = $parse(attrs.ngBlur);
          elem.bind('blur', function(event) {

            // on the blur event, call my function
            scope.$apply(function() {
              functionToCall(scope, {$event:event});
            });
          });
        }
    };
}]);


// Notice that focus me also sets the value to false when blur is called
// TODO: Replace this custom directive by a supported angular-js directive for focus
// http://stackoverflow.com/questions/14833326/how-to-set-focus-in-angularjs
jsTag.directive('focusMe', ['$parse', '$timeout', function($parse, $timeout) {
  return {
    restrict: 'A',
    link: function(scope, element, attrs) {
      var model = $parse(attrs.focusMe);
      scope.$watch(model, function(value) {
        if (value === true) {
          $timeout(function() {
            element[0].focus();
          });
        }
      });

      // to address @blesh's comment, set attribute value to 'false'
      // on blur event:
      element.bind('blur', function() {
        scope.$apply(model.assign(scope, false));
      });
    }
  };
}]);

// focusOnce is used to focus an element once when first appearing
// Not like focusMe that binds to an input boolean and keeps focusing by it
jsTag.directive('focusOnce', ['$timeout', function($timeout) {
  return {
    restrict: 'A',
    link: function(scope, element, attrs) {
      $timeout(function() {
        element[0].select();
      });
    }
  };
}]);

// auto-grow directive by the "shadow" tag concept
jsTag.directive('autoGrow', ['$timeout', function($timeout) {
  return {
    link: function(scope, element, attr){
      var paddingLeft = element.css('paddingLeft'),
          paddingRight = element.css('paddingRight');

      var minWidth = 60;

      var $shadow = angular.element('<span></span>').css({
        'position': 'absolute',
        'top': '-10000px',
        'left': '-10000px',
        'fontSize': element.css('fontSize'),
        'fontFamily': element.css('fontFamily'),
        'white-space': 'pre'
      });
      element.after($shadow);

      var update = function() {
        var val = element.val()
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')
          .replace(/&/g, '&amp;')
        ;

        // If empty calculate by placeholder
        if (val !== "") {
          $shadow.html(val);
        } else {
          $shadow.html(element[0].placeholder);
        }

        var newWidth = ($shadow[0].offsetWidth + 10) + "px";
        element.css('width', newWidth);
      };

      var ngModel = element.attr('ng-model');
      if (ngModel) {
        scope.$watch(ngModel, update);
      } else {
        element.bind('keyup keydown', update);
      }

      // Update on the first link
      // $timeout is needed because the value of element is updated only after the $digest cycle
      // TODO: Maybe on compile time if we call update we won't need $timeout
      $timeout(update);
    }
  };
}]);

// Small directive for twitter's typeahead
jsTag.directive('jsTagTypeahead', function () {
  return {
    restrict: 'A', // Only apply on an attribute or class
    require: '?ngModel',  // The two-way data bound value that is returned by the directive
    link: function (scope, element, attrs, ngModel) {

      element.bind('jsTag:breakcodeHit', function(event) {

        /* Do not clear typeahead input if typeahead option 'editable' is set to false
         * so custom tags are not allowed and breakcode hit shouldn't trigger any change. */
        if (scope.$eval(attrs.options).editable === false) {
          return;
        }

        // Tell typeahead to remove the value (after it was also removed in input)
        $(event.currentTarget).typeahead('val', '');
      });

    }
  };
});
