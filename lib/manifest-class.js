// Generated by CoffeeScript 1.6.3
(function() {
  var Accessors, Manifest, ManifestError, debug, path, _, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  path = require('path');

  _ = require('underscore')._;

  debug = require('debug')('Manifest');

  Accessors = require('accessors');

  ManifestError = (function(_super) {
    __extends(ManifestError, _super);

    function ManifestError() {
      _ref = ManifestError.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return ManifestError;

  })(Error);

  Manifest = (function() {
    function Manifest(projectRoot, featurePath) {
      var m, manifestPath;
      this.projectRoot = projectRoot;
      this.featurePath = featurePath;
      manifestPath = path.join(this.getAbsolteDirectory(), 'Manifest');
      debug("requiring " + manifestPath);
      m = require(manifestPath);
      if (_(m).isEmpty()) {
        throw new ManifestError('Manifest is empty or has no module.exports');
      }
      _.extend(this, m);
    }

    Manifest.prototype.getAbsolteDirectory = function() {
      return path.join(this.projectRoot, this.featurePath);
    };

    Manifest.prototype.resolveRelativePath = function(relativePath) {
      var absolutePath;
      absolutePath = path.resolve(this.getAbsolteDirectory(), relativePath);
      return path.relative(this.projectRoot, absolutePath);
    };

    Manifest.prototype.replacePlaceholders = function(value) {
      var nodeModules;
      value = value.replace(/__PROJECT_ROOT__/g, this.projectRoot);
      nodeModules = path.join(this.projectRoot, 'node_modules');
      return value = value.replace(/__NODE_MODULES__/g, nodeModules);
    };

    Manifest.prototype.lookup = function(key) {
      var entry, value;
      value = Accessors.get(this, key);
      if (value != null) {
        if (_.isArray(value)) {
          return (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = value.length; _i < _len; _i++) {
              entry = value[_i];
              _results.push(this.replacePlaceholders(entry));
            }
            return _results;
          }).call(this);
        }
        return this.replacePlaceholders(value);
      } else {
        return void 0;
      }
    };

    Manifest.prototype.lookupPath = function(key) {
      var entry, value;
      value = this.lookup(key);
      if (value != null) {
        if (_.isArray(value)) {
          return (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = value.length; _i < _len; _i++) {
              entry = value[_i];
              _results.push(this.replacePlaceholders(this.resolveRelativePath(entry)));
            }
            return _results;
          }).call(this);
        }
        return this.replacePlaceholders(this.resolveRelativePath(value));
      } else {
        return void 0;
      }
    };

    return Manifest;

  })();

  module.exports = Manifest;

}).call(this);