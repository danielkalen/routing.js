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
        module.exports = Router = (function() {
          function Router(timeout1, ID) {
            this.timeout = timeout1;
            this.ID = ID;
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
          }

          Router.prototype._applyBase = function(path) {
            if (path[0] === '/') {
              path = path.slice(1);
            }
            if (this._specialRoutes.basePath) {
              if (path.indexOf(this._specialRoutes.basePath) !== 0) {
                return this._specialRoutes.basePath + "/" + path;
              }
            }
            return path;
          };

          Router.prototype._removeBase = function(path) {
            if (path[0] === '/') {
              path = path.slice(1);
            }
            if (this._specialRoutes.basePath) {
              if (path.indexOf(this._specialRoutes.basePath) === 0) {
                return path.slice(this._specialRoutes.basePath.length + 1);
              }
            }
            return path;
          };

          Router.prototype._matchPath = function(path, firstTime) {
            var dynamicSegment, index, j, k, len, len1, matchingRoute, matchingSoFar, ref, route, segment, segments, segmentsStrigified;
            if (path === FALLBACK_ROUTE) {
              return this._specialRoutes.fallback;
            }
            path = helpers.cleanPath(path);
            segments = helpers.parsePath(path, this._specialRoutes.basePath);
            segmentsStrigified = segments.join('/');
            matchingRoute = this._routesMap[segmentsStrigified] || this._cache[segmentsStrigified];
            if (this._specialRoutes.basePath && path.indexOf(this._specialRoutes.basePath) !== 0) {
              return;
            }
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

          Router.prototype._removeRoute = function(route) {
            var cacheKeys, mapKeys, matchingCacheKey, matchingMapKey, routeIndex;
            if (route) {
              cacheKeys = Object.keys(this._cache);
              mapKeys = Object.keys(this._routesMap);
              routeIndex = this.routes.indexOf(route);
              if (routeIndex !== -1) {
                this.routes.splice(routeIndex, 1);
              }
              matchingCacheKey = cacheKeys.filter((function(_this) {
                return function(key) {
                  return _this._cache[key] === route;
                };
              })(this))[0];
              matchingMapKey = cacheKeys.filter((function(_this) {
                return function(key) {
                  return _this._routesMap[key] === route;
                };
              })(this))[0];
              delete this._cache[matchingCacheKey];
              return delete this._routesMap[matchingMapKey];
            }
          };

          Router.prototype.listen = function() {
            this.listening = true;
            Routing._onChange(this, this._listenCallback = (function(_this) {
              return function(firstTime) {
                return _this.go(window.location.hash, false, firstTime, null, true);
              };
            })(this));
            return this;
          };

          Router.prototype.refresh = function() {
            this.prev.path = this.current.path;
            this.prev.route = this.current.route;
            return this.go(this.current.path, true);
          };

          Router.prototype.go = function(path, forceRefresh, firstTime, navDirection, fromHashChange) {
            var matchingRoute;
            if (typeof path !== 'string') {
              return this._pendingRoute;
            } else {
              if (!fromHashChange) {
                path = this._applyBase(path);
              }
              matchingRoute = this._matchPath(path, firstTime);
              path = (matchingRoute != null ? matchingRoute.path : void 0) || path;
              if (matchingRoute && (path !== this.current.path || forceRefresh)) {
                (function(_this) {
                  return (function() {
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
                          return reject(new Error("TimeoutError: '" + path + "' failed to load within " + _this.timeout + "ms (Router #" + _this.ID + ")"));
                        }, _this.timeout);
                        return Promise.resolve().then(_this._globalBefore).then(function() {
                          var ref;
                          return (ref = _this.prev.route) != null ? ref._leave(_this.current.route, _this.current.path) : void 0;
                        }).then(function() {
                          return matchingRoute._run(path, _this.prev.route, _this.prev.path);
                        }).then(_this._globalAfter).then(resolve)["catch"](reject);
                      });
                    });
                    return _this._pendingRoute["catch"](function(err) {
                      helpers.logError(err);
                      _this._pendingRoute = Promise.resolve();
                      return _this.go(_this._specialRoutes.fallback ? FALLBACK_ROUTE : _this.prev.path);
                    });
                  });
                })(this)();
              }
              return this._pendingRoute;
            }
          };

          Router.prototype.map = function(path) {
            var matchingRoute, segments, segmentsStrigified;
            path = helpers.cleanPath(path);
            segments = helpers.parsePath(path);
            segmentsStrigified = segments.join('/');
            matchingRoute = this._routesMap[segmentsStrigified];
            if (!matchingRoute) {
              matchingRoute = this._routesMap[segmentsStrigified] = new Route(path, segments, this);
              this._addRoute(matchingRoute);
            }
            return matchingRoute;
          };

          Router.prototype.beforeAll = function(fn) {
            this._globalBefore = fn;
            return this;
          };

          Router.prototype.afterAll = function(fn) {
            this._globalAfter = fn;
            return this;
          };

          Router.prototype.base = function(path) {
            Routing._registerBasePath(this._specialRoutes.basePath = helpers.cleanPath(path));
            return this;
          };

          Router.prototype.root = function(path) {
            this._specialRoutes.rootPath = helpers.cleanPath(path);
            return this;
          };

          Router.prototype.fallback = function(fn) {
            this._specialRoutes.fallback = new Route(FALLBACK_ROUTE, [], this);
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

          return Router;

        })();
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
        helpers.parsePath = function(path, basePath) {
          var addSegment, char, currentSegment, dynamic, i, length, segments;
          dynamic = false;
          currentSegment = '';
          segments = [];
          segments.dynamic = {};
          if (basePath && path.indexOf(basePath) === 0) {
            path = path.slice(basePath.length + 1);
          }
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
        module.exports = Route = (function() {
          function Route(path1, segments1, router1) {
            this.path = path1;
            this.segments = segments1;
            this.router = router1;
            this.originalPath = this.path;
            this.enterAction = this.leaveAction = helpers.noop;
            this.actions = [];
            this.context = {
              path: this.path,
              segments: this.segments,
              params: {}
            };
            this._dynamicFilters = {};
          }

          Route.prototype.entering = function(fn) {
            this.enterAction = fn;
            return this;
          };

          Route.prototype.leaving = function(fn) {
            this.leaveAction = fn;
            return this;
          };

          Route.prototype.to = function(fn) {
            this.actions.push(fn);
            return this;
          };

          Route.prototype.filters = function(filters) {
            this._dynamicFilters = filters;
            return this;
          };

          Route.prototype.remove = function() {
            return this.router._removeRoute(this);
          };

          Route.prototype._invokeAction = function(action, relatedPath, relatedRoute) {
            var result;
            result = action.call(this.context, relatedPath, relatedRoute);
            if (result === this.router._pendingRoute) {
              return null;
            } else {
              return result;
            }
          };

          Route.prototype._run = function(path, prevRoute, prevPath) {
            this._resolveParams(path);
            return Promise.resolve(this._invokeAction(this.enterAction, prevPath, prevRoute)).then((function(_this) {
              return function() {
                return Promise.all(_this.actions.map(function(action) {
                  return _this._invokeAction(action, prevPath, prevRoute);
                }));
              };
            })(this));
          };

          Route.prototype._leave = function(newRoute, newPath) {
            return this._invokeAction(this.leaveAction, newPath, newRoute);
          };

          Route.prototype._resolveParams = function(path) {
            var dynamicIndex, dynamicSegment, ref, segments;
            if (this.segments.hasDynamic) {
              path = this.router._removeBase(path);
              segments = path.split('/');
              ref = this.segments.dynamic;
              for (dynamicIndex in ref) {
                dynamicSegment = ref[dynamicIndex];
                this.context.params[dynamicSegment] = segments[dynamicIndex] || '';
              }
            }
          };

          Object.defineProperty(Route.prototype, 'map', {
            get: function() {
              return this.router.map.bind(this.router);
            }
          });

          Object.defineProperty(Route.prototype, 'listen', {
            get: function() {
              return this.router.listen.bind(this.router);
            }
          });

          return Route;

        })();
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
        var basePaths, changeCallbacks, currentID, dispatchChange, listening, routers;
        changeCallbacks = [];
        routers = [];
        basePaths = [];
        listening = false;
        currentID = 0;
        dispatchChange = function(firstTime) {
          var applicableCallbacks, basePath, callback, j, k, len, len1, len2, n, path, routerBasePath;
          path = helpers.cleanPath(window.location.hash);
          applicableCallbacks = changeCallbacks;
          if (path && basePaths.length) {
            for (j = 0, len = basePaths.length; j < len; j++) {
              basePath = basePaths[j];
              if (path.indexOf(basePath) === 0) {
                applicableCallbacks = [];
                for (k = 0, len1 = changeCallbacks.length; k < len1; k++) {
                  callback = changeCallbacks[k];
                  routerBasePath = callback.router._specialRoutes.basePath;
                  if (routerBasePath === basePath) {
                    applicableCallbacks.push(callback);
                  }
                }
                break;
              }
            }
          }
          for (n = 0, len2 = applicableCallbacks.length; n < len2; n++) {
            callback = applicableCallbacks[n];
            callback(firstTime === true);
          }
        };
        this._onChange = function(router, callback) {
          callback.router = router;
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
        this._registerBasePath = function(path) {
          return basePaths.push(path);
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
          routers.push(routerInstance = new Router(timeout, ++currentID));
          return routerInstance;
        };
        this.version = '1.0.5-c';
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
