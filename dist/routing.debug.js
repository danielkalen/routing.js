(function (require, global) {
require = (function (cache, modules, cx) {
return function (r) {
if (!modules[r]) throw new Error(r + ' is not a module');
return cache[r] ? cache[r].exports : ((cache[r] = {
exports: {}
}, cache[r].exports = modules[r].call(cx, require, cache[r], cache[r].exports)));
};
})({}, {
3: function (require, module, exports) {
(function () {
var process = require(6);
/**
 * This is the web browser implementation of `debug()`.
 *
 * Expose `debug()` as the module.
 */

exports = module.exports = require(7);
exports.log = log;
exports.formatArgs = formatArgs;
exports.save = save;
exports.load = load;
exports.useColors = useColors;
exports.storage = 'undefined' != typeof chrome
               && 'undefined' != typeof chrome.storage
                  ? chrome.storage.local
                  : localstorage();

/**
 * Colors.
 */

exports.colors = [
  'lightseagreen',
  'forestgreen',
  'goldenrod',
  'dodgerblue',
  'darkorchid',
  'crimson'
];

/**
 * Currently only WebKit-based Web Inspectors, Firefox >= v31,
 * and the Firebug extension (any Firefox version) are known
 * to support "%c" CSS customizations.
 *
 * TODO: add a `localStorage` variable to explicitly enable/disable colors
 */

function useColors() {
  // NB: In an Electron preload script, document will be defined but not fully
  // initialized. Since we know we're in Chrome, we'll just detect this case
  // explicitly
  if (typeof window !== 'undefined' && window.process && window.process.type === 'renderer') {
    return true;
  }

  // is webkit? http://stackoverflow.com/a/16459606/376773
  // document is undefined in react-native: https://github.com/facebook/react-native/pull/1632
  return (typeof document !== 'undefined' && document.documentElement && document.documentElement.style && document.documentElement.style.WebkitAppearance) ||
    // is firebug? http://stackoverflow.com/a/398120/376773
    (typeof window !== 'undefined' && window.console && (window.console.firebug || (window.console.exception && window.console.table))) ||
    // is firefox >= v31?
    // https://developer.mozilla.org/en-US/docs/Tools/Web_Console#Styling_messages
    (typeof navigator !== 'undefined' && navigator.userAgent && navigator.userAgent.toLowerCase().match(/firefox\/(\d+)/) && parseInt(RegExp.$1, 10) >= 31) ||
    // double check webkit in userAgent just in case we are in a worker
    (typeof navigator !== 'undefined' && navigator.userAgent && navigator.userAgent.toLowerCase().match(/applewebkit\/(\d+)/));
}

/**
 * Map %j to `JSON.stringify()`, since no Web Inspectors do that by default.
 */

exports.formatters.j = function(v) {
  try {
    return JSON.stringify(v);
  } catch (err) {
    return '[UnexpectedJSONParseError]: ' + err.message;
  }
};


/**
 * Colorize log arguments if enabled.
 *
 * @api public
 */

function formatArgs(args) {
  var useColors = this.useColors;

  args[0] = (useColors ? '%c' : '')
    + this.namespace
    + (useColors ? ' %c' : ' ')
    + args[0]
    + (useColors ? '%c ' : ' ')
    + '+' + exports.humanize(this.diff);

  if (!useColors) return;

  var c = 'color: ' + this.color;
  args.splice(1, 0, c, 'color: inherit')

  // the final "%c" is somewhat tricky, because there could be other
  // arguments passed either before or after the %c, so we need to
  // figure out the correct index to insert the CSS into
  var index = 0;
  var lastC = 0;
  args[0].replace(/%[a-zA-Z%]/g, function(match) {
    if ('%%' === match) return;
    index++;
    if ('%c' === match) {
      // we only are interested in the *last* %c
      // (the user may have provided their own)
      lastC = index;
    }
  });

  args.splice(lastC, 0, c);
}

/**
 * Invokes `console.log()` when available.
 * No-op when `console.log` is not a "function".
 *
 * @api public
 */

function log() {
  // this hackery is required for IE8/9, where
  // the `console.log` function doesn't have 'apply'
  return 'object' === typeof console
    && console.log
    && Function.prototype.apply.call(console.log, console, arguments);
}

/**
 * Save `namespaces`.
 *
 * @param {String} namespaces
 * @api private
 */

function save(namespaces) {
  try {
    if (null == namespaces) {
      exports.storage.removeItem('debug');
    } else {
      exports.storage.debug = namespaces;
    }
  } catch(e) {}
}

/**
 * Load `namespaces`.
 *
 * @return {String} returns the previously persisted debug modes
 * @api private
 */

function load() {
  var r;
  try {
    r = exports.storage.debug;
  } catch(e) {}

  // If debug isn't set in LS, and we're in Electron, try to load $DEBUG
  if (!r && typeof process !== 'undefined' && 'env' in process) {
    r = process.env.DEBUG;
  }

  return r;
}

/**
 * Enable namespaces listed in `localStorage.debug` initially.
 */

exports.enable(load());

/**
 * Localstorage attempts to return the localstorage.
 *
 * This is necessary because safari throws
 * when a user disables cookies/localstorage
 * and you attempt to access it.
 *
 * @return {LocalStorage}
 * @api private
 */

function localstorage() {
  try {
    return window.localStorage;
  } catch (e) {}
}

}).call(this);
return module.exports;
},
0: function (require, module, exports) {
var Router, Routing, debug, helpers;

Router = require(1);

helpers = require(2);

debug = (require(3))('routing:global');

Routing = new function() {
  var currentID, handleHashChange, listening, listeningRouters, routers;
  routers = [];
  listeningRouters = [];
  listening = false;
  currentID = 0;
  handleHashChange = function(e) {
    var highestPriority, i, j, k, len, len1, len2, matchingRoute, matchingRoutes, path, route, router, targetPath;
    path = helpers.currentPath();
    matchingRoutes = [];
    debug("hash change " + path);
    for (i = 0, len = listeningRouters.length; i < len; i++) {
      router = listeningRouters[i];
      if (router._basePath && !router._basePath.test(path)) {
        continue;
      }
      targetPath = helpers.removeBase(path, router._basePath);
      matchingRoute = router._matchPath(targetPath);
      if (matchingRoute) {
        if (matchingRoute.constructor === Array) {
          matchingRoutes.push.apply(matchingRoutes, matchingRoute);
        } else {
          matchingRoutes.push(matchingRoute);
        }
      }
    }
    if (!matchingRoutes.length) {
      for (j = 0, len1 = listeningRouters.length; j < len1; j++) {
        router = listeningRouters[j];
        if (router._fallbackRoute) {
          if (!(router._basePath && !router._basePath.test(path))) {
            matchingRoutes.push(router._fallbackRoute);
          }
        }
      }
    }
    highestPriority = Math.max.apply(Math, matchingRoutes.map(function(route) {
      return route.router._priority;
    }));
    matchingRoutes = matchingRoutes.filter(function(route) {
      return route.router._priority === highestPriority;
    });
    debug(matchingRoutes.length + " matching routes");
    for (k = 0, len2 = matchingRoutes.length; k < len2; k++) {
      route = matchingRoutes[k];
      if (route.router.current.path !== path) {
        route.router._go(route, path, true);
      }
    }
  };
  this._registerRouter = function(router, initOnStart) {
    var defaultPath, matchingRoute, path;
    listeningRouters.push(router);
    if (!listening) {
      listening = true;

      /* istanbul ignore next */
      if (window.onhashchange !== void 0 && (!document.documentMode || document.documentMode >= 8)) {
        window.addEventListener('hashchange', handleHashChange);
      } else {
        setInterval(handleHashChange, 100);
      }
    }
    if (initOnStart) {
      path = helpers.currentPath();
      if (typeof initOnStart === 'string') {
        defaultPath = helpers.cleanPath(initOnStart);
      }
      if (router._basePath && !router._basePath.test(path) && !defaultPath) {
        return;
      }
      matchingRoute = router._matchPath(helpers.removeBase(path, router._basePath));
      if (!matchingRoute && defaultPath) {
        matchingRoute = router._matchPath(defaultPath);
        path = defaultPath;
      }
      if (matchingRoute == null) {
        matchingRoute = router._fallbackRoute;
      }
      if (matchingRoute) {
        return router._go(matchingRoute, path, true);
      }
    }
  };
  this.killAll = function() {
    var i, len, router, routersToKill;
    routersToKill = routers.slice();
    for (i = 0, len = routersToKill.length; i < len; i++) {
      router = routersToKill[i];
      router.kill();
    }
    routers.length = 0;
    listeningRouters.length = 0;
  };
  this.Router = function(timeout) {
    var routerInstance;
    routers.push(routerInstance = new Router(timeout, ++currentID));
    return routerInstance;
  };
  this.version = "1.1.1";
  return this;
};

module.exports = Routing;

;
return module.exports;
},
7: function (require, module, exports) {

/**
 * This is the common logic for both the Node.js and web browser
 * implementations of `debug()`.
 *
 * Expose `debug()` as the module.
 */

exports = module.exports = createDebug.debug = createDebug['default'] = createDebug;
exports.coerce = coerce;
exports.disable = disable;
exports.enable = enable;
exports.enabled = enabled;
exports.humanize = require(8);

/**
 * The currently active debug mode names, and names to skip.
 */

exports.names = [];
exports.skips = [];

/**
 * Map of special "%n" handling functions, for the debug "format" argument.
 *
 * Valid key names are a single, lower or upper-case letter, i.e. "n" and "N".
 */

exports.formatters = {};

/**
 * Previous log timestamp.
 */

var prevTime;

/**
 * Select a color.
 * @param {String} namespace
 * @return {Number}
 * @api private
 */

function selectColor(namespace) {
  var hash = 0, i;

  for (i in namespace) {
    hash  = ((hash << 5) - hash) + namespace.charCodeAt(i);
    hash |= 0; // Convert to 32bit integer
  }

  return exports.colors[Math.abs(hash) % exports.colors.length];
}

/**
 * Create a debugger with the given `namespace`.
 *
 * @param {String} namespace
 * @return {Function}
 * @api public
 */

function createDebug(namespace) {

  function debug() {
    // disabled?
    if (!debug.enabled) return;

    var self = debug;

    // set `diff` timestamp
    var curr = +new Date();
    var ms = curr - (prevTime || curr);
    self.diff = ms;
    self.prev = prevTime;
    self.curr = curr;
    prevTime = curr;

    // turn the `arguments` into a proper Array
    var args = new Array(arguments.length);
    for (var i = 0; i < args.length; i++) {
      args[i] = arguments[i];
    }

    args[0] = exports.coerce(args[0]);

    if ('string' !== typeof args[0]) {
      // anything else let's inspect with %O
      args.unshift('%O');
    }

    // apply any `formatters` transformations
    var index = 0;
    args[0] = args[0].replace(/%([a-zA-Z%])/g, function(match, format) {
      // if we encounter an escaped % then don't increase the array index
      if (match === '%%') return match;
      index++;
      var formatter = exports.formatters[format];
      if ('function' === typeof formatter) {
        var val = args[index];
        match = formatter.call(self, val);

        // now we need to remove `args[index]` since it's inlined in the `format`
        args.splice(index, 1);
        index--;
      }
      return match;
    });

    // apply env-specific formatting (colors, etc.)
    exports.formatArgs.call(self, args);

    var logFn = debug.log || exports.log || console.log.bind(console);
    logFn.apply(self, args);
  }

  debug.namespace = namespace;
  debug.enabled = exports.enabled(namespace);
  debug.useColors = exports.useColors();
  debug.color = selectColor(namespace);

  // env-specific initialization logic for debug instances
  if ('function' === typeof exports.init) {
    exports.init(debug);
  }

  return debug;
}

/**
 * Enables a debug mode by namespaces. This can include modes
 * separated by a colon and wildcards.
 *
 * @param {String} namespaces
 * @api public
 */

function enable(namespaces) {
  exports.save(namespaces);

  exports.names = [];
  exports.skips = [];

  var split = (typeof namespaces === 'string' ? namespaces : '').split(/[\s,]+/);
  var len = split.length;

  for (var i = 0; i < len; i++) {
    if (!split[i]) continue; // ignore empty strings
    namespaces = split[i].replace(/\*/g, '.*?');
    if (namespaces[0] === '-') {
      exports.skips.push(new RegExp('^' + namespaces.substr(1) + '$'));
    } else {
      exports.names.push(new RegExp('^' + namespaces + '$'));
    }
  }
}

/**
 * Disable debug output.
 *
 * @api public
 */

function disable() {
  exports.enable('');
}

/**
 * Returns true if the given mode name is enabled, false otherwise.
 *
 * @param {String} name
 * @return {Boolean}
 * @api public
 */

function enabled(name) {
  var i, len;
  for (i = 0, len = exports.skips.length; i < len; i++) {
    if (exports.skips[i].test(name)) {
      return false;
    }
  }
  for (i = 0, len = exports.names.length; i < len; i++) {
    if (exports.names[i].test(name)) {
      return true;
    }
  }
  return false;
}

/**
 * Coerce `val`.
 *
 * @param {Mixed} val
 * @return {Mixed}
 * @api private
 */

function coerce(val) {
  if (val instanceof Error) return val.stack || val.message;
  return val;
}
;
return module.exports;
},
6: function (require, module, exports) {
// shim for using process in browser
var process = module.exports = {};

// cached from whatever global is present so that test runners that stub it
// don't break things.  But we need to wrap it in a try catch in case it is
// wrapped in strict mode code which doesn't define any globals.  It's inside a
// function because try/catches deoptimize in certain engines.

var cachedSetTimeout;
var cachedClearTimeout;

function defaultSetTimout() {
    throw new Error('setTimeout has not been defined');
}
function defaultClearTimeout () {
    throw new Error('clearTimeout has not been defined');
}
(function () {
    try {
        if (typeof setTimeout === 'function') {
            cachedSetTimeout = setTimeout;
        } else {
            cachedSetTimeout = defaultSetTimout;
        }
    } catch (e) {
        cachedSetTimeout = defaultSetTimout;
    }
    try {
        if (typeof clearTimeout === 'function') {
            cachedClearTimeout = clearTimeout;
        } else {
            cachedClearTimeout = defaultClearTimeout;
        }
    } catch (e) {
        cachedClearTimeout = defaultClearTimeout;
    }
} ())
function runTimeout(fun) {
    if (cachedSetTimeout === setTimeout) {
        //normal enviroments in sane situations
        return setTimeout(fun, 0);
    }
    // if setTimeout wasn't available but was latter defined
    if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {
        cachedSetTimeout = setTimeout;
        return setTimeout(fun, 0);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedSetTimeout(fun, 0);
    } catch(e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally
            return cachedSetTimeout.call(null, fun, 0);
        } catch(e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error
            return cachedSetTimeout.call(this, fun, 0);
        }
    }


}
function runClearTimeout(marker) {
    if (cachedClearTimeout === clearTimeout) {
        //normal enviroments in sane situations
        return clearTimeout(marker);
    }
    // if clearTimeout wasn't available but was latter defined
    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {
        cachedClearTimeout = clearTimeout;
        return clearTimeout(marker);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedClearTimeout(marker);
    } catch (e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally
            return cachedClearTimeout.call(null, marker);
        } catch (e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.
            // Some versions of I.E. have different rules for clearTimeout vs setTimeout
            return cachedClearTimeout.call(this, marker);
        }
    }



}
var queue = [];
var draining = false;
var currentQueue;
var queueIndex = -1;

function cleanUpNextTick() {
    if (!draining || !currentQueue) {
        return;
    }
    draining = false;
    if (currentQueue.length) {
        queue = currentQueue.concat(queue);
    } else {
        queueIndex = -1;
    }
    if (queue.length) {
        drainQueue();
    }
}

function drainQueue() {
    if (draining) {
        return;
    }
    var timeout = runTimeout(cleanUpNextTick);
    draining = true;

    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        while (++queueIndex < len) {
            if (currentQueue) {
                currentQueue[queueIndex].run();
            }
        }
        queueIndex = -1;
        len = queue.length;
    }
    currentQueue = null;
    draining = false;
    runClearTimeout(timeout);
}

process.nextTick = function (fun) {
    var args = new Array(arguments.length - 1);
    if (arguments.length > 1) {
        for (var i = 1; i < arguments.length; i++) {
            args[i - 1] = arguments[i];
        }
    }
    queue.push(new Item(fun, args));
    if (queue.length === 1 && !draining) {
        runTimeout(drainQueue);
    }
};

// v8 likes predictible objects
function Item(fun, array) {
    this.fun = fun;
    this.array = array;
}
Item.prototype.run = function () {
    this.fun.apply(null, this.array);
};
process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];
process.version = ''; // empty string to avoid regexp issues
process.versions = {};

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;
process.prependListener = noop;
process.prependOnceListener = noop;

process.listeners = function (name) { return [] }

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};
process.umask = function() { return 0; };
;
return module.exports;
},
5: function (require, module, exports) {
var Context, Route, debug, helpers;

Context = require(9);

helpers = require(2);

debug = (require(3))('routing:router');

module.exports = Route = (function() {
  function Route(path1, segments1, router, _isPassive) {
    this.path = path1;
    this.segments = segments1;
    this.router = router;
    this._isPassive = _isPassive;
    this._context = new Context(this);
    this._enterAction = this._leaveAction = helpers.noop;
    this._actions = [];
  }

  Route.prototype.entering = function(fn) {
    this._enterAction = fn;
    return this;
  };

  Route.prototype.leaving = function(fn) {
    this._leaveAction = fn;
    return this;
  };

  Route.prototype.to = function(fn) {
    this._actions.push(fn);
    return this;
  };

  Route.prototype.filters = function(filters) {
    this._dynamicFilters = filters;
    return this;
  };

  Route.prototype.passive = function() {
    if (this._isPassive) {
      return this;
    } else if (!this._passiveVersion) {
      debug("added passive version " + this.path.original);
      this._passiveVersion = new Route(this.path, this.segments, this.router, true);
      this.router._hasPassives = true;
    }
    return this._passiveVersion;
  };

  Route.prototype.remove = function() {
    return this.router._removeRoute(this);
  };

  Route.prototype._invokeAction = function(action, relatedPath, relatedRoute) {
    var result;
    result = action.call(this._context, relatedPath, relatedRoute);
    if (result === this.router._pendingRoute) {
      return null;
    } else {
      return result;
    }
  };

  Route.prototype._run = function(path, prevRoute, prevPath) {
    debug("running " + this.path.original);
    this._isActive = true;
    this._context.params = this._resolveParams(path);
    this._context.query = helpers.parseQuery(path);
    return Promise.resolve(this._invokeAction(this._enterAction, prevPath, prevRoute)).then((function(_this) {
      return function() {
        return Promise.all(_this._actions.map(function(action) {
          return _this._invokeAction(action, prevPath, prevRoute);
        }));
      };
    })(this));
  };

  Route.prototype._leave = function(newRoute, newPath) {
    if (this._isActive) {
      debug("leaving " + this.path.original + " from " + (newRoute != null ? newRoute.path.original : void 0));
      this._isActive = false;
      return this._invokeAction(this._leaveAction, newPath, newRoute);
    }
  };

  Route.prototype._resolveParams = function(path) {
    var dynamicIndex, params, ref, segmentName, segments;
    if (!this.segments.dynamic) {
      return helpers.noopObj;
    }
    path = helpers.removeQuery(helpers.removeBase(path, this.router._basePath));
    segments = path.split('/');
    params = {};
    ref = this.segments.dynamic;
    for (dynamicIndex in ref) {
      segmentName = ref[dynamicIndex];
      if (dynamicIndex !== 'length') {
        params[segmentName] = segments[dynamicIndex] || '';
      }
    }
    return params;
  };

  Route.prototype.matchesPath = function(target) {
    var dynamicSegment, i, index, isMatching, len, segment, segments;
    isMatching = false;
    if (isMatching = this.path.test(target)) {
      if (this.segments.dynamic && this._dynamicFilters) {
        if (!segments) {
          segments = target.split('/');
        }
        for (index = i = 0, len = segments.length; i < len; index = ++i) {
          segment = segments[index];
          if (segment !== this.segments[index]) {
            dynamicSegment = this.segments.dynamic[index];
            if (isMatching = dynamicSegment != null) {
              if (this._dynamicFilters[dynamicSegment]) {
                isMatching = this._dynamicFilters[dynamicSegment](segment);
              }
            }
          }
          if (!isMatching) {
            break;
          }
        }
      }
    }
    return isMatching;
  };

  Object.defineProperties(Route.prototype, {
    'map': {
      get: function() {
        return this.router.map.bind(this.router);
      }
    },
    'mapOnce': {
      get: function() {
        return this.router.mapOnce.bind(this.router);
      }
    },
    'listen': {
      get: function() {
        return this.router.listen.bind(this.router);
      }
    }
  });

  return Route;

})();

;
return module.exports;
},
9: function (require, module, exports) {
var Context;

module.exports = Context = (function() {
  function Context(route) {
    this.route = route;
    this.segments = this.route.segments;
    this.path = this.route.path.string;
    this.params = {};
    this.query = {};
  }

  Context.prototype.remove = function() {
    return this.route.remove();
  };

  Context.prototype.redirect = function(path) {
    this.route.router.go(path, 'redirect');
    return Promise.resolve();
  };

  return Context;

})();

;
return module.exports;
},
8: function (require, module, exports) {
/**
 * Helpers.
 */

var s = 1000;
var m = s * 60;
var h = m * 60;
var d = h * 24;
var y = d * 365.25;

/**
 * Parse or format the given `val`.
 *
 * Options:
 *
 *  - `long` verbose formatting [false]
 *
 * @param {String|Number} val
 * @param {Object} [options]
 * @throws {Error} throw an error if val is not a non-empty string or a number
 * @return {String|Number}
 * @api public
 */

module.exports = function(val, options) {
  options = options || {};
  var type = typeof val;
  if (type === 'string' && val.length > 0) {
    return parse(val);
  } else if (type === 'number' && isNaN(val) === false) {
    return options.long ? fmtLong(val) : fmtShort(val);
  }
  throw new Error(
    'val is not a non-empty string or a valid number. val=' +
      JSON.stringify(val)
  );
};

/**
 * Parse the given `str` and return milliseconds.
 *
 * @param {String} str
 * @return {Number}
 * @api private
 */

function parse(str) {
  str = String(str);
  if (str.length > 100) {
    return;
  }
  var match = /^((?:\d+)?\.?\d+) *(milliseconds?|msecs?|ms|seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h|days?|d|years?|yrs?|y)?$/i.exec(
    str
  );
  if (!match) {
    return;
  }
  var n = parseFloat(match[1]);
  var type = (match[2] || 'ms').toLowerCase();
  switch (type) {
    case 'years':
    case 'year':
    case 'yrs':
    case 'yr':
    case 'y':
      return n * y;
    case 'days':
    case 'day':
    case 'd':
      return n * d;
    case 'hours':
    case 'hour':
    case 'hrs':
    case 'hr':
    case 'h':
      return n * h;
    case 'minutes':
    case 'minute':
    case 'mins':
    case 'min':
    case 'm':
      return n * m;
    case 'seconds':
    case 'second':
    case 'secs':
    case 'sec':
    case 's':
      return n * s;
    case 'milliseconds':
    case 'millisecond':
    case 'msecs':
    case 'msec':
    case 'ms':
      return n;
    default:
      return undefined;
  }
}

/**
 * Short format for `ms`.
 *
 * @param {Number} ms
 * @return {String}
 * @api private
 */

function fmtShort(ms) {
  if (ms >= d) {
    return Math.round(ms / d) + 'd';
  }
  if (ms >= h) {
    return Math.round(ms / h) + 'h';
  }
  if (ms >= m) {
    return Math.round(ms / m) + 'm';
  }
  if (ms >= s) {
    return Math.round(ms / s) + 's';
  }
  return ms + 'ms';
}

/**
 * Long format for `ms`.
 *
 * @param {Number} ms
 * @return {String}
 * @api private
 */

function fmtLong(ms) {
  return plural(ms, d, 'day') ||
    plural(ms, h, 'hour') ||
    plural(ms, m, 'minute') ||
    plural(ms, s, 'second') ||
    ms + ' ms';
}

/**
 * Pluralization helper.
 */

function plural(ms, n, name) {
  if (ms < n) {
    return;
  }
  if (ms < n * 1.5) {
    return Math.floor(ms / n) + ' ' + name;
  }
  return Math.ceil(ms / n) + ' ' + name + 's';
}
;
return module.exports;
},
1: function (require, module, exports) {
var Route, Router, debug, helpers;

Route = require(5);

helpers = require(2);

debug = (require(3))('routing:router');

Router = (function() {
  function Router(timeout, ID) {
    this.timeout = timeout;
    this.ID = ID;
    if (isNaN(this.timeout)) {
      this.timeout = 2500;
    }
    this.listening = false;
    this.routes = [];
    this._priority = 1;
    this._routesMap = {};
    this._cache = {};
    this._history = [];
    this._future = [];
    this._globalBefore = this._globalAfter = helpers.noop;
    this._pendingRoute = Promise.resolve();
    this._activeRoutes = [];
    this.current = this.prev = {
      route: null,
      path: null
    };
  }

  Router.prototype._addRoute = function(route) {
    this.routes.push(route);
    this.routes.sort(function(a, b) {
      var aLength, bLength, ref, ref1, segmentsDiff;
      segmentsDiff = a.segments.length - b.segments.length;
      if (!segmentsDiff) {
        aLength = ((ref = a.segments.dynamic) != null ? ref.length : void 0) || 0;
        bLength = ((ref1 = b.segments.dynamic) != null ? ref1.length : void 0) || 0;
        segmentsDiff = aLength - bLength;
      }
      return segmentsDiff;
    });
    debug("added route " + route.path.original);
    return route;
  };

  Router.prototype._removeRoute = function(route) {
    var cacheKeys, mapKeys, matchingCacheKey, matchingMapKey;
    cacheKeys = Object.keys(this._cache);
    mapKeys = Object.keys(this._routesMap);
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
    helpers.removeItem(this.routes, route);
    delete this._cache[matchingCacheKey];
    delete this._routesMap[matchingMapKey];
    return debug("removed route " + route.path.original);
  };

  Router.prototype._matchPath = function(path) {
    var i, len, matchingRoute, passiveRoutes, ref, ref1, route;
    path = helpers.removeQuery(path);
    matchingRoute = this._cache[path];
    if (!matchingRoute) {
      ref = this.routes;
      for (i = 0, len = ref.length; i < len; i++) {
        route = ref[i];
        if (!route.matchesPath(path)) {
          continue;
        }
        if (this._hasPassives) {
          if (route._passiveVersion) {
            if (!passiveRoutes) {
              passiveRoutes = [];
            }
            passiveRoutes.push(route._passiveVersion);
            if (route._actions.length === 0) {
              continue;
            }
          }
          if (!matchingRoute) {
            matchingRoute = route;
          }
        } else {
          matchingRoute = route;
          break;
        }
      }
    }
    if (passiveRoutes) {
      if (matchingRoute) {
        passiveRoutes.push(matchingRoute);
      }
      matchingRoute = passiveRoutes;
      debug("matched " + path + " with [" + (passiveRoutes.map(function(r) {
        return r.path.original;
      }).join(', ')) + "]");
    } else {
      if (matchingRoute) {
        debug("matched " + path + " with " + (((ref1 = matchingRoute.path) != null ? ref1.original : void 0) || matchingRoute.path));
      }
    }
    if (matchingRoute) {
      return this._cache[path] = matchingRoute;
    }
  };

  Router.prototype._go = function(route, path, storeChange, navDirection, activeRoutes) {
    if (!activeRoutes) {
      activeRoutes = this._activeRoutes.slice();
      this._activeRoutes.length = 0;
    }
    if (route.constructor === Array) {
      return Promise.all(route.map((function(_this) {
        return function(route_) {
          return _this._go(route_, path, storeChange, navDirection, activeRoutes);
        };
      })(this)));
    }
    path = helpers.applyBase(path, this._basePath);
    if (storeChange && !route._isPassive) {
      debug("storing hash change " + route.path.original);
      if (path !== helpers.currentPath()) {
        window.location.hash = path;
      }
      if (navDirection === 'redirect') {
        this.current = this.prev;
        this._history.pop();
      }
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
          if (!(route === _this._fallbackRoute || helpers.includes(_this._activeRoutes, route))) {
            _this._activeRoutes.push(route);
          }
          setTimeout(function() {
            return reject(new Error("TimeoutError: '" + path + "' failed to load within " + _this.timeout + "ms (Router #" + _this.ID + ")"));
          }, _this.timeout);
          debug("starting route transition");
          return Promise.resolve().then(_this._globalBefore).then(function() {
            return Promise.all(activeRoutes.map(function(route) {
              return route._leave(_this.current.route, _this.current.path);
            }));
          }).then(function() {
            return route._run(path, _this.prev.route, _this.prev.path);
          }).then(_this._globalAfter).then(resolve)["catch"](reject);
        });
      };
    })(this));
    return this._pendingRoute["catch"]((function(_this) {
      return function(err) {
        debug("error occured during route transition");
        helpers.logError(err);
        _this._pendingRoute = Promise.resolve();
        if (_this._fallbackRoute) {
          return _this._go(_this._fallbackRoute, _this.current.path);
        } else {
          return _this._go(_this.prev.route, _this.prev.path, true, 'back');
        }
      };
    })(this));
  };

  Router.prototype.go = function(pathGiven, isRedirect) {
    var matchingRoute, path;
    if (typeof pathGiven === 'string') {
      debug("starting manual route transition to " + pathGiven);
      path = helpers.cleanPath(pathGiven);
      path = helpers.removeBase(path, this._basePath);
      matchingRoute = this._matchPath(path);
      if (!matchingRoute) {
        matchingRoute = this._fallbackRoute;
      }
      if (matchingRoute && path !== this.current.path) {
        this._go(matchingRoute, path, true, isRedirect);
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

  Router.prototype.mapOnce = function(path) {
    return this.map(path).to(function() {
      return this.remove();
    });
  };

  Router.prototype.listen = function(initOnStart) {
    if (initOnStart == null) {
      initOnStart = true;
    }
    this.listening = true;
    (require(0))._registerRouter(this, initOnStart);
    debug("router " + this.ID + " listening");
    return this;
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
    this._basePath = helpers.pathToRegex(helpers.cleanPath(path), true, path);
    return this;
  };

  Router.prototype.priority = function(priority) {
    if (priority && typeof priority === 'number') {
      this._priority = priority;
    }
    return this;
  };

  Router.prototype.fallback = function(fn) {
    this._fallbackRoute = new Route('*FALLBACK*', [], this);
    this._fallbackRoute.to(fn);
    debug("added fallback route");
    return this;
  };

  Router.prototype.back = function() {
    var prev;
    debug("history - back");
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
    debug("history - forward");
    next = this._future.shift();
    if (next) {
      return this._go(next.route, next.path, true, 'forward');
    } else {
      return Promise.resolve();
    }
  };

  Router.prototype.refresh = function() {
    debug("history - refresh");
    if (this.current.route) {
      this.prev.path = this.current.path;
      this.prev.route = this.current.route;
      this._go(this.current.route, this.current.path);
    }
    return this._pendingRoute;
  };

  Router.prototype.kill = function() {
    this._routesMap = {};
    this._cache = {};
    this.routes.length = this._history.length = this._future.length = 0;
    this._globalBefore = this._globalAfter = helpers.noop;
    this._fallbackRoute = null;
    this.current.route = this.current.path = this.prev.route = this.prev.path = null;
    debug("router " + this.ID + " killed");
  };

  return Router;

})();

module.exports = Router;

;
return module.exports;
},
2: function (require, module, exports) {
var helpers;

helpers = exports;

helpers.noopObj = {};

helpers.noop = function() {
  return Promise.resolve();
};

helpers.currentPath = function() {
  return helpers.cleanPath(window.location.hash);
};

helpers.removeQuery = function(path) {
  return path.split('?')[0];
};

helpers.parseQuery = function(path) {
  var j, len, pair, pairs, parsed, query, split;
  query = path.split('?')[1];
  if (query) {
    parsed = {};
    pairs = query.split('&');
    for (j = 0, len = pairs.length; j < len; j++) {
      pair = pairs[j];
      split = pair.split('=');
      parsed[split[0]] = split[1];
    }
    return parsed;
  }
  return helpers.noopObj;
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

helpers.includes = function(target, item) {
  return target.indexOf(item) !== -1;
};

helpers.removeItem = function(target, item) {
  var itemIndex;
  itemIndex = target.indexOf(item);
  target.splice(itemIndex, 1);
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
  if (base && !base.test(path)) {
    return base.string + "/" + path;
  }
  return path;
};

helpers.removeBase = function(path, base) {
  if (base && base.test(path)) {
    path = path.slice(base.length + 1);
    if (!path.length || path[0] === '?') {
      path = '/' + path;
    }
  }
  return path;
};

helpers.cleanPath = function(path) {
  if (path[0] === '#') {
    path = path.slice(1);
  }
  if (path.length === 0 || path[0] === '?') {
    path = '/' + path;
  } else if (path.length > 1) {
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
  var addSegment, char, currentSegment, dynamic, i, length, optional, segments;
  if (path === '/') {
    return ['/'];
  }
  dynamic = optional = false;
  currentSegment = '';
  segments = [];
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

helpers.pathToRegex = function(targetPath, openEnded, original) {
  var path, regex;
  path = targetPath.replace(/\//g, '\\/');
  regex = "^" + targetPath;
  if (!openEnded) {
    regex += '$';
  }
  regex = new RegExp(regex);
  regex.original = original;
  regex.string = targetPath;
  regex.length = targetPath.length;
  return regex;
};

helpers.segmentsToRegex = function(segments, original) {
  var index, j, len, path, ref, segment;
  path = '';
  for (index = j = 0, len = segments.length; j < len; index = ++j) {
    segment = segments[index];
    if ((ref = segments.dynamic) != null ? ref[index] : void 0) {
      segment = '[^\/]+';
      if (segments.length === 1) {
        segment += '$';
      }
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
  return helpers.pathToRegex(path, false, original);
};

;
return module.exports;
}
}, this);
if (typeof define === 'function' && define.umd) {
define(function () {
return require(0);
});
} else if (typeof module === 'object' && module.exports) {
module.exports = require(0);
} else {
return this['Routing'] = require(0);
}
}).call(this, null, typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : this);
