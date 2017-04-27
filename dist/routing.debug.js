(function(_this) {
  return (function() {
    var _s$m;
    _s$m = function(m, c, l, _s$m) {
      _s$m = function(r) {
        if (l[r]) {
          return c[r];
        } else {
          return (l[r]=1,c[r]={},c[r]=m[r](c[r]));
        }
      };
      m[1] = function(exports) {
        var module = {exports:exports};
        var FALLBACK_ROUTE, Route, Router, helpers;
        Route = _s$m(4);
        helpers = _s$m(2);
        FALLBACK_ROUTE = '*FALLBACK*';
        module.exports = Router = function(timeout1) {
          this.timeout = timeout1;
          if (isNaN(this.timeout)) {
            this.timeout = 2500;
          }
          this.listening = false;
          this.routes = [];
          this._specialRoutes = {};
          this._routesMap = {};
          this._cache = {};
          this._history = [];
          this._future = [];
          this._globalBefore = this._globalAfter = helpers.noop;
          this.current = {
            route: null,
            path: null
          };
          this.prev = {
            route: null,
            path: null
          };
          this._pendingRoute = Promise.resolve();
          return this;
        };
        Router.prototype._matchPath = function(path, firstTime) {
          var dynamicSegment, index, j, k, len, len1, matchingRoute, matchingSoFar, ref, route, segment, segments, segmentsStrigified;
          path = helpers.cleanPath(path);
          segments = helpers.parsePath(path);
          segmentsStrigified = segments.join('/');
          matchingRoute = this._routesMap[segmentsStrigified] || this._cache[segmentsStrigified];
          if (!matchingRoute) {
            ref = this.routes;
            for (j = 0, len = ref.length; j < len; j++) {
              route = ref[j];
              matchingSoFar = true;
              for (index = k = 0, len1 = segments.length; k < len1; index = ++k) {
                segment = segments[index];
                if (segment !== route.segments[index]) {
                  dynamicSegment = route.segments.dynamic[index];
                  if (matchingSoFar = dynamicSegment != null) {
                    if (route._dynamicFilters[dynamicSegment]) {
                      matchingSoFar = route._dynamicFilters[dynamicSegment](segment);
                    }
                  }
                }
                if (!matchingSoFar) {
                  break;
                }
              }
              if (matchingSoFar) {
                matchingRoute = route;
                break;
              }
            }
          }
          if (matchingRoute) {
            this._cache[segmentsStrigified] = matchingRoute;
            matchingRoute.path = path;
          } else if (firstTime && this._specialRoutes.rootPath) {
            matchingRoute = this._matchPath(this._specialRoutes.rootPath);
          }
          return matchingRoute || this._specialRoutes.fallback;
        };
        Router.prototype._addRoute = function(route) {
          this.routes.push(route);
          this.routes.sort(function(a, b) {
            var segmentsDiff;
            segmentsDiff = b.segments.length - a.segments.length;
            if (!segmentsDiff) {
              segmentsDiff = b.segments.dynamic.length - a.segments.dynamic.length;
            }
            return segmentsDiff;
          });
          return route;
        };
        Router.prototype.listen = function() {
          this.listening = true;
          Routing._onChange(this._listenCallback = (function(_this) {
            return function(firstTime) {
              return _this.go(window.location.hash, false, firstTime);
            };
          })(this));
          return this;
        };
        Router.prototype.refresh = function() {
          this.prev.path = this.current.path;
          this.prev.route = this.current.route;
          return this.go(this.current.path, true);
        };
        Router.prototype.go = function(path, forceRefresh, firstTime, navDirection) {
          var matchingRoute;
          if (typeof path !== 'string') {
            return this._pendingRoute;
          } else {
            matchingRoute = this._matchPath(path, firstTime);
            path = (matchingRoute != null ? matchingRoute.path : void 0) || path;
            if (matchingRoute && (path !== this.current.path || forceRefresh)) {
              return (function(_this) {
                return function() {
                  if (!(forceRefresh || path === _this.current.path || path === FALLBACK_ROUTE)) {
                    window.location.hash = path;
                    if (_this.current.path && navDirection !== 'back') {
                      _this._history.push(_this.current.path);
                    }
                    if (!navDirection) {
                      _this._future.length = 0;
                    }
                    _this.prev.route = _this.current.route;
                    _this.prev.path = _this.current.path;
                    _this.current.route = matchingRoute;
                    _this.current.path = path;
                  }
                  _this._pendingRoute = _this._pendingRoute.then(function() {
                    return new Promise(function(resolve, reject) {
                      _this._pendingPath = path;
                      setTimeout(function() {
                        return reject(new Error("Timeout Error - " + path));
                      }, _this.timeout);
                      return Promise.resolve().then(_this._globalBefore).then(function() {
                        var ref;
                        return (ref = _this.prev.route) != null ? ref._leave(_this.current.route, _this.current.path) : void 0;
                      }).then(function() {
                        return matchingRoute._run(path, _this.prev.route, _this.prev.path);
                      }).then(_this._globalAfter).then(resolve);
                    });
                  });
                  return _this._pendingRoute["catch"](function(err) {
                    helpers.logError(err);
                    _this._pendingRoute = Promise.resolve();
                    return _this.go(_this.prev.path);
                  });
                };
              })(this)();
            }
          }
        };
        Router.prototype.map = function(path) {
          var matchingRoute, segments, segmentsStrigified;
          path = helpers.cleanPath(path);
          segments = helpers.parsePath(path);
          segmentsStrigified = segments.join('/');
          matchingRoute = this._routesMap[segmentsStrigified];
          if (!matchingRoute) {
            matchingRoute = this._routesMap[segmentsStrigified] = new Route(path, segments);
          }
          return this._addRoute(matchingRoute);
        };
        Router.prototype.beforeAll = function(fn) {
          this._globalBefore = fn;
          return this;
        };
        Router.prototype.afterAll = function(fn) {
          this._globalAfter = fn;
          return this;
        };
        Router.prototype.root = function(path) {
          this._specialRoutes.rootPath = helpers.cleanPath(path);
          return this;
        };
        Router.prototype.fallback = function(fn) {
          this._specialRoutes.fallback = new Route(FALLBACK_ROUTE, []);
          this._specialRoutes.fallback.to(fn);
          return this;
        };
        Router.prototype.back = function() {
          if (this.current.path) {
            this._future.unshift(this.current.path);
          }
          return this.go(this._history.pop(), false, false, 'back');
        };
        Router.prototype.forward = function() {
          return this.go(this._future.shift(), false, false, 'forward');
        };
        Router.prototype.kill = function() {
          this._routesMap = {};
          this._specialRoutes = {};
          this._cache = {};
          this.routes.length = this._history.length = this._future.length = 0;
          this._globalBefore = this._globalAfter = helpers.noop;
          this.current.route = this.current.path = this.prev.route = this.prev.path = null;
        };
        return module.exports;
      };
      m[2] = function(exports) {
        var module = {exports:exports};
        var helpers;
        module.exports = helpers = {};
        helpers.noop = function() {
          return Promise.resolve();
        };
        helpers.removeItem = function(target, item) {
          var itemIndex;
          itemIndex = target.indexOf(item);
          if (itemIndex !== -1) {
            target.splice(itemIndex, 1);
          }
          return target;
        };

        /* istanbul ignore next */
        helpers.logError = function(err) {
          if (!(err instanceof Error)) {
            err = new Error(err);
          }
          if ((typeof console !== "undefined" && console !== null ? console.error : void 0) != null) {
            console.error(err);
          } else if ((typeof console !== "undefined" && console !== null ? console.log : void 0) != null) {
            console.log(err);
          }
        };
        helpers.cleanPath = function(path) {
          if (path[0] === '#') {
            path = path.slice(1);
          }
          if (path.length > 1) {
            if (path[0] === '/') {
              path = path.slice(1);
            }
            if (path[path.length - 1] === '/') {
              path = path.slice(0, -1);
            }
          }
          return path;
        };
        helpers.parsePath = function(path) {
          var addSegment, char, currentSegment, dynamic, i, length, segments;
          dynamic = false;
          currentSegment = '';
          segments = [];
          segments.dynamic = {};
          length = path.length;
          i = -1;
          addSegment = function() {
            segments.push(currentSegment);
            if (dynamic) {
              segments.dynamic[segments.length - 1] = currentSegment;
            }
            if (dynamic) {
              segments.hasDynamic = true;
            }
            currentSegment = '';
            return dynamic = false;
          };
          while (++i !== length) {
            switch (char = path[i]) {
              case '/':
                addSegment();
                break;
              case ':':
                dynamic = true;
                break;
              default:
                currentSegment += char;
            }
          }
          addSegment();
          return segments;
        };
        return module.exports;
      };
      m[4] = function(exports) {
        var module = {exports:exports};
        var Route, helpers;
        helpers = _s$m(2);
        module.exports = Route = function(path1, segments1) {
          this.path = path1;
          this.segments = segments1;
          this.originalPath = this.path;
          this.action = this.enterAction = this.leaveAction = helpers.noop;
          this.context = {
            path: this.path,
            segments: this.segments,
            params: {}
          };
          this._dynamicFilters = {};
          return this;
        };
        Route.prototype.entering = function(fn) {
          this.enterAction = fn;
          return this;
        };
        Route.prototype.leaving = function(fn) {
          this.leaveAction = fn;
          return this;
        };
        Route.prototype.to = function(fn) {
          this.action = fn;
          return this;
        };
        Route.prototype.filters = function(filters) {
          this._dynamicFilters = filters;
          return this;
        };
        Route.prototype._run = function(path, prevRoute, prevPath) {
          this._resolveParams(path);
          return Promise.resolve(this.enterAction.call(this.context, prevPath, prevRoute)).then((function(_this) {
            return function() {
              return _this.action.call(_this.context, prevPath, prevRoute);
            };
          })(this));
        };
        Route.prototype._leave = function(newRoute, newPath) {
          return this.leaveAction.call(this.context, newPath, newRoute);
        };
        Route.prototype._resolveParams = function(path) {
          var dynamicIndex, dynamicSegment, ref, segments;
          if (this.segments.hasDynamic) {
            segments = path.split('/');
            ref = this.segments.dynamic;
            for (dynamicIndex in ref) {
              dynamicSegment = ref[dynamicIndex];
              this.context.params[dynamicSegment] = segments[dynamicIndex] || '';
            }
          }
        };
        return module.exports;
      };
      return _s$m;
    };
    _s$m = _s$m({}, {}, {});
    return (function() {
      var Router, Routing, helpers;
      Router = _s$m(1);
      helpers = _s$m(2);
      Routing = new function() {
        var changeCallbacks, dispatchChange, listening, routers;
        changeCallbacks = [];
        routers = [];
        listening = false;
        dispatchChange = function(firstTime) {
          var callback, j, len;
          for (j = 0, len = changeCallbacks.length; j < len; j++) {
            callback = changeCallbacks[j];
            callback(firstTime === true);
          }
        };
        this._onChange = function(callback) {
          changeCallbacks.push(callback);
          if (listening) {
            return callback(true);
          } else {
            listening = true;

            /* istanbul ignore next */
            if (window.onhashchange !== void 0 && (!document.documentMode || document.documentMode >= 8)) {
              window.addEventListener('hashchange', dispatchChange);
            } else {
              setInterval(dispatchChange, 100);
            }
            return dispatchChange(true);
          }
        };
        this.killAll = function() {
          var j, len, router, routersToKill;
          routersToKill = routers.slice();
          for (j = 0, len = routersToKill.length; j < len; j++) {
            router = routersToKill[j];
            router.kill();
            helpers.removeItem(routers, router);
            helpers.removeItem(changeCallbacks, router._listenCallback);
          }
        };
        this.Router = function(timeout) {
          var routerInstance;
          routers.push(routerInstance = new Router(timeout));
          return routerInstance;
        };
        this.version = '1.0.3';
        return this;
      };

      /* istanbul ignore next */
      if ((typeof module !== "undefined" && module !== null ? module.exports : void 0) != null) {
        return module.exports = Routing;
      } else if (typeof define === 'function' && define.amd) {
        return define(['routing.js'], function() {
          return Routing;
        });
      } else {
        return this.Routing = Routing;
      }
    })();
  });
})(this)();
