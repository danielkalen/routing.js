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

          Router.prototype._addRoute = function(route) {
            this.routes.push(route);
            this.routes.sort(function(a, b) {
              var aLength, bLength, ref, ref1, segmentsDiff;
              segmentsDiff = b.segments.length - a.segments.length;
              if (!segmentsDiff) {
                aLength = ((ref = a.segments.dynamic) != null ? ref.length : void 0) || 0;
                bLength = ((ref1 = b.segments.dynamic) != null ? ref1.length : void 0) || 0;
                segmentsDiff = bLength - aLength;
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

          Router.prototype._matchPath = function(path, firstTime) {
            var dynamicSegment, index, j, k, len, len1, matchingRoute, matchingSoFar, ref, ref1, result, route, segment, segments;
            matchingRoute = this._routesMap[path] || this._cache[path];
            result = {};
            if (!matchingRoute) {
              segments = path.split('/');
              ref = this.routes;
              for (j = 0, len = ref.length; j < len; j++) {
                route = ref[j];
                if (route.path.test(path)) {
                  matchingRoute = route;
                  if (!route.segments.dynamic || !route._dynamicFilters) {
                    break;
                  } else {
                    matchingSoFar = true;
                    for (index = k = 0, len1 = segments.length; k < len1; index = ++k) {
                      segment = segments[index];
                      if (segment !== route.segments[index]) {
                        dynamicSegment = (ref1 = route.segments.dynamic) != null ? ref1[index] : void 0;
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
                    if (!matchingSoFar) {
                      matchingRoute = false;
                      continue;
                    }
                    break;
                  }
                }
              }
            }
            if (matchingRoute) {
              this._cache[path] = matchingRoute;
              result.path = path;
            } else if (firstTime && this._rootPath) {
              return this._matchPath(this._rootPath);
            }
            result.route = matchingRoute || this._fallbackRoute;
            return result;
          };

          Router.prototype._go = function(route, path, storeChange, navDirection) {
            if (route) {
              path = helpers.applyBase(path, this._basePath);
              if (storeChange) {
                window.location.hash = path;
                if (this.current.route && navDirection !== 'back') {
                  this._history.push(this.current);
                }
                if (!navDirection) {
                  this._future.length = 0;
                }
                this.prev = helpers.copyObject(this.current);
                this.current = {
                  route: route,
                  path: path
                };
              }
              this._pendingRoute = this._pendingRoute.then((function(_this) {
                return function() {
                  return new Promise(function(resolve, reject) {
                    setTimeout(function() {
                      return reject(new Error("TimeoutError: '" + path + "' failed to load within " + _this.timeout + "ms (Router #" + _this.ID + ")"));
                    }, _this.timeout);
                    return Promise.resolve().then(_this._globalBefore).then(function() {
                      var ref;
                      return (ref = _this.prev.route) != null ? ref._leave(_this.current.route, _this.current.path) : void 0;
                    }).then(function() {
                      return route._run(path, _this.prev.route, _this.prev.path);
                    }).then(_this._globalAfter).then(resolve)["catch"](reject);
                  });
                };
              })(this));
              return this._pendingRoute["catch"]((function(_this) {
                return function(err) {
                  helpers.logError(err);
                  _this._pendingRoute = Promise.resolve();
                  if (_this._fallbackRoute) {
                    return _this._go(_this._fallbackRoute, _this.current.path);
                  } else {
                    return _this._go(_this.prev.route, _this.prev.path, true, 'back');
                  }
                };
              })(this));
            }
          };

          Router.prototype.go = function(pathGiven, firstTime, navDirection) {
            var matchingRoute, path, result;
            if (typeof pathGiven === 'string') {
              path = helpers.cleanPath(pathGiven);
              path = helpers.removeBase(path, this._basePath);
              if (path === FALLBACK_ROUTE) {
                matchingRoute = this._fallbackRoute;
              } else {
                result = this._matchPath(path, firstTime);
                if (result && result.route) {
                  matchingRoute = result.route;
                  path = result.path || path;
                }
              }
              if (path !== this.current.path) {
                this._go(matchingRoute, path, true);
              }
            }
            return this._pendingRoute;
          };

          Router.prototype.map = function(path) {
            var matchingRoute, pathRegex, segments;
            path = helpers.cleanPath(path);
            segments = helpers.parsePath(path);
            matchingRoute = this._routesMap[path];
            if (!matchingRoute) {
              pathRegex = helpers.segmentsToRegex(segments);
              matchingRoute = this._routesMap[path] = new Route(pathRegex, segments, this);
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
            Routing._registerBasePath(this._basePath = helpers.pathToRegex(helpers.cleanPath(path)));
            return this;
          };

          Router.prototype.root = function(path) {
            this._rootPath = helpers.cleanPath(path);
            return this;
          };

          Router.prototype.fallback = function(fn) {
            this._fallbackRoute = new Route(FALLBACK_ROUTE, [], this);
            this._fallbackRoute.to(fn);
            return this;
          };

          Router.prototype.back = function() {
            var prev;
            if (this.current.route) {
              this._future.unshift(this.current);
            }
            prev = this._history.pop();
            if (prev) {
              return this._go(prev.route, prev.path, true, 'back');
            } else {
              return Promise.resolve();
            }
          };

          Router.prototype.forward = function() {
            var next;
            next = this._future.shift();
            if (next) {
              return this._go(next.route, next.path, true, 'forward');
            } else {
              return Promise.resolve();
            }
          };

          Router.prototype.kill = function() {
            this._routesMap = {};
            this._cache = {};
            this.routes.length = this._history.length = this._future.length = 0;
            this._globalBefore = this._globalAfter = helpers.noop;
            this.current.route = this.current.path = this.prev.route = this.prev.path = null;
          };

          Router.prototype.listen = function() {
            this.listening = true;
            Routing._onChange(this, this._listenCallback = (function(_this) {
              return function(path, firstTime) {
                if (!(_this._basePath && !_this._basePath.test(path))) {
                  return _this.go(path, firstTime, null);
                }
              };
            })(this));
            return this;
          };

          Router.prototype.refresh = function() {
            this.prev.path = this.current.path;
            this.prev.route = this.current.route;
            return this._go(this.current.route, this.current.path);
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
        helpers.copyObject = function(source) {
          var key, target, value;
          target = {};
          for (key in source) {
            value = source[key];
            target[key] = value;
          }
          return target;
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
        helpers.applyBase = function(path, base) {
          if (path[0] === '/') {
            path = path.slice(1);
          }
          if (base && !base.test(path)) {
            return base.string + "/" + path;
          }
          return path;
        };
        helpers.removeBase = function(path, base) {
          if (base && base.test(path)) {
            return path.slice(base.length + 1);
          }
          return path;
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
          var addSegment, char, currentSegment, dynamic, i, length, optional, segments;
          dynamic = optional = false;
          currentSegment = '';
          segments = [];
          if (basePath && basePath.test(path)) {
            path = path.slice(basePath.length + 1);
          }
          length = path.length;
          i = -1;
          addSegment = function() {
            var index;
            segments.push(currentSegment);
            index = segments.length - 1;
            if (dynamic) {
              if (segments.optional == null) {
                segments.optional = {};
              }
              if (segments.dynamic == null) {
                segments.dynamic = {
                  length: 0
                };
              }
              segments.dynamic[index] = currentSegment;
            }
            if (optional) {
              segments.optional[index] = currentSegment;
            }
            currentSegment = '';
            return dynamic = optional = false;
          };
          while (++i !== length) {
            switch (char = path[i]) {
              case '/':
                addSegment();
                break;
              case ':':
                dynamic = true;
                break;
              case '?':
                optional = true;
                break;
              default:
                currentSegment += char;
            }
          }
          addSegment();
          return segments;
        };
        helpers.pathToRegex = function(pathOrig) {
          var path, regex;
          path = pathOrig.replace(/\//g, '\\/');
          regex = new RegExp("^" + pathOrig);
          regex.string = pathOrig;
          regex.length = pathOrig.length;
          return regex;
        };
        helpers.segmentsToRegex = function(segments) {
          var index, j, len, path, ref, segment;
          path = '';
          for (index = j = 0, len = segments.length; j < len; index = ++j) {
            segment = segments[index];
            if ((ref = segments.dynamic) != null ? ref[index] : void 0) {
              segment = '.+?';
              if (path) {
                segment = "/" + segment;
              }
              if (segments.optional[index]) {
                segment = "(?:" + segment + ")?";
              }
            } else {
              if (path) {
                path += '/';
              }
            }
            path += segment;
          }
          return helpers.pathToRegex(path);
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
            this.enterAction = this.leaveAction = helpers.noop;
            this.actions = [];
            this.context = {
              segments: this.segments,
              path: this.path.string,
              params: {}
            };
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
            var dynamicIndex, ref, segmentName, segments;
            if (this.segments.dynamic) {
              path = helpers.removeBase(path, this.router._basePath);
              segments = path.split('/');
              ref = this.segments.dynamic;
              for (dynamicIndex in ref) {
                segmentName = ref[dynamicIndex];
                if (dynamicIndex !== 'length') {
                  this.context.params[segmentName] = segments[dynamicIndex] || '';
                }
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
              if (!(basePath.test(path))) {
                continue;
              }
              applicableCallbacks = [];
              for (k = 0, len1 = changeCallbacks.length; k < len1; k++) {
                callback = changeCallbacks[k];
                routerBasePath = callback.router._basePath;
                if (routerBasePath === basePath) {
                  applicableCallbacks.push(callback);
                }
              }
              break;
            }
          }
          for (n = 0, len2 = applicableCallbacks.length; n < len2; n++) {
            callback = applicableCallbacks[n];
            callback(path, firstTime === true);
          }
        };
        this._onChange = function(router, callback) {
          callback.router = router;
          changeCallbacks.push(callback);
          if (!listening) {
            listening = true;

            /* istanbul ignore next */
            if (window.onhashchange !== void 0 && (!document.documentMode || document.documentMode >= 8)) {
              window.addEventListener('hashchange', dispatchChange);
            } else {
              setInterval(dispatchChange, 100);
            }
          }
          return callback(helpers.cleanPath(window.location.hash), true);
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
