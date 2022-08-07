import Foundation

// swiftlint:disable all

public extension ToolsPamphlet {
    #if DEBUG
    static func ToolsJs() -> String {
        let fileOnDiskPath = "/Users/rjbowli/Development/chimerasw/Pamphlet/Tools/Pamphlet/tools.js"
        if let contents = try? String(contentsOf:URL(fileURLWithPath: fileOnDiskPath)) {
            if contents.hasPrefix("#define PAMPHLET_PREPROCESSOR") {
                do {
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/pamphlet")
                    task.arguments = ["preprocess", fileOnDiskPath]
                    let outputPipe = Pipe()
                    task.standardOutput = outputPipe
                    try task.run()
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(decoding: outputData, as: UTF8.self)
                    return output
                } catch {
                    return "Failed to use /opt/homebrew/bin/pamphlet to preprocess the requested file"
                }
            }
            return contents
        }
        return String()
    }
    #else
    static func ToolsJs() -> StaticString {
        return uncompressedToolsJs
    }
    #endif
    static func ToolsJsGzip() -> Data {
        return compressedToolsJs
    }
}

private let uncompressedToolsJs: StaticString = ###"""
(function () {
  'use strict';

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  function characters(str) {
      return str.split("");
  }

  function member(name, array) {
      return array.includes(name);
  }

  class DefaultsError extends Error {
      constructor(msg, defs) {
          super();

          this.name = "DefaultsError";
          this.message = msg;
          this.defs = defs;
      }
  }

  function defaults(args, defs, croak) {
      if (args === true) {
          args = {};
      } else if (args != null && typeof args === "object") {
          args = {...args};
      }

      const ret = args || {};

      if (croak) for (const i in ret) if (HOP(ret, i) && !HOP(defs, i)) {
          throw new DefaultsError("`" + i + "` is not a supported option", defs);
      }

      for (const i in defs) if (HOP(defs, i)) {
          if (!args || !HOP(args, i)) {
              ret[i] = defs[i];
          } else if (i === "ecma") {
              let ecma = args[i] | 0;
              if (ecma > 5 && ecma < 2015) ecma += 2009;
              ret[i] = ecma;
          } else {
              ret[i] = (args && HOP(args, i)) ? args[i] : defs[i];
          }
      }

      return ret;
  }

  function noop() {}
  function return_false() { return false; }
  function return_true() { return true; }
  function return_this() { return this; }
  function return_null() { return null; }

  var MAP = (function() {
      function MAP(a, f, backwards) {
          var ret = [], top = [], i;
          function doit() {
              var val = f(a[i], i);
              var is_last = val instanceof Last;
              if (is_last) val = val.v;
              if (val instanceof AtTop) {
                  val = val.v;
                  if (val instanceof Splice) {
                      top.push.apply(top, backwards ? val.v.slice().reverse() : val.v);
                  } else {
                      top.push(val);
                  }
              } else if (val !== skip) {
                  if (val instanceof Splice) {
                      ret.push.apply(ret, backwards ? val.v.slice().reverse() : val.v);
                  } else {
                      ret.push(val);
                  }
              }
              return is_last;
          }
          if (Array.isArray(a)) {
              if (backwards) {
                  for (i = a.length; --i >= 0;) if (doit()) break;
                  ret.reverse();
                  top.reverse();
              } else {
                  for (i = 0; i < a.length; ++i) if (doit()) break;
              }
          } else {
              for (i in a) if (HOP(a, i)) if (doit()) break;
          }
          return top.concat(ret);
      }
      MAP.at_top = function(val) { return new AtTop(val); };
      MAP.splice = function(val) { return new Splice(val); };
      MAP.last = function(val) { return new Last(val); };
      var skip = MAP.skip = {};
      function AtTop(val) { this.v = val; }
      function Splice(val) { this.v = val; }
      function Last(val) { this.v = val; }
      return MAP;
  })();

  function make_node(ctor, orig, props) {
      if (!props) props = {};
      if (orig) {
          if (!props.start) props.start = orig.start;
          if (!props.end) props.end = orig.end;
      }
      return new ctor(props);
  }

  function push_uniq(array, el) {
      if (!array.includes(el))
          array.push(el);
  }

  function string_template(text, props) {
      return text.replace(/{(.+?)}/g, function(str, p) {
          return props && props[p];
      });
  }

  function remove(array, el) {
      for (var i = array.length; --i >= 0;) {
          if (array[i] === el) array.splice(i, 1);
      }
  }

  function mergeSort(array, cmp) {
      if (array.length < 2) return array.slice();
      function merge(a, b) {
          var r = [], ai = 0, bi = 0, i = 0;
          while (ai < a.length && bi < b.length) {
              cmp(a[ai], b[bi]) <= 0
                  ? r[i++] = a[ai++]
                  : r[i++] = b[bi++];
          }
          if (ai < a.length) r.push.apply(r, a.slice(ai));
          if (bi < b.length) r.push.apply(r, b.slice(bi));
          return r;
      }
      function _ms(a) {
          if (a.length <= 1)
              return a;
          var m = Math.floor(a.length / 2), left = a.slice(0, m), right = a.slice(m);
          left = _ms(left);
          right = _ms(right);
          return merge(left, right);
      }
      return _ms(array);
  }

  function makePredicate(words) {
      if (!Array.isArray(words)) words = words.split(" ");

      return new Set(words.sort());
  }

  function map_add(map, key, value) {
      if (map.has(key)) {
          map.get(key).push(value);
      } else {
          map.set(key, [ value ]);
      }
  }

  function HOP(obj, prop) {
      return Object.prototype.hasOwnProperty.call(obj, prop);
  }

  function keep_name(keep_setting, name) {
      return keep_setting === true
          || (keep_setting instanceof RegExp && keep_setting.test(name));
  }

  var lineTerminatorEscape = {
      "\0": "0",
      "\n": "n",
      "\r": "r",
      "\u2028": "u2028",
      "\u2029": "u2029",
  };
  function regexp_source_fix(source) {
      // V8 does not escape line terminators in regexp patterns in node 12
      // We'll also remove literal \0
      return source.replace(/[\0\n\r\u2028\u2029]/g, function (match, offset) {
          var escaped = source[offset - 1] == "\\"
              && (source[offset - 2] != "\\"
              || /(?:^|[^\\])(?:\\{2})*$/.test(source.slice(0, offset - 1)));
          return (escaped ? "" : "\\") + lineTerminatorEscape[match];
      });
  }

  // Subset of regexps that is not going to cause regexp based DDOS
  // https://owasp.org/www-community/attacks/Regular_expression_Denial_of_Service_-_ReDoS
  const re_safe_regexp = /^[\\/|\0\s\w^$.[\]()]*$/;

  /** Check if the regexp is safe for Terser to create without risking a RegExp DOS */
  const regexp_is_safe = (source) => re_safe_regexp.test(source);

  const all_flags = "dgimsuy";
  function sort_regexp_flags(flags) {
      const existing_flags = new Set(flags.split(""));
      let out = "";
      for (const flag of all_flags) {
          if (existing_flags.has(flag)) {
              out += flag;
              existing_flags.delete(flag);
          }
      }
      if (existing_flags.size) {
          // Flags Terser doesn't know about
          existing_flags.forEach(flag => { out += flag; });
      }
      return out;
  }

  function has_annotation(node, annotation) {
      return node._annotations & annotation;
  }

  function set_annotation(node, annotation) {
      node._annotations |= annotation;
  }

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>
      Parser based on parse-js (http://marijn.haverbeke.nl/parse-js/).

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  var LATEST_RAW = "";  // Only used for numbers and template strings
  var TEMPLATE_RAWS = new Map();  // Raw template strings

  var KEYWORDS = "break case catch class const continue debugger default delete do else export extends finally for function if in instanceof let new return switch throw try typeof var void while with";
  var KEYWORDS_ATOM = "false null true";
  var RESERVED_WORDS = "enum import super this " + KEYWORDS_ATOM + " " + KEYWORDS;
  var ALL_RESERVED_WORDS = "implements interface package private protected public static " + RESERVED_WORDS;
  var KEYWORDS_BEFORE_EXPRESSION = "return new delete throw else case yield await";

  KEYWORDS = makePredicate(KEYWORDS);
  RESERVED_WORDS = makePredicate(RESERVED_WORDS);
  KEYWORDS_BEFORE_EXPRESSION = makePredicate(KEYWORDS_BEFORE_EXPRESSION);
  KEYWORDS_ATOM = makePredicate(KEYWORDS_ATOM);
  ALL_RESERVED_WORDS = makePredicate(ALL_RESERVED_WORDS);

  var OPERATOR_CHARS = makePredicate(characters("+-*&%=<>!?|~^"));

  var RE_NUM_LITERAL = /[0-9a-f]/i;
  var RE_HEX_NUMBER = /^0x[0-9a-f]+$/i;
  var RE_OCT_NUMBER = /^0[0-7]+$/;
  var RE_ES6_OCT_NUMBER = /^0o[0-7]+$/i;
  var RE_BIN_NUMBER = /^0b[01]+$/i;
  var RE_DEC_NUMBER = /^\d*\.?\d*(?:e[+-]?\d*(?:\d\.?|\.?\d)\d*)?$/i;
  var RE_BIG_INT = /^(0[xob])?[0-9a-f]+n$/i;

  var OPERATORS = makePredicate([
      "in",
      "instanceof",
      "typeof",
      "new",
      "void",
      "delete",
      "++",
      "--",
      "+",
      "-",
      "!",
      "~",
      "&",
      "|",
      "^",
      "*",
      "**",
      "/",
      "%",
      ">>",
      "<<",
      ">>>",
      "<",
      ">",
      "<=",
      ">=",
      "==",
      "===",
      "!=",
      "!==",
      "?",
      "=",
      "+=",
      "-=",
      "||=",
      "&&=",
      "??=",
      "/=",
      "*=",
      "**=",
      "%=",
      ">>=",
      "<<=",
      ">>>=",
      "|=",
      "^=",
      "&=",
      "&&",
      "??",
      "||",
  ]);

  var WHITESPACE_CHARS = makePredicate(characters(" \u00a0\n\r\t\f\u000b\u200b\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u2028\u2029\u202f\u205f\u3000\uFEFF"));

  var NEWLINE_CHARS = makePredicate(characters("\n\r\u2028\u2029"));

  var PUNC_AFTER_EXPRESSION = makePredicate(characters(";]),:"));

  var PUNC_BEFORE_EXPRESSION = makePredicate(characters("[{(,;:"));

  var PUNC_CHARS = makePredicate(characters("[]{}(),;:"));

  /* -----[ Tokenizer ]----- */

  // surrogate safe regexps adapted from https://github.com/mathiasbynens/unicode-8.0.0/tree/89b412d8a71ecca9ed593d9e9fa073ab64acfebe/Binary_Property
  var UNICODE = {
      ID_Start: /[$A-Z_a-z\xAA\xB5\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0370-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u048A-\u052F\u0531-\u0556\u0559\u0561-\u0587\u05D0-\u05EA\u05F0-\u05F2\u0620-\u064A\u066E\u066F\u0671-\u06D3\u06D5\u06E5\u06E6\u06EE\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u07F4\u07F5\u07FA\u0800-\u0815\u081A\u0824\u0828\u0840-\u0858\u08A0-\u08B4\u0904-\u0939\u093D\u0950\u0958-\u0961\u0971-\u0980\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC\u09DD\u09DF-\u09E1\u09F0\u09F1\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0\u0AE1\u0AF9\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3D\u0B5C\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58-\u0C5A\u0C60\u0C61\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDE\u0CE0\u0CE1\u0CF1\u0CF2\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D5F-\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32\u0E33\u0E40-\u0E46\u0E81\u0E82\u0E84\u0E87\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA\u0EAB\u0EAD-\u0EB0\u0EB2\u0EB3\u0EBD\u0EC0-\u0EC4\u0EC6\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065\u1066\u106E-\u1070\u1075-\u1081\u108E\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u13A0-\u13F5\u13F8-\u13FD\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16EE-\u16F8\u1700-\u170C\u170E-\u1711\u1720-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17D7\u17DC\u1820-\u1877\u1880-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u1A00-\u1A16\u1A20-\u1A54\u1AA7\u1B05-\u1B33\u1B45-\u1B4B\u1B83-\u1BA0\u1BAE\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C7D\u1CE9-\u1CEC\u1CEE-\u1CF1\u1CF5\u1CF6\u1D00-\u1DBF\u1E00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u2071\u207F\u2090-\u209C\u2102\u2107\u210A-\u2113\u2115\u2118-\u211D\u2124\u2126\u2128\u212A-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2160-\u2188\u2C00-\u2C2E\u2C30-\u2C5E\u2C60-\u2CE4\u2CEB-\u2CEE\u2CF2\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u3005-\u3007\u3021-\u3029\u3031-\u3035\u3038-\u303C\u3041-\u3096\u309B-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312D\u3131-\u318E\u31A0-\u31BA\u31F0-\u31FF\u3400-\u4DB5\u4E00-\u9FD5\uA000-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA61F\uA62A\uA62B\uA640-\uA66E\uA67F-\uA69D\uA6A0-\uA6EF\uA717-\uA71F\uA722-\uA788\uA78B-\uA7AD\uA7B0-\uA7B7\uA7F7-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA8FD\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9CF\uA9E0-\uA9E4\uA9E6-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADD\uAAE0-\uAAEA\uAAF2-\uAAF4\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB65\uAB70-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF21-\uFF3A\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]|\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA\uDD40-\uDD74\uDE80-\uDE9C\uDEA0-\uDED0\uDF00-\uDF1F\uDF30-\uDF4A\uDF50-\uDF75\uDF80-\uDF9D\uDFA0-\uDFC3\uDFC8-\uDFCF\uDFD1-\uDFD5]|\uD801[\uDC00-\uDC9D\uDD00-\uDD27\uDD30-\uDD63\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67]|\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F-\uDC55\uDC60-\uDC76\uDC80-\uDC9E\uDCE0-\uDCF2\uDCF4\uDCF5\uDD00-\uDD15\uDD20-\uDD39\uDD80-\uDDB7\uDDBE\uDDBF\uDE00\uDE10-\uDE13\uDE15-\uDE17\uDE19-\uDE33\uDE60-\uDE7C\uDE80-\uDE9C\uDEC0-\uDEC7\uDEC9-\uDEE4\uDF00-\uDF35\uDF40-\uDF55\uDF60-\uDF72\uDF80-\uDF91]|\uD803[\uDC00-\uDC48\uDC80-\uDCB2\uDCC0-\uDCF2]|\uD804[\uDC03-\uDC37\uDC83-\uDCAF\uDCD0-\uDCE8\uDD03-\uDD26\uDD50-\uDD72\uDD76\uDD83-\uDDB2\uDDC1-\uDDC4\uDDDA\uDDDC\uDE00-\uDE11\uDE13-\uDE2B\uDE80-\uDE86\uDE88\uDE8A-\uDE8D\uDE8F-\uDE9D\uDE9F-\uDEA8\uDEB0-\uDEDE\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3D\uDF50\uDF5D-\uDF61]|\uD805[\uDC80-\uDCAF\uDCC4\uDCC5\uDCC7\uDD80-\uDDAE\uDDD8-\uDDDB\uDE00-\uDE2F\uDE44\uDE80-\uDEAA\uDF00-\uDF19]|\uD806[\uDCA0-\uDCDF\uDCFF\uDEC0-\uDEF8]|\uD808[\uDC00-\uDF99]|\uD809[\uDC00-\uDC6E\uDC80-\uDD43]|[\uD80C\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872][\uDC00-\uDFFF]|\uD80D[\uDC00-\uDC2E]|\uD811[\uDC00-\uDE46]|\uD81A[\uDC00-\uDE38\uDE40-\uDE5E\uDED0-\uDEED\uDF00-\uDF2F\uDF40-\uDF43\uDF63-\uDF77\uDF7D-\uDF8F]|\uD81B[\uDF00-\uDF44\uDF50\uDF93-\uDF9F]|\uD82C[\uDC00\uDC01]|\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDEC0\uDEC2-\uDEDA\uDEDC-\uDEFA\uDEFC-\uDF14\uDF16-\uDF34\uDF36-\uDF4E\uDF50-\uDF6E\uDF70-\uDF88\uDF8A-\uDFA8\uDFAA-\uDFC2\uDFC4-\uDFCB]|\uD83A[\uDC00-\uDCC4]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB]|\uD869[\uDC00-\uDED6\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF34\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|\uD873[\uDC00-\uDEA1]|\uD87E[\uDC00-\uDE1D]/,
      ID_Continue: /(?:[$0-9A-Z_a-z\xAA\xB5\xB7\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0300-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u0483-\u0487\u048A-\u052F\u0531-\u0556\u0559\u0561-\u0587\u0591-\u05BD\u05BF\u05C1\u05C2\u05C4\u05C5\u05C7\u05D0-\u05EA\u05F0-\u05F2\u0610-\u061A\u0620-\u0669\u066E-\u06D3\u06D5-\u06DC\u06DF-\u06E8\u06EA-\u06FC\u06FF\u0710-\u074A\u074D-\u07B1\u07C0-\u07F5\u07FA\u0800-\u082D\u0840-\u085B\u08A0-\u08B4\u08E3-\u0963\u0966-\u096F\u0971-\u0983\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BC-\u09C4\u09C7\u09C8\u09CB-\u09CE\u09D7\u09DC\u09DD\u09DF-\u09E3\u09E6-\u09F1\u0A01-\u0A03\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A3C\u0A3E-\u0A42\u0A47\u0A48\u0A4B-\u0A4D\u0A51\u0A59-\u0A5C\u0A5E\u0A66-\u0A75\u0A81-\u0A83\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABC-\u0AC5\u0AC7-\u0AC9\u0ACB-\u0ACD\u0AD0\u0AE0-\u0AE3\u0AE6-\u0AEF\u0AF9\u0B01-\u0B03\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3C-\u0B44\u0B47\u0B48\u0B4B-\u0B4D\u0B56\u0B57\u0B5C\u0B5D\u0B5F-\u0B63\u0B66-\u0B6F\u0B71\u0B82\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BBE-\u0BC2\u0BC6-\u0BC8\u0BCA-\u0BCD\u0BD0\u0BD7\u0BE6-\u0BEF\u0C00-\u0C03\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D-\u0C44\u0C46-\u0C48\u0C4A-\u0C4D\u0C55\u0C56\u0C58-\u0C5A\u0C60-\u0C63\u0C66-\u0C6F\u0C81-\u0C83\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBC-\u0CC4\u0CC6-\u0CC8\u0CCA-\u0CCD\u0CD5\u0CD6\u0CDE\u0CE0-\u0CE3\u0CE6-\u0CEF\u0CF1\u0CF2\u0D01-\u0D03\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D-\u0D44\u0D46-\u0D48\u0D4A-\u0D4E\u0D57\u0D5F-\u0D63\u0D66-\u0D6F\u0D7A-\u0D7F\u0D82\u0D83\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0DCA\u0DCF-\u0DD4\u0DD6\u0DD8-\u0DDF\u0DE6-\u0DEF\u0DF2\u0DF3\u0E01-\u0E3A\u0E40-\u0E4E\u0E50-\u0E59\u0E81\u0E82\u0E84\u0E87\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA\u0EAB\u0EAD-\u0EB9\u0EBB-\u0EBD\u0EC0-\u0EC4\u0EC6\u0EC8-\u0ECD\u0ED0-\u0ED9\u0EDC-\u0EDF\u0F00\u0F18\u0F19\u0F20-\u0F29\u0F35\u0F37\u0F39\u0F3E-\u0F47\u0F49-\u0F6C\u0F71-\u0F84\u0F86-\u0F97\u0F99-\u0FBC\u0FC6\u1000-\u1049\u1050-\u109D\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u135D-\u135F\u1369-\u1371\u1380-\u138F\u13A0-\u13F5\u13F8-\u13FD\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16EE-\u16F8\u1700-\u170C\u170E-\u1714\u1720-\u1734\u1740-\u1753\u1760-\u176C\u176E-\u1770\u1772\u1773\u1780-\u17D3\u17D7\u17DC\u17DD\u17E0-\u17E9\u180B-\u180D\u1810-\u1819\u1820-\u1877\u1880-\u18AA\u18B0-\u18F5\u1900-\u191E\u1920-\u192B\u1930-\u193B\u1946-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u19D0-\u19DA\u1A00-\u1A1B\u1A20-\u1A5E\u1A60-\u1A7C\u1A7F-\u1A89\u1A90-\u1A99\u1AA7\u1AB0-\u1ABD\u1B00-\u1B4B\u1B50-\u1B59\u1B6B-\u1B73\u1B80-\u1BF3\u1C00-\u1C37\u1C40-\u1C49\u1C4D-\u1C7D\u1CD0-\u1CD2\u1CD4-\u1CF6\u1CF8\u1CF9\u1D00-\u1DF5\u1DFC-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u200C\u200D\u203F\u2040\u2054\u2071\u207F\u2090-\u209C\u20D0-\u20DC\u20E1\u20E5-\u20F0\u2102\u2107\u210A-\u2113\u2115\u2118-\u211D\u2124\u2126\u2128\u212A-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2160-\u2188\u2C00-\u2C2E\u2C30-\u2C5E\u2C60-\u2CE4\u2CEB-\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D7F-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u2DE0-\u2DFF\u3005-\u3007\u3021-\u302F\u3031-\u3035\u3038-\u303C\u3041-\u3096\u3099-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312D\u3131-\u318E\u31A0-\u31BA\u31F0-\u31FF\u3400-\u4DB5\u4E00-\u9FD5\uA000-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA62B\uA640-\uA66F\uA674-\uA67D\uA67F-\uA6F1\uA717-\uA71F\uA722-\uA788\uA78B-\uA7AD\uA7B0-\uA7B7\uA7F7-\uA827\uA840-\uA873\uA880-\uA8C4\uA8D0-\uA8D9\uA8E0-\uA8F7\uA8FB\uA8FD\uA900-\uA92D\uA930-\uA953\uA960-\uA97C\uA980-\uA9C0\uA9CF-\uA9D9\uA9E0-\uA9FE\uAA00-\uAA36\uAA40-\uAA4D\uAA50-\uAA59\uAA60-\uAA76\uAA7A-\uAAC2\uAADB-\uAADD\uAAE0-\uAAEF\uAAF2-\uAAF6\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB65\uAB70-\uABEA\uABEC\uABED\uABF0-\uABF9\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE00-\uFE0F\uFE20-\uFE2F\uFE33\uFE34\uFE4D-\uFE4F\uFE70-\uFE74\uFE76-\uFEFC\uFF10-\uFF19\uFF21-\uFF3A\uFF3F\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]|\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA\uDD40-\uDD74\uDDFD\uDE80-\uDE9C\uDEA0-\uDED0\uDEE0\uDF00-\uDF1F\uDF30-\uDF4A\uDF50-\uDF7A\uDF80-\uDF9D\uDFA0-\uDFC3\uDFC8-\uDFCF\uDFD1-\uDFD5]|\uD801[\uDC00-\uDC9D\uDCA0-\uDCA9\uDD00-\uDD27\uDD30-\uDD63\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67]|\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F-\uDC55\uDC60-\uDC76\uDC80-\uDC9E\uDCE0-\uDCF2\uDCF4\uDCF5\uDD00-\uDD15\uDD20-\uDD39\uDD80-\uDDB7\uDDBE\uDDBF\uDE00-\uDE03\uDE05\uDE06\uDE0C-\uDE13\uDE15-\uDE17\uDE19-\uDE33\uDE38-\uDE3A\uDE3F\uDE60-\uDE7C\uDE80-\uDE9C\uDEC0-\uDEC7\uDEC9-\uDEE6\uDF00-\uDF35\uDF40-\uDF55\uDF60-\uDF72\uDF80-\uDF91]|\uD803[\uDC00-\uDC48\uDC80-\uDCB2\uDCC0-\uDCF2]|\uD804[\uDC00-\uDC46\uDC66-\uDC6F\uDC7F-\uDCBA\uDCD0-\uDCE8\uDCF0-\uDCF9\uDD00-\uDD34\uDD36-\uDD3F\uDD50-\uDD73\uDD76\uDD80-\uDDC4\uDDCA-\uDDCC\uDDD0-\uDDDA\uDDDC\uDE00-\uDE11\uDE13-\uDE37\uDE80-\uDE86\uDE88\uDE8A-\uDE8D\uDE8F-\uDE9D\uDE9F-\uDEA8\uDEB0-\uDEEA\uDEF0-\uDEF9\uDF00-\uDF03\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3C-\uDF44\uDF47\uDF48\uDF4B-\uDF4D\uDF50\uDF57\uDF5D-\uDF63\uDF66-\uDF6C\uDF70-\uDF74]|\uD805[\uDC80-\uDCC5\uDCC7\uDCD0-\uDCD9\uDD80-\uDDB5\uDDB8-\uDDC0\uDDD8-\uDDDD\uDE00-\uDE40\uDE44\uDE50-\uDE59\uDE80-\uDEB7\uDEC0-\uDEC9\uDF00-\uDF19\uDF1D-\uDF2B\uDF30-\uDF39]|\uD806[\uDCA0-\uDCE9\uDCFF\uDEC0-\uDEF8]|\uD808[\uDC00-\uDF99]|\uD809[\uDC00-\uDC6E\uDC80-\uDD43]|[\uD80C\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872][\uDC00-\uDFFF]|\uD80D[\uDC00-\uDC2E]|\uD811[\uDC00-\uDE46]|\uD81A[\uDC00-\uDE38\uDE40-\uDE5E\uDE60-\uDE69\uDED0-\uDEED\uDEF0-\uDEF4\uDF00-\uDF36\uDF40-\uDF43\uDF50-\uDF59\uDF63-\uDF77\uDF7D-\uDF8F]|\uD81B[\uDF00-\uDF44\uDF50-\uDF7E\uDF8F-\uDF9F]|\uD82C[\uDC00\uDC01]|\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99\uDC9D\uDC9E]|\uD834[\uDD65-\uDD69\uDD6D-\uDD72\uDD7B-\uDD82\uDD85-\uDD8B\uDDAA-\uDDAD\uDE42-\uDE44]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDEC0\uDEC2-\uDEDA\uDEDC-\uDEFA\uDEFC-\uDF14\uDF16-\uDF34\uDF36-\uDF4E\uDF50-\uDF6E\uDF70-\uDF88\uDF8A-\uDFA8\uDFAA-\uDFC2\uDFC4-\uDFCB\uDFCE-\uDFFF]|\uD836[\uDE00-\uDE36\uDE3B-\uDE6C\uDE75\uDE84\uDE9B-\uDE9F\uDEA1-\uDEAF]|\uD83A[\uDC00-\uDCC4\uDCD0-\uDCD6]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB]|\uD869[\uDC00-\uDED6\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF34\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|\uD873[\uDC00-\uDEA1]|\uD87E[\uDC00-\uDE1D]|\uDB40[\uDD00-\uDDEF])+/,
  };

  function get_full_char(str, pos) {
      if (is_surrogate_pair_head(str.charCodeAt(pos))) {
          if (is_surrogate_pair_tail(str.charCodeAt(pos + 1))) {
              return str.charAt(pos) + str.charAt(pos + 1);
          }
      } else if (is_surrogate_pair_tail(str.charCodeAt(pos))) {
          if (is_surrogate_pair_head(str.charCodeAt(pos - 1))) {
              return str.charAt(pos - 1) + str.charAt(pos);
          }
      }
      return str.charAt(pos);
  }

  function get_full_char_code(str, pos) {
      // https://en.wikipedia.org/wiki/Universal_Character_Set_characters#Surrogates
      if (is_surrogate_pair_head(str.charCodeAt(pos))) {
          return 0x10000 + (str.charCodeAt(pos) - 0xd800 << 10) + str.charCodeAt(pos + 1) - 0xdc00;
      }
      return str.charCodeAt(pos);
  }

  function get_full_char_length(str) {
      var surrogates = 0;

      for (var i = 0; i < str.length; i++) {
          if (is_surrogate_pair_head(str.charCodeAt(i)) && is_surrogate_pair_tail(str.charCodeAt(i + 1))) {
              surrogates++;
              i++;
          }
      }

      return str.length - surrogates;
  }

  function from_char_code(code) {
      // Based on https://github.com/mathiasbynens/String.fromCodePoint/blob/master/fromcodepoint.js
      if (code > 0xFFFF) {
          code -= 0x10000;
          return (String.fromCharCode((code >> 10) + 0xD800) +
              String.fromCharCode((code % 0x400) + 0xDC00));
      }
      return String.fromCharCode(code);
  }

  function is_surrogate_pair_head(code) {
      return code >= 0xd800 && code <= 0xdbff;
  }

  function is_surrogate_pair_tail(code) {
      return code >= 0xdc00 && code <= 0xdfff;
  }

  function is_digit(code) {
      return code >= 48 && code <= 57;
  }

  function is_identifier_start(ch) {
      return UNICODE.ID_Start.test(ch);
  }

  function is_identifier_char(ch) {
      return UNICODE.ID_Continue.test(ch);
  }

  const BASIC_IDENT = /^[a-z_$][a-z0-9_$]*$/i;

  function is_basic_identifier_string(str) {
      return BASIC_IDENT.test(str);
  }

  function is_identifier_string(str, allow_surrogates) {
      if (BASIC_IDENT.test(str)) {
          return true;
      }
      if (!allow_surrogates && /[\ud800-\udfff]/.test(str)) {
          return false;
      }
      var match = UNICODE.ID_Start.exec(str);
      if (!match || match.index !== 0) {
          return false;
      }

      str = str.slice(match[0].length);
      if (!str) {
          return true;
      }

      match = UNICODE.ID_Continue.exec(str);
      return !!match && match[0].length === str.length;
  }

  function parse_js_number(num, allow_e = true) {
      if (!allow_e && num.includes("e")) {
          return NaN;
      }
      if (RE_HEX_NUMBER.test(num)) {
          return parseInt(num.substr(2), 16);
      } else if (RE_OCT_NUMBER.test(num)) {
          return parseInt(num.substr(1), 8);
      } else if (RE_ES6_OCT_NUMBER.test(num)) {
          return parseInt(num.substr(2), 8);
      } else if (RE_BIN_NUMBER.test(num)) {
          return parseInt(num.substr(2), 2);
      } else if (RE_DEC_NUMBER.test(num)) {
          return parseFloat(num);
      } else {
          var val = parseFloat(num);
          if (val == num) return val;
      }
  }

  class JS_Parse_Error extends Error {
      constructor(message, filename, line, col, pos) {
          super();

          this.name = "SyntaxError";
          this.message = message;
          this.filename = filename;
          this.line = line;
          this.col = col;
          this.pos = pos;
      }
  }

  function js_error(message, filename, line, col, pos) {
      throw new JS_Parse_Error(message, filename, line, col, pos);
  }

  function is_token(token, type, val) {
      return token.type == type && (val == null || token.value == val);
  }

  var EX_EOF = {};

  function tokenizer($TEXT, filename, html5_comments, shebang) {
      var S = {
          text            : $TEXT,
          filename        : filename,
          pos             : 0,
          tokpos          : 0,
          line            : 1,
          tokline         : 0,
          col             : 0,
          tokcol          : 0,
          newline_before  : false,
          regex_allowed   : false,
          brace_counter   : 0,
          template_braces : [],
          comments_before : [],
          directives      : {},
          directive_stack : []
      };

      function peek() { return get_full_char(S.text, S.pos); }

      // Used because parsing ?. involves a lookahead for a digit
      function is_option_chain_op() {
          const must_be_dot = S.text.charCodeAt(S.pos + 1) === 46;
          if (!must_be_dot) return false;

          const cannot_be_digit = S.text.charCodeAt(S.pos + 2);
          return cannot_be_digit < 48 || cannot_be_digit > 57;
      }

      function next(signal_eof, in_string) {
          var ch = get_full_char(S.text, S.pos++);
          if (signal_eof && !ch)
              throw EX_EOF;
          if (NEWLINE_CHARS.has(ch)) {
              S.newline_before = S.newline_before || !in_string;
              ++S.line;
              S.col = 0;
              if (ch == "\r" && peek() == "\n") {
                  // treat a \r\n sequence as a single \n
                  ++S.pos;
                  ch = "\n";
              }
          } else {
              if (ch.length > 1) {
                  ++S.pos;
                  ++S.col;
              }
              ++S.col;
          }
          return ch;
      }

      function forward(i) {
          while (i--) next();
      }

      function looking_at(str) {
          return S.text.substr(S.pos, str.length) == str;
      }

      function find_eol() {
          var text = S.text;
          for (var i = S.pos, n = S.text.length; i < n; ++i) {
              var ch = text[i];
              if (NEWLINE_CHARS.has(ch))
                  return i;
          }
          return -1;
      }

      function find(what, signal_eof) {
          var pos = S.text.indexOf(what, S.pos);
          if (signal_eof && pos == -1) throw EX_EOF;
          return pos;
      }

      function start_token() {
          S.tokline = S.line;
          S.tokcol = S.col;
          S.tokpos = S.pos;
      }

      var prev_was_dot = false;
      var previous_token = null;
      function token(type, value, is_comment) {
          S.regex_allowed = ((type == "operator" && !UNARY_POSTFIX.has(value)) ||
                             (type == "keyword" && KEYWORDS_BEFORE_EXPRESSION.has(value)) ||
                             (type == "punc" && PUNC_BEFORE_EXPRESSION.has(value))) ||
                             (type == "arrow");
          if (type == "punc" && (value == "." || value == "?.")) {
              prev_was_dot = true;
          } else if (!is_comment) {
              prev_was_dot = false;
          }
          const line     = S.tokline;
          const col      = S.tokcol;
          const pos      = S.tokpos;
          const nlb      = S.newline_before;
          const file     = filename;
          let comments_before = [];
          let comments_after  = [];

          if (!is_comment) {
              comments_before = S.comments_before;
              comments_after = S.comments_before = [];
          }
          S.newline_before = false;
          const tok = new AST_Token(type, value, line, col, pos, nlb, comments_before, comments_after, file);

          if (!is_comment) previous_token = tok;
          return tok;
      }

      function skip_whitespace() {
          while (WHITESPACE_CHARS.has(peek()))
              next();
      }

      function read_while(pred) {
          var ret = "", ch, i = 0;
          while ((ch = peek()) && pred(ch, i++))
              ret += next();
          return ret;
      }

      function parse_error(err) {
          js_error(err, filename, S.tokline, S.tokcol, S.tokpos);
      }

      function read_num(prefix) {
          var has_e = false, after_e = false, has_x = false, has_dot = prefix == ".", is_big_int = false, numeric_separator = false;
          var num = read_while(function(ch, i) {
              if (is_big_int) return false;

              var code = ch.charCodeAt(0);
              switch (code) {
                case 95: // _
                  return (numeric_separator = true);
                case 98: case 66: // bB
                  return (has_x = true); // Can occur in hex sequence, don't return false yet
                case 111: case 79: // oO
                case 120: case 88: // xX
                  return has_x ? false : (has_x = true);
                case 101: case 69: // eE
                  return has_x ? true : has_e ? false : (has_e = after_e = true);
                case 45: // -
                  return after_e || (i == 0 && !prefix);
                case 43: // +
                  return after_e;
                case (after_e = false, 46): // .
                  return (!has_dot && !has_x && !has_e) ? (has_dot = true) : false;
              }

              if (ch === "n") {
                  is_big_int = true;

                  return true;
              }

              return RE_NUM_LITERAL.test(ch);
          });
          if (prefix) num = prefix + num;

          LATEST_RAW = num;

          if (RE_OCT_NUMBER.test(num) && next_token.has_directive("use strict")) {
              parse_error("Legacy octal literals are not allowed in strict mode");
          }
          if (numeric_separator) {
              if (num.endsWith("_")) {
                  parse_error("Numeric separators are not allowed at the end of numeric literals");
              } else if (num.includes("__")) {
                  parse_error("Only one underscore is allowed as numeric separator");
              }
              num = num.replace(/_/g, "");
          }
          if (num.endsWith("n")) {
              const without_n = num.slice(0, -1);
              const allow_e = RE_HEX_NUMBER.test(without_n);
              const valid = parse_js_number(without_n, allow_e);
              if (!has_dot && RE_BIG_INT.test(num) && !isNaN(valid))
                  return token("big_int", without_n);
              parse_error("Invalid or unexpected token");
          }
          var valid = parse_js_number(num);
          if (!isNaN(valid)) {
              return token("num", valid);
          } else {
              parse_error("Invalid syntax: " + num);
          }
      }

      function is_octal(ch) {
          return ch >= "0" && ch <= "7";
      }

      function read_escaped_char(in_string, strict_hex, template_string) {
          var ch = next(true, in_string);
          switch (ch.charCodeAt(0)) {
            case 110 : return "\n";
            case 114 : return "\r";
            case 116 : return "\t";
            case 98  : return "\b";
            case 118 : return "\u000b"; // \v
            case 102 : return "\f";
            case 120 : return String.fromCharCode(hex_bytes(2, strict_hex)); // \x
            case 117 : // \u
              if (peek() == "{") {
                  next(true);
                  if (peek() === "}")
                      parse_error("Expecting hex-character between {}");
                  while (peek() == "0") next(true); // No significance
                  var result, length = find("}", true) - S.pos;
                  // Avoid 32 bit integer overflow (1 << 32 === 1)
                  // We know first character isn't 0 and thus out of range anyway
                  if (length > 6 || (result = hex_bytes(length, strict_hex)) > 0x10FFFF) {
                      parse_error("Unicode reference out of bounds");
                  }
                  next(true);
                  return from_char_code(result);
              }
              return String.fromCharCode(hex_bytes(4, strict_hex));
            case 10  : return ""; // newline
            case 13  :            // \r
              if (peek() == "\n") { // DOS newline
                  next(true, in_string);
                  return "";
              }
          }
          if (is_octal(ch)) {
              if (template_string && strict_hex) {
                  const represents_null_character = ch === "0" && !is_octal(peek());
                  if (!represents_null_character) {
                      parse_error("Octal escape sequences are not allowed in template strings");
                  }
              }
              return read_octal_escape_sequence(ch, strict_hex);
          }
          return ch;
      }

      function read_octal_escape_sequence(ch, strict_octal) {
          // Read
          var p = peek();
          if (p >= "0" && p <= "7") {
              ch += next(true);
              if (ch[0] <= "3" && (p = peek()) >= "0" && p <= "7")
                  ch += next(true);
          }

          // Parse
          if (ch === "0") return "\0";
          if (ch.length > 0 && next_token.has_directive("use strict") && strict_octal)
              parse_error("Legacy octal escape sequences are not allowed in strict mode");
          return String.fromCharCode(parseInt(ch, 8));
      }

      function hex_bytes(n, strict_hex) {
          var num = 0;
          for (; n > 0; --n) {
              if (!strict_hex && isNaN(parseInt(peek(), 16))) {
                  return parseInt(num, 16) || "";
              }
              var digit = next(true);
              if (isNaN(parseInt(digit, 16)))
                  parse_error("Invalid hex-character pattern in string");
              num += digit;
          }
          return parseInt(num, 16);
      }

      var read_string = with_eof_error("Unterminated string constant", function() {
          const start_pos = S.pos;
          var quote = next(), ret = [];
          for (;;) {
              var ch = next(true, true);
              if (ch == "\\") ch = read_escaped_char(true, true);
              else if (ch == "\r" || ch == "\n") parse_error("Unterminated string constant");
              else if (ch == quote) break;
              ret.push(ch);
          }
          var tok = token("string", ret.join(""));
          LATEST_RAW = S.text.slice(start_pos, S.pos);
          tok.quote = quote;
          return tok;
      });

      var read_template_characters = with_eof_error("Unterminated template", function(begin) {
          if (begin) {
              S.template_braces.push(S.brace_counter);
          }
          var content = "", raw = "", ch, tok;
          next(true, true);
          while ((ch = next(true, true)) != "`") {
              if (ch == "\r") {
                  if (peek() == "\n") ++S.pos;
                  ch = "\n";
              } else if (ch == "$" && peek() == "{") {
                  next(true, true);
                  S.brace_counter++;
                  tok = token(begin ? "template_head" : "template_substitution", content);
                  TEMPLATE_RAWS.set(tok, raw);
                  tok.template_end = false;
                  return tok;
              }

              raw += ch;
              if (ch == "\\") {
                  var tmp = S.pos;
                  var prev_is_tag = previous_token && (previous_token.type === "name" || previous_token.type === "punc" && (previous_token.value === ")" || previous_token.value === "]"));
                  ch = read_escaped_char(true, !prev_is_tag, true);
                  raw += S.text.substr(tmp, S.pos - tmp);
              }

              content += ch;
          }
          S.template_braces.pop();
          tok = token(begin ? "template_head" : "template_substitution", content);
          TEMPLATE_RAWS.set(tok, raw);
          tok.template_end = true;
          return tok;
      });

      function skip_line_comment(type) {
          var regex_allowed = S.regex_allowed;
          var i = find_eol(), ret;
          if (i == -1) {
              ret = S.text.substr(S.pos);
              S.pos = S.text.length;
          } else {
              ret = S.text.substring(S.pos, i);
              S.pos = i;
          }
          S.col = S.tokcol + (S.pos - S.tokpos);
          S.comments_before.push(token(type, ret, true));
          S.regex_allowed = regex_allowed;
          return next_token;
      }

      var skip_multiline_comment = with_eof_error("Unterminated multiline comment", function() {
          var regex_allowed = S.regex_allowed;
          var i = find("*/", true);
          var text = S.text.substring(S.pos, i).replace(/\r\n|\r|\u2028|\u2029/g, "\n");
          // update stream position
          forward(get_full_char_length(text) /* text length doesn't count \r\n as 2 char while S.pos - i does */ + 2);
          S.comments_before.push(token("comment2", text, true));
          S.newline_before = S.newline_before || text.includes("\n");
          S.regex_allowed = regex_allowed;
          return next_token;
      });

      var read_name = with_eof_error("Unterminated identifier name", function() {
          var name = [], ch, escaped = false;
          var read_escaped_identifier_char = function() {
              escaped = true;
              next();
              if (peek() !== "u") {
                  parse_error("Expecting UnicodeEscapeSequence -- uXXXX or u{XXXX}");
              }
              return read_escaped_char(false, true);
          };

          // Read first character (ID_Start)
          if ((ch = peek()) === "\\") {
              ch = read_escaped_identifier_char();
              if (!is_identifier_start(ch)) {
                  parse_error("First identifier char is an invalid identifier char");
              }
          } else if (is_identifier_start(ch)) {
              next();
          } else {
              return "";
          }

          name.push(ch);

          // Read ID_Continue
          while ((ch = peek()) != null) {
              if ((ch = peek()) === "\\") {
                  ch = read_escaped_identifier_char();
                  if (!is_identifier_char(ch)) {
                      parse_error("Invalid escaped identifier char");
                  }
              } else {
                  if (!is_identifier_char(ch)) {
                      break;
                  }
                  next();
              }
              name.push(ch);
          }
          const name_str = name.join("");
          if (RESERVED_WORDS.has(name_str) && escaped) {
              parse_error("Escaped characters are not allowed in keywords");
          }
          return name_str;
      });

      var read_regexp = with_eof_error("Unterminated regular expression", function(source) {
          var prev_backslash = false, ch, in_class = false;
          while ((ch = next(true))) if (NEWLINE_CHARS.has(ch)) {
              parse_error("Unexpected line terminator");
          } else if (prev_backslash) {
              source += "\\" + ch;
              prev_backslash = false;
          } else if (ch == "[") {
              in_class = true;
              source += ch;
          } else if (ch == "]" && in_class) {
              in_class = false;
              source += ch;
          } else if (ch == "/" && !in_class) {
              break;
          } else if (ch == "\\") {
              prev_backslash = true;
          } else {
              source += ch;
          }
          const flags = read_name();
          return token("regexp", "/" + source + "/" + flags);
      });

      function read_operator(prefix) {
          function grow(op) {
              if (!peek()) return op;
              var bigger = op + peek();
              if (OPERATORS.has(bigger)) {
                  next();
                  return grow(bigger);
              } else {
                  return op;
              }
          }
          return token("operator", grow(prefix || next()));
      }

      function handle_slash() {
          next();
          switch (peek()) {
            case "/":
              next();
              return skip_line_comment("comment1");
            case "*":
              next();
              return skip_multiline_comment();
          }
          return S.regex_allowed ? read_regexp("") : read_operator("/");
      }

      function handle_eq_sign() {
          next();
          if (peek() === ">") {
              next();
              return token("arrow", "=>");
          } else {
              return read_operator("=");
          }
      }

      function handle_dot() {
          next();
          if (is_digit(peek().charCodeAt(0))) {
              return read_num(".");
          }
          if (peek() === ".") {
              next();  // Consume second dot
              next();  // Consume third dot
              return token("expand", "...");
          }

          return token("punc", ".");
      }

      function read_word() {
          var word = read_name();
          if (prev_was_dot) return token("name", word);
          return KEYWORDS_ATOM.has(word) ? token("atom", word)
              : !KEYWORDS.has(word) ? token("name", word)
              : OPERATORS.has(word) ? token("operator", word)
              : token("keyword", word);
      }

      function read_private_word() {
          next();
          return token("privatename", read_name());
      }

      function with_eof_error(eof_error, cont) {
          return function(x) {
              try {
                  return cont(x);
              } catch(ex) {
                  if (ex === EX_EOF) parse_error(eof_error);
                  else throw ex;
              }
          };
      }

      function next_token(force_regexp) {
          if (force_regexp != null)
              return read_regexp(force_regexp);
          if (shebang && S.pos == 0 && looking_at("#!")) {
              start_token();
              forward(2);
              skip_line_comment("comment5");
          }
          for (;;) {
              skip_whitespace();
              start_token();
              if (html5_comments) {
                  if (looking_at("<!--")) {
                      forward(4);
                      skip_line_comment("comment3");
                      continue;
                  }
                  if (looking_at("-->") && S.newline_before) {
                      forward(3);
                      skip_line_comment("comment4");
                      continue;
                  }
              }
              var ch = peek();
              if (!ch) return token("eof");
              var code = ch.charCodeAt(0);
              switch (code) {
                case 34: case 39: return read_string();
                case 46: return handle_dot();
                case 47: {
                    var tok = handle_slash();
                    if (tok === next_token) continue;
                    return tok;
                }
                case 61: return handle_eq_sign();
                case 63: {
                    if (!is_option_chain_op()) break;  // Handled below

                    next(); // ?
                    next(); // .

                    return token("punc", "?.");
                }
                case 96: return read_template_characters(true);
                case 123:
                  S.brace_counter++;
                  break;
                case 125:
                  S.brace_counter--;
                  if (S.template_braces.length > 0
                      && S.template_braces[S.template_braces.length - 1] === S.brace_counter)
                      return read_template_characters(false);
                  break;
              }
              if (is_digit(code)) return read_num();
              if (PUNC_CHARS.has(ch)) return token("punc", next());
              if (OPERATOR_CHARS.has(ch)) return read_operator();
              if (code == 92 || is_identifier_start(ch)) return read_word();
              if (code == 35) return read_private_word();
              break;
          }
          parse_error("Unexpected character '" + ch + "'");
      }

      next_token.next = next;
      next_token.peek = peek;

      next_token.context = function(nc) {
          if (nc) S = nc;
          return S;
      };

      next_token.add_directive = function(directive) {
          S.directive_stack[S.directive_stack.length - 1].push(directive);

          if (S.directives[directive] === undefined) {
              S.directives[directive] = 1;
          } else {
              S.directives[directive]++;
          }
      };

      next_token.push_directives_stack = function() {
          S.directive_stack.push([]);
      };

      next_token.pop_directives_stack = function() {
          var directives = S.directive_stack[S.directive_stack.length - 1];

          for (var i = 0; i < directives.length; i++) {
              S.directives[directives[i]]--;
          }

          S.directive_stack.pop();
      };

      next_token.has_directive = function(directive) {
          return S.directives[directive] > 0;
      };

      return next_token;

  }

  /* -----[ Parser (constants) ]----- */

  var UNARY_PREFIX = makePredicate([
      "typeof",
      "void",
      "delete",
      "--",
      "++",
      "!",
      "~",
      "-",
      "+"
  ]);

  var UNARY_POSTFIX = makePredicate([ "--", "++" ]);

  var ASSIGNMENT = makePredicate([ "=", "+=", "-=", "??=", "&&=", "||=", "/=", "*=", "**=", "%=", ">>=", "<<=", ">>>=", "|=", "^=", "&=" ]);

  var LOGICAL_ASSIGNMENT = makePredicate([ "??=", "&&=", "||=" ]);

  var PRECEDENCE = (function(a, ret) {
      for (var i = 0; i < a.length; ++i) {
          var b = a[i];
          for (var j = 0; j < b.length; ++j) {
              ret[b[j]] = i + 1;
          }
      }
      return ret;
  })(
      [
          ["||"],
          ["??"],
          ["&&"],
          ["|"],
          ["^"],
          ["&"],
          ["==", "===", "!=", "!=="],
          ["<", ">", "<=", ">=", "in", "instanceof"],
          [">>", "<<", ">>>"],
          ["+", "-"],
          ["*", "/", "%"],
          ["**"]
      ],
      {}
  );

  var ATOMIC_START_TOKEN = makePredicate([ "atom", "num", "big_int", "string", "regexp", "name" ]);

  /* -----[ Parser ]----- */

  function parse($TEXT, options) {
      // maps start tokens to count of comments found outside of their parens
      // Example: /* I count */ ( /* I don't */ foo() )
      // Useful because comments_before property of call with parens outside
      // contains both comments inside and outside these parens. Used to find the
      
      const outer_comments_before_counts = new WeakMap();

      options = defaults(options, {
          bare_returns   : false,
          ecma           : null,  // Legacy
          expression     : false,
          filename       : null,
          html5_comments : true,
          module         : false,
          shebang        : true,
          strict         : false,
          toplevel       : null,
      }, true);

      var S = {
          input         : (typeof $TEXT == "string"
                           ? tokenizer($TEXT, options.filename,
                                       options.html5_comments, options.shebang)
                           : $TEXT),
          token         : null,
          prev          : null,
          peeked        : null,
          in_function   : 0,
          in_async      : -1,
          in_generator  : -1,
          in_directives : true,
          in_loop       : 0,
          labels        : []
      };

      S.token = next();

      function is(type, value) {
          return is_token(S.token, type, value);
      }

      function peek() { return S.peeked || (S.peeked = S.input()); }

      function next() {
          S.prev = S.token;

          if (!S.peeked) peek();
          S.token = S.peeked;
          S.peeked = null;
          S.in_directives = S.in_directives && (
              S.token.type == "string" || is("punc", ";")
          );
          return S.token;
      }

      function prev() {
          return S.prev;
      }

      function croak(msg, line, col, pos) {
          var ctx = S.input.context();
          js_error(msg,
                   ctx.filename,
                   line != null ? line : ctx.tokline,
                   col != null ? col : ctx.tokcol,
                   pos != null ? pos : ctx.tokpos);
      }

      function token_error(token, msg) {
          croak(msg, token.line, token.col);
      }

      function unexpected(token) {
          if (token == null)
              token = S.token;
          token_error(token, "Unexpected token: " + token.type + " (" + token.value + ")");
      }

      function expect_token(type, val) {
          if (is(type, val)) {
              return next();
          }
          token_error(S.token, "Unexpected token " + S.token.type + " «" + S.token.value + "»" + ", expected " + type + " «" + val + "»");
      }

      function expect(punc) { return expect_token("punc", punc); }

      function has_newline_before(token) {
          return token.nlb || !token.comments_before.every((comment) => !comment.nlb);
      }

      function can_insert_semicolon() {
          return !options.strict
              && (is("eof") || is("punc", "}") || has_newline_before(S.token));
      }

      function is_in_generator() {
          return S.in_generator === S.in_function;
      }

      function is_in_async() {
          return S.in_async === S.in_function;
      }

      function can_await() {
          return (
              S.in_async === S.in_function
              || S.in_function === 0 && S.input.has_directive("use strict")
          );
      }

      function semicolon(optional) {
          if (is("punc", ";")) next();
          else if (!optional && !can_insert_semicolon()) unexpected();
      }

      function parenthesised() {
          expect("(");
          var exp = expression(true);
          expect(")");
          return exp;
      }

      function embed_tokens(parser) {
          return function _embed_tokens_wrapper(...args) {
              const start = S.token;
              const expr = parser(...args);
              expr.start = start;
              expr.end = prev();
              return expr;
          };
      }

      function handle_regexp() {
          if (is("operator", "/") || is("operator", "/=")) {
              S.peeked = null;
              S.token = S.input(S.token.value.substr(1)); // force regexp
          }
      }

      var statement = embed_tokens(function statement(is_export_default, is_for_body, is_if_body) {
          handle_regexp();
          switch (S.token.type) {
            case "string":
              if (S.in_directives) {
                  var token = peek();
                  if (!LATEST_RAW.includes("\\")
                      && (is_token(token, "punc", ";")
                          || is_token(token, "punc", "}")
                          || has_newline_before(token)
                          || is_token(token, "eof"))) {
                      S.input.add_directive(S.token.value);
                  } else {
                      S.in_directives = false;
                  }
              }
              var dir = S.in_directives, stat = simple_statement();
              return dir && stat.body instanceof AST_String ? new AST_Directive(stat.body) : stat;
            case "template_head":
            case "num":
            case "big_int":
            case "regexp":
            case "operator":
            case "atom":
              return simple_statement();

            case "name":
              if (S.token.value == "async" && is_token(peek(), "keyword", "function")) {
                  next();
                  next();
                  if (is_for_body) {
                      croak("functions are not allowed as the body of a loop");
                  }
                  return function_(AST_Defun, false, true, is_export_default);
              }
              if (S.token.value == "import" && !is_token(peek(), "punc", "(") && !is_token(peek(), "punc", ".")) {
                  next();
                  var node = import_statement();
                  semicolon();
                  return node;
              }
              return is_token(peek(), "punc", ":")
                  ? labeled_statement()
                  : simple_statement();

            case "punc":
              switch (S.token.value) {
                case "{":
                  return new AST_BlockStatement({
                      start : S.token,
                      body  : block_(),
                      end   : prev()
                  });
                case "[":
                case "(":
                  return simple_statement();
                case ";":
                  S.in_directives = false;
                  next();
                  return new AST_EmptyStatement();
                default:
                  unexpected();
              }

            case "keyword":
              switch (S.token.value) {
                case "break":
                  next();
                  return break_cont(AST_Break);

                case "continue":
                  next();
                  return break_cont(AST_Continue);

                case "debugger":
                  next();
                  semicolon();
                  return new AST_Debugger();

                case "do":
                  next();
                  var body = in_loop(statement);
                  expect_token("keyword", "while");
                  var condition = parenthesised();
                  semicolon(true);
                  return new AST_Do({
                      body      : body,
                      condition : condition
                  });

                case "while":
                  next();
                  return new AST_While({
                      condition : parenthesised(),
                      body      : in_loop(function() { return statement(false, true); })
                  });

                case "for":
                  next();
                  return for_();

                case "class":
                  next();
                  if (is_for_body) {
                      croak("classes are not allowed as the body of a loop");
                  }
                  if (is_if_body) {
                      croak("classes are not allowed as the body of an if");
                  }
                  return class_(AST_DefClass, is_export_default);

                case "function":
                  next();
                  if (is_for_body) {
                      croak("functions are not allowed as the body of a loop");
                  }
                  return function_(AST_Defun, false, false, is_export_default);

                case "if":
                  next();
                  return if_();

                case "return":
                  if (S.in_function == 0 && !options.bare_returns)
                      croak("'return' outside of function");
                  next();
                  var value = null;
                  if (is("punc", ";")) {
                      next();
                  } else if (!can_insert_semicolon()) {
                      value = expression(true);
                      semicolon();
                  }
                  return new AST_Return({
                      value: value
                  });

                case "switch":
                  next();
                  return new AST_Switch({
                      expression : parenthesised(),
                      body       : in_loop(switch_body_)
                  });

                case "throw":
                  next();
                  if (has_newline_before(S.token))
                      croak("Illegal newline after 'throw'");
                  var value = expression(true);
                  semicolon();
                  return new AST_Throw({
                      value: value
                  });

                case "try":
                  next();
                  return try_();

                case "var":
                  next();
                  var node = var_();
                  semicolon();
                  return node;

                case "let":
                  next();
                  var node = let_();
                  semicolon();
                  return node;

                case "const":
                  next();
                  var node = const_();
                  semicolon();
                  return node;

                case "with":
                  if (S.input.has_directive("use strict")) {
                      croak("Strict mode may not include a with statement");
                  }
                  next();
                  return new AST_With({
                      expression : parenthesised(),
                      body       : statement()
                  });

                case "export":
                  if (!is_token(peek(), "punc", "(")) {
                      next();
                      var node = export_statement();
                      if (is("punc", ";")) semicolon();
                      return node;
                  }
              }
          }
          unexpected();
      });

      function labeled_statement() {
          var label = as_symbol(AST_Label);
          if (label.name === "await" && is_in_async()) {
              token_error(S.prev, "await cannot be used as label inside async function");
          }
          if (S.labels.some((l) => l.name === label.name)) {
              // ECMA-262, 12.12: An ECMAScript program is considered
              // syntactically incorrect if it contains a
              // LabelledStatement that is enclosed by a
              // LabelledStatement with the same Identifier as label.
              croak("Label " + label.name + " defined twice");
          }
          expect(":");
          S.labels.push(label);
          var stat = statement();
          S.labels.pop();
          if (!(stat instanceof AST_IterationStatement)) {
              // check for `continue` that refers to this label.
              // those should be reported as syntax errors.
              // https://github.com/mishoo/UglifyJS2/issues/287
              label.references.forEach(function(ref) {
                  if (ref instanceof AST_Continue) {
                      ref = ref.label.start;
                      croak("Continue label `" + label.name + "` refers to non-IterationStatement.",
                            ref.line, ref.col, ref.pos);
                  }
              });
          }
          return new AST_LabeledStatement({ body: stat, label: label });
      }

      function simple_statement(tmp) {
          return new AST_SimpleStatement({ body: (tmp = expression(true), semicolon(), tmp) });
      }

      function break_cont(type) {
          var label = null, ldef;
          if (!can_insert_semicolon()) {
              label = as_symbol(AST_LabelRef, true);
          }
          if (label != null) {
              ldef = S.labels.find((l) => l.name === label.name);
              if (!ldef)
                  croak("Undefined label " + label.name);
              label.thedef = ldef;
          } else if (S.in_loop == 0)
              croak(type.TYPE + " not inside a loop or switch");
          semicolon();
          var stat = new type({ label: label });
          if (ldef) ldef.references.push(stat);
          return stat;
      }

      function for_() {
          var for_await_error = "`for await` invalid in this context";
          var await_tok = S.token;
          if (await_tok.type == "name" && await_tok.value == "await") {
              if (!can_await()) {
                  token_error(await_tok, for_await_error);
              }
              next();
          } else {
              await_tok = false;
          }
          expect("(");
          var init = null;
          if (!is("punc", ";")) {
              init =
                  is("keyword", "var") ? (next(), var_(true)) :
                  is("keyword", "let") ? (next(), let_(true)) :
                  is("keyword", "const") ? (next(), const_(true)) :
                                         expression(true, true);
              var is_in = is("operator", "in");
              var is_of = is("name", "of");
              if (await_tok && !is_of) {
                  token_error(await_tok, for_await_error);
              }
              if (is_in || is_of) {
                  if (init instanceof AST_Definitions) {
                      if (init.definitions.length > 1)
                          token_error(init.start, "Only one variable declaration allowed in for..in loop");
                  } else if (!(is_assignable(init) || (init = to_destructuring(init)) instanceof AST_Destructuring)) {
                      token_error(init.start, "Invalid left-hand side in for..in loop");
                  }
                  next();
                  if (is_in) {
                      return for_in(init);
                  } else {
                      return for_of(init, !!await_tok);
                  }
              }
          } else if (await_tok) {
              token_error(await_tok, for_await_error);
          }
          return regular_for(init);
      }

      function regular_for(init) {
          expect(";");
          var test = is("punc", ";") ? null : expression(true);
          expect(";");
          var step = is("punc", ")") ? null : expression(true);
          expect(")");
          return new AST_For({
              init      : init,
              condition : test,
              step      : step,
              body      : in_loop(function() { return statement(false, true); })
          });
      }

      function for_of(init, is_await) {
          var lhs = init instanceof AST_Definitions ? init.definitions[0].name : null;
          var obj = expression(true);
          expect(")");
          return new AST_ForOf({
              await  : is_await,
              init   : init,
              name   : lhs,
              object : obj,
              body   : in_loop(function() { return statement(false, true); })
          });
      }

      function for_in(init) {
          var obj = expression(true);
          expect(")");
          return new AST_ForIn({
              init   : init,
              object : obj,
              body   : in_loop(function() { return statement(false, true); })
          });
      }

      var arrow_function = function(start, argnames, is_async) {
          if (has_newline_before(S.token)) {
              croak("Unexpected newline before arrow (=>)");
          }

          expect_token("arrow", "=>");

          var body = _function_body(is("punc", "{"), false, is_async);

          var end =
              body instanceof Array && body.length ? body[body.length - 1].end :
              body instanceof Array ? start :
                  body.end;

          return new AST_Arrow({
              start    : start,
              end      : end,
              async    : is_async,
              argnames : argnames,
              body     : body
          });
      };

      var function_ = function(ctor, is_generator_property, is_async, is_export_default) {
          var in_statement = ctor === AST_Defun;
          var is_generator = is("operator", "*");
          if (is_generator) {
              next();
          }

          var name = is("name") ? as_symbol(in_statement ? AST_SymbolDefun : AST_SymbolLambda) : null;
          if (in_statement && !name) {
              if (is_export_default) {
                  ctor = AST_Function;
              } else {
                  unexpected();
              }
          }

          if (name && ctor !== AST_Accessor && !(name instanceof AST_SymbolDeclaration))
              unexpected(prev());

          var args = [];
          var body = _function_body(true, is_generator || is_generator_property, is_async, name, args);
          return new ctor({
              start : args.start,
              end   : body.end,
              is_generator: is_generator,
              async : is_async,
              name  : name,
              argnames: args,
              body  : body
          });
      };

      class UsedParametersTracker {
          constructor(is_parameter, strict, duplicates_ok = false) {
              this.is_parameter = is_parameter;
              this.duplicates_ok = duplicates_ok;
              this.parameters = new Set();
              this.duplicate = null;
              this.default_assignment = false;
              this.spread = false;
              this.strict_mode = !!strict;
          }
          add_parameter(token) {
              if (this.parameters.has(token.value)) {
                  if (this.duplicate === null) {
                      this.duplicate = token;
                  }
                  this.check_strict();
              } else {
                  this.parameters.add(token.value);
                  if (this.is_parameter) {
                      switch (token.value) {
                        case "arguments":
                        case "eval":
                        case "yield":
                          if (this.strict_mode) {
                              token_error(token, "Unexpected " + token.value + " identifier as parameter inside strict mode");
                          }
                          break;
                        default:
                          if (RESERVED_WORDS.has(token.value)) {
                              unexpected();
                          }
                      }
                  }
              }
          }
          mark_default_assignment(token) {
              if (this.default_assignment === false) {
                  this.default_assignment = token;
              }
          }
          mark_spread(token) {
              if (this.spread === false) {
                  this.spread = token;
              }
          }
          mark_strict_mode() {
              this.strict_mode = true;
          }
          is_strict() {
              return this.default_assignment !== false || this.spread !== false || this.strict_mode;
          }
          check_strict() {
              if (this.is_strict() && this.duplicate !== null && !this.duplicates_ok) {
                  token_error(this.duplicate, "Parameter " + this.duplicate.value + " was used already");
              }
          }
      }

      function parameters(params) {
          var used_parameters = new UsedParametersTracker(true, S.input.has_directive("use strict"));

          expect("(");

          while (!is("punc", ")")) {
              var param = parameter(used_parameters);
              params.push(param);

              if (!is("punc", ")")) {
                  expect(",");
              }

              if (param instanceof AST_Expansion) {
                  break;
              }
          }

          next();
      }

      function parameter(used_parameters, symbol_type) {
          var param;
          var expand = false;
          if (used_parameters === undefined) {
              used_parameters = new UsedParametersTracker(true, S.input.has_directive("use strict"));
          }
          if (is("expand", "...")) {
              expand = S.token;
              used_parameters.mark_spread(S.token);
              next();
          }
          param = binding_element(used_parameters, symbol_type);

          if (is("operator", "=") && expand === false) {
              used_parameters.mark_default_assignment(S.token);
              next();
              param = new AST_DefaultAssign({
                  start: param.start,
                  left: param,
                  operator: "=",
                  right: expression(false),
                  end: S.token
              });
          }

          if (expand !== false) {
              if (!is("punc", ")")) {
                  unexpected();
              }
              param = new AST_Expansion({
                  start: expand,
                  expression: param,
                  end: expand
              });
          }
          used_parameters.check_strict();

          return param;
      }

      function binding_element(used_parameters, symbol_type) {
          var elements = [];
          var first = true;
          var is_expand = false;
          var expand_token;
          var first_token = S.token;
          if (used_parameters === undefined) {
              const strict = S.input.has_directive("use strict");
              const duplicates_ok = symbol_type === AST_SymbolVar;
              used_parameters = new UsedParametersTracker(false, strict, duplicates_ok);
          }
          symbol_type = symbol_type === undefined ? AST_SymbolFunarg : symbol_type;
          if (is("punc", "[")) {
              next();
              while (!is("punc", "]")) {
                  if (first) {
                      first = false;
                  } else {
                      expect(",");
                  }

                  if (is("expand", "...")) {
                      is_expand = true;
                      expand_token = S.token;
                      used_parameters.mark_spread(S.token);
                      next();
                  }
                  if (is("punc")) {
                      switch (S.token.value) {
                        case ",":
                          elements.push(new AST_Hole({
                              start: S.token,
                              end: S.token
                          }));
                          continue;
                        case "]": // Trailing comma after last element
                          break;
                        case "[":
                        case "{":
                          elements.push(binding_element(used_parameters, symbol_type));
                          break;
                        default:
                          unexpected();
                      }
                  } else if (is("name")) {
                      used_parameters.add_parameter(S.token);
                      elements.push(as_symbol(symbol_type));
                  } else {
                      croak("Invalid function parameter");
                  }
                  if (is("operator", "=") && is_expand === false) {
                      used_parameters.mark_default_assignment(S.token);
                      next();
                      elements[elements.length - 1] = new AST_DefaultAssign({
                          start: elements[elements.length - 1].start,
                          left: elements[elements.length - 1],
                          operator: "=",
                          right: expression(false),
                          end: S.token
                      });
                  }
                  if (is_expand) {
                      if (!is("punc", "]")) {
                          croak("Rest element must be last element");
                      }
                      elements[elements.length - 1] = new AST_Expansion({
                          start: expand_token,
                          expression: elements[elements.length - 1],
                          end: expand_token
                      });
                  }
              }
              expect("]");
              used_parameters.check_strict();
              return new AST_Destructuring({
                  start: first_token,
                  names: elements,
                  is_array: true,
                  end: prev()
              });
          } else if (is("punc", "{")) {
              next();
              while (!is("punc", "}")) {
                  if (first) {
                      first = false;
                  } else {
                      expect(",");
                  }
                  if (is("expand", "...")) {
                      is_expand = true;
                      expand_token = S.token;
                      used_parameters.mark_spread(S.token);
                      next();
                  }
                  if (is("name") && (is_token(peek(), "punc") || is_token(peek(), "operator")) && [",", "}", "="].includes(peek().value)) {
                      used_parameters.add_parameter(S.token);
                      var start = prev();
                      var value = as_symbol(symbol_type);
                      if (is_expand) {
                          elements.push(new AST_Expansion({
                              start: expand_token,
                              expression: value,
                              end: value.end,
                          }));
                      } else {
                          elements.push(new AST_ObjectKeyVal({
                              start: start,
                              key: value.name,
                              value: value,
                              end: value.end,
                          }));
                      }
                  } else if (is("punc", "}")) {
                      continue; // Allow trailing hole
                  } else {
                      var property_token = S.token;
                      var property = as_property_name();
                      if (property === null) {
                          unexpected(prev());
                      } else if (prev().type === "name" && !is("punc", ":")) {
                          elements.push(new AST_ObjectKeyVal({
                              start: prev(),
                              key: property,
                              value: new symbol_type({
                                  start: prev(),
                                  name: property,
                                  end: prev()
                              }),
                              end: prev()
                          }));
                      } else {
                          expect(":");
                          elements.push(new AST_ObjectKeyVal({
                              start: property_token,
                              quote: property_token.quote,
                              key: property,
                              value: binding_element(used_parameters, symbol_type),
                              end: prev()
                          }));
                      }
                  }
                  if (is_expand) {
                      if (!is("punc", "}")) {
                          croak("Rest element must be last element");
                      }
                  } else if (is("operator", "=")) {
                      used_parameters.mark_default_assignment(S.token);
                      next();
                      elements[elements.length - 1].value = new AST_DefaultAssign({
                          start: elements[elements.length - 1].value.start,
                          left: elements[elements.length - 1].value,
                          operator: "=",
                          right: expression(false),
                          end: S.token
                      });
                  }
              }
              expect("}");
              used_parameters.check_strict();
              return new AST_Destructuring({
                  start: first_token,
                  names: elements,
                  is_array: false,
                  end: prev()
              });
          } else if (is("name")) {
              used_parameters.add_parameter(S.token);
              return as_symbol(symbol_type);
          } else {
              croak("Invalid function parameter");
          }
      }

      function params_or_seq_(allow_arrows, maybe_sequence) {
          var spread_token;
          var invalid_sequence;
          var trailing_comma;
          var a = [];
          expect("(");
          while (!is("punc", ")")) {
              if (spread_token) unexpected(spread_token);
              if (is("expand", "...")) {
                  spread_token = S.token;
                  if (maybe_sequence) invalid_sequence = S.token;
                  next();
                  a.push(new AST_Expansion({
                      start: prev(),
                      expression: expression(),
                      end: S.token,
                  }));
              } else {
                  a.push(expression());
              }
              if (!is("punc", ")")) {
                  expect(",");
                  if (is("punc", ")")) {
                      trailing_comma = prev();
                      if (maybe_sequence) invalid_sequence = trailing_comma;
                  }
              }
          }
          expect(")");
          if (allow_arrows && is("arrow", "=>")) {
              if (spread_token && trailing_comma) unexpected(trailing_comma);
          } else if (invalid_sequence) {
              unexpected(invalid_sequence);
          }
          return a;
      }

      function _function_body(block, generator, is_async, name, args) {
          var loop = S.in_loop;
          var labels = S.labels;
          var current_generator = S.in_generator;
          var current_async = S.in_async;
          ++S.in_function;
          if (generator)
              S.in_generator = S.in_function;
          if (is_async)
              S.in_async = S.in_function;
          if (args) parameters(args);
          if (block)
              S.in_directives = true;
          S.in_loop = 0;
          S.labels = [];
          if (block) {
              S.input.push_directives_stack();
              var a = block_();
              if (name) _verify_symbol(name);
              if (args) args.forEach(_verify_symbol);
              S.input.pop_directives_stack();
          } else {
              var a = [new AST_Return({
                  start: S.token,
                  value: expression(false),
                  end: S.token
              })];
          }
          --S.in_function;
          S.in_loop = loop;
          S.labels = labels;
          S.in_generator = current_generator;
          S.in_async = current_async;
          return a;
      }

      function _await_expression() {
          // Previous token must be "await" and not be interpreted as an identifier
          if (!can_await()) {
              croak("Unexpected await expression outside async function",
                  S.prev.line, S.prev.col, S.prev.pos);
          }
          // the await expression is parsed as a unary expression in Babel
          return new AST_Await({
              start: prev(),
              end: S.token,
              expression : maybe_unary(true),
          });
      }

      function _yield_expression() {
          // Previous token must be keyword yield and not be interpret as an identifier
          if (!is_in_generator()) {
              croak("Unexpected yield expression outside generator function",
                  S.prev.line, S.prev.col, S.prev.pos);
          }
          var start = S.token;
          var star = false;
          var has_expression = true;

          // Attempt to get expression or star (and then the mandatory expression)
          // behind yield on the same line.
          //
          // If nothing follows on the same line of the yieldExpression,
          // it should default to the value `undefined` for yield to return.
          // In that case, the `undefined` stored as `null` in ast.
          //
          // Note 1: It isn't allowed for yield* to close without an expression
          // Note 2: If there is a nlb between yield and star, it is interpret as
          //         yield <explicit undefined> <inserted automatic semicolon> *
          if (can_insert_semicolon() ||
              (is("punc") && PUNC_AFTER_EXPRESSION.has(S.token.value))) {
              has_expression = false;

          } else if (is("operator", "*")) {
              star = true;
              next();
          }

          return new AST_Yield({
              start      : start,
              is_star    : star,
              expression : has_expression ? expression() : null,
              end        : prev()
          });
      }

      function if_() {
          var cond = parenthesised(), body = statement(false, false, true), belse = null;
          if (is("keyword", "else")) {
              next();
              belse = statement(false, false, true);
          }
          return new AST_If({
              condition   : cond,
              body        : body,
              alternative : belse
          });
      }

      function block_() {
          expect("{");
          var a = [];
          while (!is("punc", "}")) {
              if (is("eof")) unexpected();
              a.push(statement());
          }
          next();
          return a;
      }

      function switch_body_() {
          expect("{");
          var a = [], cur = null, branch = null, tmp;
          while (!is("punc", "}")) {
              if (is("eof")) unexpected();
              if (is("keyword", "case")) {
                  if (branch) branch.end = prev();
                  cur = [];
                  branch = new AST_Case({
                      start      : (tmp = S.token, next(), tmp),
                      expression : expression(true),
                      body       : cur
                  });
                  a.push(branch);
                  expect(":");
              } else if (is("keyword", "default")) {
                  if (branch) branch.end = prev();
                  cur = [];
                  branch = new AST_Default({
                      start : (tmp = S.token, next(), expect(":"), tmp),
                      body  : cur
                  });
                  a.push(branch);
              } else {
                  if (!cur) unexpected();
                  cur.push(statement());
              }
          }
          if (branch) branch.end = prev();
          next();
          return a;
      }

      function try_() {
          var body = block_(), bcatch = null, bfinally = null;
          if (is("keyword", "catch")) {
              var start = S.token;
              next();
              if (is("punc", "{")) {
                  var name = null;
              } else {
                  expect("(");
                  var name = parameter(undefined, AST_SymbolCatch);
                  expect(")");
              }
              bcatch = new AST_Catch({
                  start   : start,
                  argname : name,
                  body    : block_(),
                  end     : prev()
              });
          }
          if (is("keyword", "finally")) {
              var start = S.token;
              next();
              bfinally = new AST_Finally({
                  start : start,
                  body  : block_(),
                  end   : prev()
              });
          }
          if (!bcatch && !bfinally)
              croak("Missing catch/finally blocks");
          return new AST_Try({
              body     : body,
              bcatch   : bcatch,
              bfinally : bfinally
          });
      }

      function vardefs(no_in, kind) {
          var a = [];
          var def;
          for (;;) {
              var sym_type =
                  kind === "var" ? AST_SymbolVar :
                  kind === "const" ? AST_SymbolConst :
                  kind === "let" ? AST_SymbolLet : null;
              if (is("punc", "{") || is("punc", "[")) {
                  def = new AST_VarDef({
                      start: S.token,
                      name: binding_element(undefined, sym_type),
                      value: is("operator", "=") ? (expect_token("operator", "="), expression(false, no_in)) : null,
                      end: prev()
                  });
              } else {
                  def = new AST_VarDef({
                      start : S.token,
                      name  : as_symbol(sym_type),
                      value : is("operator", "=")
                          ? (next(), expression(false, no_in))
                          : !no_in && kind === "const"
                              ? croak("Missing initializer in const declaration") : null,
                      end   : prev()
                  });
                  if (def.name.name == "import") croak("Unexpected token: import");
              }
              a.push(def);
              if (!is("punc", ","))
                  break;
              next();
          }
          return a;
      }

      var var_ = function(no_in) {
          return new AST_Var({
              start       : prev(),
              definitions : vardefs(no_in, "var"),
              end         : prev()
          });
      };

      var let_ = function(no_in) {
          return new AST_Let({
              start       : prev(),
              definitions : vardefs(no_in, "let"),
              end         : prev()
          });
      };

      var const_ = function(no_in) {
          return new AST_Const({
              start       : prev(),
              definitions : vardefs(no_in, "const"),
              end         : prev()
          });
      };

      var new_ = function(allow_calls) {
          var start = S.token;
          expect_token("operator", "new");
          if (is("punc", ".")) {
              next();
              expect_token("name", "target");
              return subscripts(new AST_NewTarget({
                  start : start,
                  end   : prev()
              }), allow_calls);
          }
          var newexp = expr_atom(false), args;
          if (is("punc", "(")) {
              next();
              args = expr_list(")", true);
          } else {
              args = [];
          }
          var call = new AST_New({
              start      : start,
              expression : newexp,
              args       : args,
              end        : prev()
          });
          annotate(call);
          return subscripts(call, allow_calls);
      };

      function as_atom_node() {
          var tok = S.token, ret;
          switch (tok.type) {
            case "name":
              ret = _make_symbol(AST_SymbolRef);
              break;
            case "num":
              ret = new AST_Number({
                  start: tok,
                  end: tok,
                  value: tok.value,
                  raw: LATEST_RAW
              });
              break;
            case "big_int":
              ret = new AST_BigInt({ start: tok, end: tok, value: tok.value });
              break;
            case "string":
              ret = new AST_String({
                  start : tok,
                  end   : tok,
                  value : tok.value,
                  quote : tok.quote
              });
              break;
            case "regexp":
              const [_, source, flags] = tok.value.match(/^\/(.*)\/(\w*)$/);

              ret = new AST_RegExp({ start: tok, end: tok, value: { source, flags } });
              break;
            case "atom":
              switch (tok.value) {
                case "false":
                  ret = new AST_False({ start: tok, end: tok });
                  break;
                case "true":
                  ret = new AST_True({ start: tok, end: tok });
                  break;
                case "null":
                  ret = new AST_Null({ start: tok, end: tok });
                  break;
              }
              break;
          }
          next();
          return ret;
      }

      function to_fun_args(ex, default_seen_above) {
          var insert_default = function(ex, default_value) {
              if (default_value) {
                  return new AST_DefaultAssign({
                      start: ex.start,
                      left: ex,
                      operator: "=",
                      right: default_value,
                      end: default_value.end
                  });
              }
              return ex;
          };
          if (ex instanceof AST_Object) {
              return insert_default(new AST_Destructuring({
                  start: ex.start,
                  end: ex.end,
                  is_array: false,
                  names: ex.properties.map(prop => to_fun_args(prop))
              }), default_seen_above);
          } else if (ex instanceof AST_ObjectKeyVal) {
              ex.value = to_fun_args(ex.value);
              return insert_default(ex, default_seen_above);
          } else if (ex instanceof AST_Hole) {
              return ex;
          } else if (ex instanceof AST_Destructuring) {
              ex.names = ex.names.map(name => to_fun_args(name));
              return insert_default(ex, default_seen_above);
          } else if (ex instanceof AST_SymbolRef) {
              return insert_default(new AST_SymbolFunarg({
                  name: ex.name,
                  start: ex.start,
                  end: ex.end
              }), default_seen_above);
          } else if (ex instanceof AST_Expansion) {
              ex.expression = to_fun_args(ex.expression);
              return insert_default(ex, default_seen_above);
          } else if (ex instanceof AST_Array) {
              return insert_default(new AST_Destructuring({
                  start: ex.start,
                  end: ex.end,
                  is_array: true,
                  names: ex.elements.map(elm => to_fun_args(elm))
              }), default_seen_above);
          } else if (ex instanceof AST_Assign) {
              return insert_default(to_fun_args(ex.left, ex.right), default_seen_above);
          } else if (ex instanceof AST_DefaultAssign) {
              ex.left = to_fun_args(ex.left);
              return ex;
          } else {
              croak("Invalid function parameter", ex.start.line, ex.start.col);
          }
      }

      var expr_atom = function(allow_calls, allow_arrows) {
          if (is("operator", "new")) {
              return new_(allow_calls);
          }
          if (is("operator", "import")) {
              return import_meta();
          }
          var start = S.token;
          var peeked;
          var async = is("name", "async")
              && (peeked = peek()).value != "["
              && peeked.type != "arrow"
              && as_atom_node();
          if (is("punc")) {
              switch (S.token.value) {
                case "(":
                  if (async && !allow_calls) break;
                  var exprs = params_or_seq_(allow_arrows, !async);
                  if (allow_arrows && is("arrow", "=>")) {
                      return arrow_function(start, exprs.map(e => to_fun_args(e)), !!async);
                  }
                  var ex = async ? new AST_Call({
                      expression: async,
                      args: exprs
                  }) : exprs.length == 1 ? exprs[0] : new AST_Sequence({
                      expressions: exprs
                  });
                  if (ex.start) {
                      const outer_comments_before = start.comments_before.length;
                      outer_comments_before_counts.set(start, outer_comments_before);
                      ex.start.comments_before.unshift(...start.comments_before);
                      start.comments_before = ex.start.comments_before;
                      if (outer_comments_before == 0 && start.comments_before.length > 0) {
                          var comment = start.comments_before[0];
                          if (!comment.nlb) {
                              comment.nlb = start.nlb;
                              start.nlb = false;
                          }
                      }
                      start.comments_after = ex.start.comments_after;
                  }
                  ex.start = start;
                  var end = prev();
                  if (ex.end) {
                      end.comments_before = ex.end.comments_before;
                      ex.end.comments_after.push(...end.comments_after);
                      end.comments_after = ex.end.comments_after;
                  }
                  ex.end = end;
                  if (ex instanceof AST_Call) annotate(ex);
                  return subscripts(ex, allow_calls);
                case "[":
                  return subscripts(array_(), allow_calls);
                case "{":
                  return subscripts(object_or_destructuring_(), allow_calls);
              }
              if (!async) unexpected();
          }
          if (allow_arrows && is("name") && is_token(peek(), "arrow")) {
              var param = new AST_SymbolFunarg({
                  name: S.token.value,
                  start: start,
                  end: start,
              });
              next();
              return arrow_function(start, [param], !!async);
          }
          if (is("keyword", "function")) {
              next();
              var func = function_(AST_Function, false, !!async);
              func.start = start;
              func.end = prev();
              return subscripts(func, allow_calls);
          }
          if (async) return subscripts(async, allow_calls);
          if (is("keyword", "class")) {
              next();
              var cls = class_(AST_ClassExpression);
              cls.start = start;
              cls.end = prev();
              return subscripts(cls, allow_calls);
          }
          if (is("template_head")) {
              return subscripts(template_string(), allow_calls);
          }
          if (ATOMIC_START_TOKEN.has(S.token.type)) {
              return subscripts(as_atom_node(), allow_calls);
          }
          unexpected();
      };

      function template_string() {
          var segments = [], start = S.token;

          segments.push(new AST_TemplateSegment({
              start: S.token,
              raw: TEMPLATE_RAWS.get(S.token),
              value: S.token.value,
              end: S.token
          }));

          while (!S.token.template_end) {
              next();
              handle_regexp();
              segments.push(expression(true));

              segments.push(new AST_TemplateSegment({
                  start: S.token,
                  raw: TEMPLATE_RAWS.get(S.token),
                  value: S.token.value,
                  end: S.token
              }));
          }
          next();

          return new AST_TemplateString({
              start: start,
              segments: segments,
              end: S.token
          });
      }

      function expr_list(closing, allow_trailing_comma, allow_empty) {
          var first = true, a = [];
          while (!is("punc", closing)) {
              if (first) first = false; else expect(",");
              if (allow_trailing_comma && is("punc", closing)) break;
              if (is("punc", ",") && allow_empty) {
                  a.push(new AST_Hole({ start: S.token, end: S.token }));
              } else if (is("expand", "...")) {
                  next();
                  a.push(new AST_Expansion({start: prev(), expression: expression(),end: S.token}));
              } else {
                  a.push(expression(false));
              }
          }
          next();
          return a;
      }

      var array_ = embed_tokens(function() {
          expect("[");
          return new AST_Array({
              elements: expr_list("]", !options.strict, true)
          });
      });

      var create_accessor = embed_tokens((is_generator, is_async) => {
          return function_(AST_Accessor, is_generator, is_async);
      });

      var object_or_destructuring_ = embed_tokens(function object_or_destructuring_() {
          var start = S.token, first = true, a = [];
          expect("{");
          while (!is("punc", "}")) {
              if (first) first = false; else expect(",");
              if (!options.strict && is("punc", "}"))
                  // allow trailing comma
                  break;

              start = S.token;
              if (start.type == "expand") {
                  next();
                  a.push(new AST_Expansion({
                      start: start,
                      expression: expression(false),
                      end: prev(),
                  }));
                  continue;
              }

              var name = as_property_name();
              var value;

              // Check property and fetch value
              if (!is("punc", ":")) {
                  var concise = concise_method_or_getset(name, start);
                  if (concise) {
                      a.push(concise);
                      continue;
                  }

                  value = new AST_SymbolRef({
                      start: prev(),
                      name: name,
                      end: prev()
                  });
              } else if (name === null) {
                  unexpected(prev());
              } else {
                  next(); // `:` - see first condition
                  value = expression(false);
              }

              // Check for default value and alter value accordingly if necessary
              if (is("operator", "=")) {
                  next();
                  value = new AST_Assign({
                      start: start,
                      left: value,
                      operator: "=",
                      right: expression(false),
                      logical: false,
                      end: prev()
                  });
              }

              // Create property
              a.push(new AST_ObjectKeyVal({
                  start: start,
                  quote: start.quote,
                  key: name instanceof AST_Node ? name : "" + name,
                  value: value,
                  end: prev()
              }));
          }
          next();
          return new AST_Object({ properties: a });
      });

      function class_(KindOfClass, is_export_default) {
          var start, method, class_name, extends_, a = [];

          S.input.push_directives_stack(); // Push directive stack, but not scope stack
          S.input.add_directive("use strict");

          if (S.token.type == "name" && S.token.value != "extends") {
              class_name = as_symbol(KindOfClass === AST_DefClass ? AST_SymbolDefClass : AST_SymbolClass);
          }

          if (KindOfClass === AST_DefClass && !class_name) {
              if (is_export_default) {
                  KindOfClass = AST_ClassExpression;
              } else {
                  unexpected();
              }
          }

          if (S.token.value == "extends") {
              next();
              extends_ = expression(true);
          }

          expect("{");

          while (is("punc", ";")) { next(); }  // Leading semicolons are okay in class bodies.
          while (!is("punc", "}")) {
              start = S.token;
              method = concise_method_or_getset(as_property_name(), start, true);
              if (!method) { unexpected(); }
              a.push(method);
              while (is("punc", ";")) { next(); }
          }

          S.input.pop_directives_stack();

          next();

          return new KindOfClass({
              start: start,
              name: class_name,
              extends: extends_,
              properties: a,
              end: prev(),
          });
      }

      function concise_method_or_getset(name, start, is_class) {
          const get_symbol_ast = (name, SymbolClass = AST_SymbolMethod) => {
              if (typeof name === "string" || typeof name === "number") {
                  return new SymbolClass({
                      start,
                      name: "" + name,
                      end: prev()
                  });
              } else if (name === null) {
                  unexpected();
              }
              return name;
          };

          const is_not_method_start = () =>
              !is("punc", "(") && !is("punc", ",") && !is("punc", "}") && !is("punc", ";") && !is("operator", "=");

          var is_async = false;
          var is_static = false;
          var is_generator = false;
          var is_private = false;
          var accessor_type = null;

          if (is_class && name === "static" && is_not_method_start()) {
              is_static = true;
              name = as_property_name();
          }
          if (name === "async" && is_not_method_start()) {
              is_async = true;
              name = as_property_name();
          }
          if (prev().type === "operator" && prev().value === "*") {
              is_generator = true;
              name = as_property_name();
          }
          if ((name === "get" || name === "set") && is_not_method_start()) {
              accessor_type = name;
              name = as_property_name();
          }
          if (prev().type === "privatename") {
              is_private = true;
          }

          const property_token = prev();

          if (accessor_type != null) {
              if (!is_private) {
                  const AccessorClass = accessor_type === "get"
                      ? AST_ObjectGetter
                      : AST_ObjectSetter;

                  name = get_symbol_ast(name);
                  return new AccessorClass({
                      start,
                      static: is_static,
                      key: name,
                      quote: name instanceof AST_SymbolMethod ? property_token.quote : undefined,
                      value: create_accessor(),
                      end: prev()
                  });
              } else {
                  const AccessorClass = accessor_type === "get"
                      ? AST_PrivateGetter
                      : AST_PrivateSetter;

                  return new AccessorClass({
                      start,
                      static: is_static,
                      key: get_symbol_ast(name),
                      value: create_accessor(),
                      end: prev(),
                  });
              }
          }

          if (is("punc", "(")) {
              name = get_symbol_ast(name);
              const AST_MethodVariant = is_private
                  ? AST_PrivateMethod
                  : AST_ConciseMethod;
              var node = new AST_MethodVariant({
                  start       : start,
                  static      : is_static,
                  is_generator: is_generator,
                  async       : is_async,
                  key         : name,
                  quote       : name instanceof AST_SymbolMethod ?
                                property_token.quote : undefined,
                  value       : create_accessor(is_generator, is_async),
                  end         : prev()
              });
              return node;
          }

          if (is_class) {
              const key = get_symbol_ast(name, AST_SymbolClassProperty);
              const quote = key instanceof AST_SymbolClassProperty
                  ? property_token.quote
                  : undefined;
              const AST_ClassPropertyVariant = is_private
                  ? AST_ClassPrivateProperty
                  : AST_ClassProperty;
              if (is("operator", "=")) {
                  next();
                  return new AST_ClassPropertyVariant({
                      start,
                      static: is_static,
                      quote,
                      key,
                      value: expression(false),
                      end: prev()
                  });
              } else if (
                  is("name")
                  || is("privatename")
                  || is("operator", "*")
                  || is("punc", ";")
                  || is("punc", "}")
              ) {
                  return new AST_ClassPropertyVariant({
                      start,
                      static: is_static,
                      quote,
                      key,
                      end: prev()
                  });
              }
          }
      }

      function maybe_import_assertion() {
          if (is("name", "assert") && !has_newline_before(S.token)) {
              next();
              return object_or_destructuring_();
          }
          return null;
      }

      function import_statement() {
          var start = prev();

          var imported_name;
          var imported_names;
          if (is("name")) {
              imported_name = as_symbol(AST_SymbolImport);
          }

          if (is("punc", ",")) {
              next();
          }

          imported_names = map_names(true);

          if (imported_names || imported_name) {
              expect_token("name", "from");
          }
          var mod_str = S.token;
          if (mod_str.type !== "string") {
              unexpected();
          }
          next();

          const assert_clause = maybe_import_assertion();

          return new AST_Import({
              start,
              imported_name,
              imported_names,
              module_name: new AST_String({
                  start: mod_str,
                  value: mod_str.value,
                  quote: mod_str.quote,
                  end: mod_str,
              }),
              assert_clause,
              end: S.token,
          });
      }

      function import_meta() {
          var start = S.token;
          expect_token("operator", "import");
          expect_token("punc", ".");
          expect_token("name", "meta");
          return subscripts(new AST_ImportMeta({
              start: start,
              end: prev()
          }), false);
      }

      function map_name(is_import) {
          function make_symbol(type) {
              return new type({
                  name: as_property_name(),
                  start: prev(),
                  end: prev()
              });
          }

          var foreign_type = is_import ? AST_SymbolImportForeign : AST_SymbolExportForeign;
          var type = is_import ? AST_SymbolImport : AST_SymbolExport;
          var start = S.token;
          var foreign_name;
          var name;

          if (is_import) {
              foreign_name = make_symbol(foreign_type);
          } else {
              name = make_symbol(type);
          }
          if (is("name", "as")) {
              next();  // The "as" word
              if (is_import) {
                  name = make_symbol(type);
              } else {
                  foreign_name = make_symbol(foreign_type);
              }
          } else if (is_import) {
              name = new type(foreign_name);
          } else {
              foreign_name = new foreign_type(name);
          }

          return new AST_NameMapping({
              start: start,
              foreign_name: foreign_name,
              name: name,
              end: prev(),
          });
      }

      function map_nameAsterisk(is_import, name) {
          var foreign_type = is_import ? AST_SymbolImportForeign : AST_SymbolExportForeign;
          var type = is_import ? AST_SymbolImport : AST_SymbolExport;
          var start = S.token;
          var foreign_name;
          var end = prev();

          name = name || new type({
              name: "*",
              start: start,
              end: end,
          });

          foreign_name = new foreign_type({
              name: "*",
              start: start,
              end: end,
          });

          return new AST_NameMapping({
              start: start,
              foreign_name: foreign_name,
              name: name,
              end: end,
          });
      }

      function map_names(is_import) {
          var names;
          if (is("punc", "{")) {
              next();
              names = [];
              while (!is("punc", "}")) {
                  names.push(map_name(is_import));
                  if (is("punc", ",")) {
                      next();
                  }
              }
              next();
          } else if (is("operator", "*")) {
              var name;
              next();
              if (is_import && is("name", "as")) {
                  next();  // The "as" word
                  name = as_symbol(is_import ? AST_SymbolImport : AST_SymbolExportForeign);
              }
              names = [map_nameAsterisk(is_import, name)];
          }
          return names;
      }

      function export_statement() {
          var start = S.token;
          var is_default;
          var exported_names;

          if (is("keyword", "default")) {
              is_default = true;
              next();
          } else if (exported_names = map_names(false)) {
              if (is("name", "from")) {
                  next();

                  var mod_str = S.token;
                  if (mod_str.type !== "string") {
                      unexpected();
                  }
                  next();

                  const assert_clause = maybe_import_assertion();

                  return new AST_Export({
                      start: start,
                      is_default: is_default,
                      exported_names: exported_names,
                      module_name: new AST_String({
                          start: mod_str,
                          value: mod_str.value,
                          quote: mod_str.quote,
                          end: mod_str,
                      }),
                      end: prev(),
                      assert_clause
                  });
              } else {
                  return new AST_Export({
                      start: start,
                      is_default: is_default,
                      exported_names: exported_names,
                      end: prev(),
                  });
              }
          }

          var node;
          var exported_value;
          var exported_definition;
          if (is("punc", "{")
              || is_default
                  && (is("keyword", "class") || is("keyword", "function"))
                  && is_token(peek(), "punc")) {
              exported_value = expression(false);
              semicolon();
          } else if ((node = statement(is_default)) instanceof AST_Definitions && is_default) {
              unexpected(node.start);
          } else if (
              node instanceof AST_Definitions
              || node instanceof AST_Defun
              || node instanceof AST_DefClass
          ) {
              exported_definition = node;
          } else if (
              node instanceof AST_ClassExpression
              || node instanceof AST_Function
          ) {
              exported_value = node;
          } else if (node instanceof AST_SimpleStatement) {
              exported_value = node.body;
          } else {
              unexpected(node.start);
          }

          return new AST_Export({
              start: start,
              is_default: is_default,
              exported_value: exported_value,
              exported_definition: exported_definition,
              end: prev(),
              assert_clause: null
          });
      }

      function as_property_name() {
          var tmp = S.token;
          switch (tmp.type) {
            case "punc":
              if (tmp.value === "[") {
                  next();
                  var ex = expression(false);
                  expect("]");
                  return ex;
              } else unexpected(tmp);
            case "operator":
              if (tmp.value === "*") {
                  next();
                  return null;
              }
              if (!["delete", "in", "instanceof", "new", "typeof", "void"].includes(tmp.value)) {
                  unexpected(tmp);
              }
              /* falls through */
            case "name":
            case "privatename":
            case "string":
            case "num":
            case "big_int":
            case "keyword":
            case "atom":
              next();
              return tmp.value;
            default:
              unexpected(tmp);
          }
      }

      function as_name() {
          var tmp = S.token;
          if (tmp.type != "name" && tmp.type != "privatename") unexpected();
          next();
          return tmp.value;
      }

      function _make_symbol(type) {
          var name = S.token.value;
          return new (name == "this" ? AST_This :
                      name == "super" ? AST_Super :
                      type)({
              name  : String(name),
              start : S.token,
              end   : S.token
          });
      }

      function _verify_symbol(sym) {
          var name = sym.name;
          if (is_in_generator() && name == "yield") {
              token_error(sym.start, "Yield cannot be used as identifier inside generators");
          }
          if (S.input.has_directive("use strict")) {
              if (name == "yield") {
                  token_error(sym.start, "Unexpected yield identifier inside strict mode");
              }
              if (sym instanceof AST_SymbolDeclaration && (name == "arguments" || name == "eval")) {
                  token_error(sym.start, "Unexpected " + name + " in strict mode");
              }
          }
      }

      function as_symbol(type, noerror) {
          if (!is("name")) {
              if (!noerror) croak("Name expected");
              return null;
          }
          var sym = _make_symbol(type);
          _verify_symbol(sym);
          next();
          return sym;
      }

      // Annotate AST_Call, AST_Lambda or AST_New with the special comments
      function annotate(node) {
          var start = node.start;
          var comments = start.comments_before;
          const comments_outside_parens = outer_comments_before_counts.get(start);
          var i = comments_outside_parens != null ? comments_outside_parens : comments.length;
          while (--i >= 0) {
              var comment = comments[i];
              if (/[@#]__/.test(comment.value)) {
                  if (/[@#]__PURE__/.test(comment.value)) {
                      set_annotation(node, _PURE);
                      break;
                  }
                  if (/[@#]__INLINE__/.test(comment.value)) {
                      set_annotation(node, _INLINE);
                      break;
                  }
                  if (/[@#]__NOINLINE__/.test(comment.value)) {
                      set_annotation(node, _NOINLINE);
                      break;
                  }
              }
          }
      }

      var subscripts = function(expr, allow_calls, is_chain) {
          var start = expr.start;
          if (is("punc", ".")) {
              next();
              const AST_DotVariant = is("privatename") ? AST_DotHash : AST_Dot;
              return subscripts(new AST_DotVariant({
                  start      : start,
                  expression : expr,
                  optional   : false,
                  property   : as_name(),
                  end        : prev()
              }), allow_calls, is_chain);
          }
          if (is("punc", "[")) {
              next();
              var prop = expression(true);
              expect("]");
              return subscripts(new AST_Sub({
                  start      : start,
                  expression : expr,
                  optional   : false,
                  property   : prop,
                  end        : prev()
              }), allow_calls, is_chain);
          }
          if (allow_calls && is("punc", "(")) {
              next();
              var call = new AST_Call({
                  start      : start,
                  expression : expr,
                  optional   : false,
                  args       : call_args(),
                  end        : prev()
              });
              annotate(call);
              return subscripts(call, true, is_chain);
          }

          if (is("punc", "?.")) {
              next();

              let chain_contents;

              if (allow_calls && is("punc", "(")) {
                  next();

                  const call = new AST_Call({
                      start,
                      optional: true,
                      expression: expr,
                      args: call_args(),
                      end: prev()
                  });
                  annotate(call);

                  chain_contents = subscripts(call, true, true);
              } else if (is("name") || is("privatename")) {
                  const AST_DotVariant = is("privatename") ? AST_DotHash : AST_Dot;
                  chain_contents = subscripts(new AST_DotVariant({
                      start,
                      expression: expr,
                      optional: true,
                      property: as_name(),
                      end: prev()
                  }), allow_calls, true);
              } else if (is("punc", "[")) {
                  next();
                  const property = expression(true);
                  expect("]");
                  chain_contents = subscripts(new AST_Sub({
                      start,
                      expression: expr,
                      optional: true,
                      property,
                      end: prev()
                  }), allow_calls, true);
              }

              if (!chain_contents) unexpected();

              if (chain_contents instanceof AST_Chain) return chain_contents;

              return new AST_Chain({
                  start,
                  expression: chain_contents,
                  end: prev()
              });
          }

          if (is("template_head")) {
              if (is_chain) {
                  // a?.b`c` is a syntax error
                  unexpected();
              }

              return subscripts(new AST_PrefixedTemplateString({
                  start: start,
                  prefix: expr,
                  template_string: template_string(),
                  end: prev()
              }), allow_calls);
          }

          return expr;
      };

      function call_args() {
          var args = [];
          while (!is("punc", ")")) {
              if (is("expand", "...")) {
                  next();
                  args.push(new AST_Expansion({
                      start: prev(),
                      expression: expression(false),
                      end: prev()
                  }));
              } else {
                  args.push(expression(false));
              }
              if (!is("punc", ")")) {
                  expect(",");
              }
          }
          next();
          return args;
      }

      var maybe_unary = function(allow_calls, allow_arrows) {
          var start = S.token;
          if (start.type == "name" && start.value == "await" && can_await()) {
              next();
              return _await_expression();
          }
          if (is("operator") && UNARY_PREFIX.has(start.value)) {
              next();
              handle_regexp();
              var ex = make_unary(AST_UnaryPrefix, start, maybe_unary(allow_calls));
              ex.start = start;
              ex.end = prev();
              return ex;
          }
          var val = expr_atom(allow_calls, allow_arrows);
          while (is("operator") && UNARY_POSTFIX.has(S.token.value) && !has_newline_before(S.token)) {
              if (val instanceof AST_Arrow) unexpected();
              val = make_unary(AST_UnaryPostfix, S.token, val);
              val.start = start;
              val.end = S.token;
              next();
          }
          return val;
      };

      function make_unary(ctor, token, expr) {
          var op = token.value;
          switch (op) {
            case "++":
            case "--":
              if (!is_assignable(expr))
                  croak("Invalid use of " + op + " operator", token.line, token.col, token.pos);
              break;
            case "delete":
              if (expr instanceof AST_SymbolRef && S.input.has_directive("use strict"))
                  croak("Calling delete on expression not allowed in strict mode", expr.start.line, expr.start.col, expr.start.pos);
              break;
          }
          return new ctor({ operator: op, expression: expr });
      }

      var expr_op = function(left, min_prec, no_in) {
          var op = is("operator") ? S.token.value : null;
          if (op == "in" && no_in) op = null;
          if (op == "**" && left instanceof AST_UnaryPrefix
              /* unary token in front not allowed - parenthesis required */
              && !is_token(left.start, "punc", "(")
              && left.operator !== "--" && left.operator !== "++")
                  unexpected(left.start);
          var prec = op != null ? PRECEDENCE[op] : null;
          if (prec != null && (prec > min_prec || (op === "**" && min_prec === prec))) {
              next();
              var right = expr_op(maybe_unary(true), prec, no_in);
              return expr_op(new AST_Binary({
                  start    : left.start,
                  left     : left,
                  operator : op,
                  right    : right,
                  end      : right.end
              }), min_prec, no_in);
          }
          return left;
      };

      function expr_ops(no_in) {
          return expr_op(maybe_unary(true, true), 0, no_in);
      }

      var maybe_conditional = function(no_in) {
          var start = S.token;
          var expr = expr_ops(no_in);
          if (is("operator", "?")) {
              next();
              var yes = expression(false);
              expect(":");
              return new AST_Conditional({
                  start       : start,
                  condition   : expr,
                  consequent  : yes,
                  alternative : expression(false, no_in),
                  end         : prev()
              });
          }
          return expr;
      };

      function is_assignable(expr) {
          return expr instanceof AST_PropAccess || expr instanceof AST_SymbolRef;
      }

      function to_destructuring(node) {
          if (node instanceof AST_Object) {
              node = new AST_Destructuring({
                  start: node.start,
                  names: node.properties.map(to_destructuring),
                  is_array: false,
                  end: node.end
              });
          } else if (node instanceof AST_Array) {
              var names = [];

              for (var i = 0; i < node.elements.length; i++) {
                  // Only allow expansion as last element
                  if (node.elements[i] instanceof AST_Expansion) {
                      if (i + 1 !== node.elements.length) {
                          token_error(node.elements[i].start, "Spread must the be last element in destructuring array");
                      }
                      node.elements[i].expression = to_destructuring(node.elements[i].expression);
                  }

                  names.push(to_destructuring(node.elements[i]));
              }

              node = new AST_Destructuring({
                  start: node.start,
                  names: names,
                  is_array: true,
                  end: node.end
              });
          } else if (node instanceof AST_ObjectProperty) {
              node.value = to_destructuring(node.value);
          } else if (node instanceof AST_Assign) {
              node = new AST_DefaultAssign({
                  start: node.start,
                  left: node.left,
                  operator: "=",
                  right: node.right,
                  end: node.end
              });
          }
          return node;
      }

      // In ES6, AssignmentExpression can also be an ArrowFunction
      var maybe_assign = function(no_in) {
          handle_regexp();
          var start = S.token;

          if (start.type == "name" && start.value == "yield") {
              if (is_in_generator()) {
                  next();
                  return _yield_expression();
              } else if (S.input.has_directive("use strict")) {
                  token_error(S.token, "Unexpected yield identifier inside strict mode");
              }
          }

          var left = maybe_conditional(no_in);
          var val = S.token.value;

          if (is("operator") && ASSIGNMENT.has(val)) {
              if (is_assignable(left) || (left = to_destructuring(left)) instanceof AST_Destructuring) {
                  next();

                  return new AST_Assign({
                      start    : start,
                      left     : left,
                      operator : val,
                      right    : maybe_assign(no_in),
                      logical  : LOGICAL_ASSIGNMENT.has(val),
                      end      : prev()
                  });
              }
              croak("Invalid assignment");
          }
          return left;
      };

      var expression = function(commas, no_in) {
          var start = S.token;
          var exprs = [];
          while (true) {
              exprs.push(maybe_assign(no_in));
              if (!commas || !is("punc", ",")) break;
              next();
              commas = true;
          }
          return exprs.length == 1 ? exprs[0] : new AST_Sequence({
              start       : start,
              expressions : exprs,
              end         : peek()
          });
      };

      function in_loop(cont) {
          ++S.in_loop;
          var ret = cont();
          --S.in_loop;
          return ret;
      }

      if (options.expression) {
          return expression(true);
      }

      return (function parse_toplevel() {
          var start = S.token;
          var body = [];
          S.input.push_directives_stack();
          if (options.module) S.input.add_directive("use strict");
          while (!is("eof")) {
              body.push(statement());
          }
          S.input.pop_directives_stack();
          var end = prev();
          var toplevel = options.toplevel;
          if (toplevel) {
              toplevel.body = toplevel.body.concat(body);
              toplevel.end = end;
          } else {
              toplevel = new AST_Toplevel({ start: start, body: body, end: end });
          }
          TEMPLATE_RAWS = new Map();
          return toplevel;
      })();

  }

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  function DEFNODE(type, props, ctor, methods, base = AST_Node) {
      if (!props) props = [];
      else props = props.split(/\s+/);
      var self_props = props;
      if (base && base.PROPS)
          props = props.concat(base.PROPS);
      const proto = base && Object.create(base.prototype);
      if (proto) {
          ctor.prototype = proto;
          ctor.BASE = base;
      }
      if (base) base.SUBCLASSES.push(ctor);
      ctor.prototype.CTOR = ctor;
      ctor.prototype.constructor = ctor;
      ctor.PROPS = props || null;
      ctor.SELF_PROPS = self_props;
      ctor.SUBCLASSES = [];
      if (type) {
          ctor.prototype.TYPE = ctor.TYPE = type;
      }
      if (methods) for (let i in methods) if (HOP(methods, i)) {
          if (i[0] === "$") {
              ctor[i.substr(1)] = methods[i];
          } else {
              ctor.prototype[i] = methods[i];
          }
      }
      ctor.DEFMETHOD = function(name, method) {
          this.prototype[name] = method;
      };
      return ctor;
  }

  const has_tok_flag = (tok, flag) => Boolean(tok.flags & flag);
  const set_tok_flag = (tok, flag, truth) => {
      if (truth) {
          tok.flags |= flag;
      } else {
          tok.flags &= ~flag;
      }
  };

  const TOK_FLAG_NLB          = 0b0001;
  const TOK_FLAG_QUOTE_SINGLE = 0b0010;
  const TOK_FLAG_QUOTE_EXISTS = 0b0100;
  const TOK_FLAG_TEMPLATE_END = 0b1000;

  class AST_Token {
      constructor(type, value, line, col, pos, nlb, comments_before, comments_after, file) {
          this.flags = (nlb ? 1 : 0);

          this.type = type;
          this.value = value;
          this.line = line;
          this.col = col;
          this.pos = pos;
          this.comments_before = comments_before;
          this.comments_after = comments_after;
          this.file = file;

          Object.seal(this);
      }

      get nlb() {
          return has_tok_flag(this, TOK_FLAG_NLB);
      }

      set nlb(new_nlb) {
          set_tok_flag(this, TOK_FLAG_NLB, new_nlb);
      }

      get quote() {
          return !has_tok_flag(this, TOK_FLAG_QUOTE_EXISTS)
              ? ""
              : (has_tok_flag(this, TOK_FLAG_QUOTE_SINGLE) ? "'" : '"');
      }

      set quote(quote_type) {
          set_tok_flag(this, TOK_FLAG_QUOTE_SINGLE, quote_type === "'");
          set_tok_flag(this, TOK_FLAG_QUOTE_EXISTS, !!quote_type);
      }

      get template_end() {
          return has_tok_flag(this, TOK_FLAG_TEMPLATE_END);
      }

      set template_end(new_template_end) {
          set_tok_flag(this, TOK_FLAG_TEMPLATE_END, new_template_end);
      }
  }

  var AST_Node = DEFNODE("Node", "start end", function AST_Node(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      _clone: function(deep) {
          if (deep) {
              var self = this.clone();
              return self.transform(new TreeTransformer(function(node) {
                  if (node !== self) {
                      return node.clone(true);
                  }
              }));
          }
          return new this.CTOR(this);
      },
      clone: function(deep) {
          return this._clone(deep);
      },
      $documentation: "Base class of all AST nodes",
      $propdoc: {
          start: "[AST_Token] The first token of this node",
          end: "[AST_Token] The last token of this node"
      },
      _walk: function(visitor) {
          return visitor._visit(this);
      },
      walk: function(visitor) {
          return this._walk(visitor); // not sure the indirection will be any help
      },
      _children_backwards: () => {}
  }, null);

  /* -----[ statements ]----- */

  var AST_Statement = DEFNODE("Statement", null, function AST_Statement(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class of all statements",
  });

  var AST_Debugger = DEFNODE("Debugger", null, function AST_Debugger(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Represents a debugger statement",
  }, AST_Statement);

  var AST_Directive = DEFNODE("Directive", "value quote", function AST_Directive(props) {
      if (props) {
          this.value = props.value;
          this.quote = props.quote;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Represents a directive, like \"use strict\";",
      $propdoc: {
          value: "[string] The value of this directive as a plain string (it's not an AST_String!)",
          quote: "[string] the original quote character"
      },
  }, AST_Statement);

  var AST_SimpleStatement = DEFNODE("SimpleStatement", "body", function AST_SimpleStatement(props) {
      if (props) {
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A statement consisting of an expression, i.e. a = 1 + 2",
      $propdoc: {
          body: "[AST_Node] an expression node (should not be instanceof AST_Statement)"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.body._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.body);
      }
  }, AST_Statement);

  function walk_body(node, visitor) {
      const body = node.body;
      for (var i = 0, len = body.length; i < len; i++) {
          body[i]._walk(visitor);
      }
  }

  function clone_block_scope(deep) {
      var clone = this._clone(deep);
      if (this.block_scope) {
          clone.block_scope = this.block_scope.clone();
      }
      return clone;
  }

  var AST_Block = DEFNODE("Block", "body block_scope", function AST_Block(props) {
      if (props) {
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A body of statements (usually braced)",
      $propdoc: {
          body: "[AST_Statement*] an array of statements",
          block_scope: "[AST_Scope] the block scope"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              walk_body(this, visitor);
          });
      },
      _children_backwards(push) {
          let i = this.body.length;
          while (i--) push(this.body[i]);
      },
      clone: clone_block_scope
  }, AST_Statement);

  var AST_BlockStatement = DEFNODE("BlockStatement", null, function AST_BlockStatement(props) {
      if (props) {
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A block statement",
  }, AST_Block);

  var AST_EmptyStatement = DEFNODE("EmptyStatement", null, function AST_EmptyStatement(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The empty statement (empty block or simply a semicolon)"
  }, AST_Statement);

  var AST_StatementWithBody = DEFNODE("StatementWithBody", "body", function AST_StatementWithBody(props) {
      if (props) {
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for all statements that contain one nested body: `For`, `ForIn`, `Do`, `While`, `With`",
      $propdoc: {
          body: "[AST_Statement] the body; this should always be present, even if it's an AST_EmptyStatement"
      }
  }, AST_Statement);

  var AST_LabeledStatement = DEFNODE("LabeledStatement", "label", function AST_LabeledStatement(props) {
      if (props) {
          this.label = props.label;
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Statement with a label",
      $propdoc: {
          label: "[AST_Label] a label definition"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.label._walk(visitor);
              this.body._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.body);
          push(this.label);
      },
      clone: function(deep) {
          var node = this._clone(deep);
          if (deep) {
              var label = node.label;
              var def = this.label;
              node.walk(new TreeWalker(function(node) {
                  if (node instanceof AST_LoopControl
                      && node.label && node.label.thedef === def) {
                      node.label.thedef = label;
                      label.references.push(node);
                  }
              }));
          }
          return node;
      }
  }, AST_StatementWithBody);

  var AST_IterationStatement = DEFNODE(
      "IterationStatement",
      "block_scope",
      function AST_IterationStatement(props) {
          if (props) {
              this.block_scope = props.block_scope;
              this.body = props.body;
              this.start = props.start;
              this.end = props.end;
          }

          this.flags = 0;
      },
      {
          $documentation: "Internal class.  All loops inherit from it.",
          $propdoc: {
              block_scope: "[AST_Scope] the block scope for this iteration statement."
          },
          clone: clone_block_scope
      },
      AST_StatementWithBody
  );

  var AST_DWLoop = DEFNODE("DWLoop", "condition", function AST_DWLoop(props) {
      if (props) {
          this.condition = props.condition;
          this.block_scope = props.block_scope;
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for do/while statements",
      $propdoc: {
          condition: "[AST_Node] the loop condition.  Should not be instanceof AST_Statement"
      }
  }, AST_IterationStatement);

  var AST_Do = DEFNODE("Do", null, function AST_Do(props) {
      if (props) {
          this.condition = props.condition;
          this.block_scope = props.block_scope;
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `do` statement",
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.body._walk(visitor);
              this.condition._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.condition);
          push(this.body);
      }
  }, AST_DWLoop);

  var AST_While = DEFNODE("While", null, function AST_While(props) {
      if (props) {
          this.condition = props.condition;
          this.block_scope = props.block_scope;
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `while` statement",
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.condition._walk(visitor);
              this.body._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.body);
          push(this.condition);
      },
  }, AST_DWLoop);

  var AST_For = DEFNODE("For", "init condition step", function AST_For(props) {
      if (props) {
          this.init = props.init;
          this.condition = props.condition;
          this.step = props.step;
          this.block_scope = props.block_scope;
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `for` statement",
      $propdoc: {
          init: "[AST_Node?] the `for` initialization code, or null if empty",
          condition: "[AST_Node?] the `for` termination clause, or null if empty",
          step: "[AST_Node?] the `for` update clause, or null if empty"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              if (this.init) this.init._walk(visitor);
              if (this.condition) this.condition._walk(visitor);
              if (this.step) this.step._walk(visitor);
              this.body._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.body);
          if (this.step) push(this.step);
          if (this.condition) push(this.condition);
          if (this.init) push(this.init);
      },
  }, AST_IterationStatement);

  var AST_ForIn = DEFNODE("ForIn", "init object", function AST_ForIn(props) {
      if (props) {
          this.init = props.init;
          this.object = props.object;
          this.block_scope = props.block_scope;
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `for ... in` statement",
      $propdoc: {
          init: "[AST_Node] the `for/in` initialization code",
          object: "[AST_Node] the object that we're looping through"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.init._walk(visitor);
              this.object._walk(visitor);
              this.body._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.body);
          if (this.object) push(this.object);
          if (this.init) push(this.init);
      },
  }, AST_IterationStatement);

  var AST_ForOf = DEFNODE("ForOf", "await", function AST_ForOf(props) {
      if (props) {
          this.await = props.await;
          this.init = props.init;
          this.object = props.object;
          this.block_scope = props.block_scope;
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `for ... of` statement",
  }, AST_ForIn);

  var AST_With = DEFNODE("With", "expression", function AST_With(props) {
      if (props) {
          this.expression = props.expression;
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `with` statement",
      $propdoc: {
          expression: "[AST_Node] the `with` expression"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.expression._walk(visitor);
              this.body._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.body);
          push(this.expression);
      },
  }, AST_StatementWithBody);

  /* -----[ scope and functions ]----- */

  var AST_Scope = DEFNODE(
      "Scope",
      "variables uses_with uses_eval parent_scope enclosed cname",
      function AST_Scope(props) {
          if (props) {
              this.variables = props.variables;
              this.uses_with = props.uses_with;
              this.uses_eval = props.uses_eval;
              this.parent_scope = props.parent_scope;
              this.enclosed = props.enclosed;
              this.cname = props.cname;
              this.body = props.body;
              this.block_scope = props.block_scope;
              this.start = props.start;
              this.end = props.end;
          }

          this.flags = 0;
      },
      {
          $documentation: "Base class for all statements introducing a lexical scope",
          $propdoc: {
              variables: "[Map/S] a map of name -> SymbolDef for all variables/functions defined in this scope",
              uses_with: "[boolean/S] tells whether this scope uses the `with` statement",
              uses_eval: "[boolean/S] tells whether this scope contains a direct call to the global `eval`",
              parent_scope: "[AST_Scope?/S] link to the parent scope",
              enclosed: "[SymbolDef*/S] a list of all symbol definitions that are accessed from this scope or any subscopes",
              cname: "[integer/S] current index for mangling variables (used internally by the mangler)",
          },
          get_defun_scope: function() {
              var self = this;
              while (self.is_block_scope()) {
                  self = self.parent_scope;
              }
              return self;
          },
          clone: function(deep, toplevel) {
              var node = this._clone(deep);
              if (deep && this.variables && toplevel && !this._block_scope) {
                  node.figure_out_scope({}, {
                      toplevel: toplevel,
                      parent_scope: this.parent_scope
                  });
              } else {
                  if (this.variables) node.variables = new Map(this.variables);
                  if (this.enclosed) node.enclosed = this.enclosed.slice();
                  if (this._block_scope) node._block_scope = this._block_scope;
              }
              return node;
          },
          pinned: function() {
              return this.uses_eval || this.uses_with;
          }
      },
      AST_Block
  );

  var AST_Toplevel = DEFNODE("Toplevel", "globals", function AST_Toplevel(props) {
      if (props) {
          this.globals = props.globals;
          this.variables = props.variables;
          this.uses_with = props.uses_with;
          this.uses_eval = props.uses_eval;
          this.parent_scope = props.parent_scope;
          this.enclosed = props.enclosed;
          this.cname = props.cname;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The toplevel scope",
      $propdoc: {
          globals: "[Map/S] a map of name -> SymbolDef for all undeclared names",
      },
      wrap_commonjs: function(name) {
          var body = this.body;
          var wrapped_tl = "(function(exports){'$ORIG';})(typeof " + name + "=='undefined'?(" + name + "={}):" + name + ");";
          wrapped_tl = parse(wrapped_tl);
          wrapped_tl = wrapped_tl.transform(new TreeTransformer(function(node) {
              if (node instanceof AST_Directive && node.value == "$ORIG") {
                  return MAP.splice(body);
              }
          }));
          return wrapped_tl;
      },
      wrap_enclose: function(args_values) {
          if (typeof args_values != "string") args_values = "";
          var index = args_values.indexOf(":");
          if (index < 0) index = args_values.length;
          var body = this.body;
          return parse([
              "(function(",
              args_values.slice(0, index),
              '){"$ORIG"})(',
              args_values.slice(index + 1),
              ")"
          ].join("")).transform(new TreeTransformer(function(node) {
              if (node instanceof AST_Directive && node.value == "$ORIG") {
                  return MAP.splice(body);
              }
          }));
      }
  }, AST_Scope);

  var AST_Expansion = DEFNODE("Expansion", "expression", function AST_Expansion(props) {
      if (props) {
          this.expression = props.expression;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "An expandible argument, such as ...rest, a splat, such as [1,2,...all], or an expansion in a variable declaration, such as var [first, ...rest] = list",
      $propdoc: {
          expression: "[AST_Node] the thing to be expanded"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.expression.walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.expression);
      },
  });

  var AST_Lambda = DEFNODE(
      "Lambda",
      "name argnames uses_arguments is_generator async",
      function AST_Lambda(props) {
          if (props) {
              this.name = props.name;
              this.argnames = props.argnames;
              this.uses_arguments = props.uses_arguments;
              this.is_generator = props.is_generator;
              this.async = props.async;
              this.variables = props.variables;
              this.uses_with = props.uses_with;
              this.uses_eval = props.uses_eval;
              this.parent_scope = props.parent_scope;
              this.enclosed = props.enclosed;
              this.cname = props.cname;
              this.body = props.body;
              this.block_scope = props.block_scope;
              this.start = props.start;
              this.end = props.end;
          }

          this.flags = 0;
      },
      {
          $documentation: "Base class for functions",
          $propdoc: {
              name: "[AST_SymbolDeclaration?] the name of this function",
              argnames: "[AST_SymbolFunarg|AST_Destructuring|AST_Expansion|AST_DefaultAssign*] array of function arguments, destructurings, or expanding arguments",
              uses_arguments: "[boolean/S] tells whether this function accesses the arguments array",
              is_generator: "[boolean] is this a generator method",
              async: "[boolean] is this method async",
          },
          args_as_names: function () {
              var out = [];
              for (var i = 0; i < this.argnames.length; i++) {
                  if (this.argnames[i] instanceof AST_Destructuring) {
                      out.push(...this.argnames[i].all_symbols());
                  } else {
                      out.push(this.argnames[i]);
                  }
              }
              return out;
          },
          _walk: function(visitor) {
              return visitor._visit(this, function() {
                  if (this.name) this.name._walk(visitor);
                  var argnames = this.argnames;
                  for (var i = 0, len = argnames.length; i < len; i++) {
                      argnames[i]._walk(visitor);
                  }
                  walk_body(this, visitor);
              });
          },
          _children_backwards(push) {
              let i = this.body.length;
              while (i--) push(this.body[i]);

              i = this.argnames.length;
              while (i--) push(this.argnames[i]);

              if (this.name) push(this.name);
          },
          is_braceless() {
              return this.body[0] instanceof AST_Return && this.body[0].value;
          },
          // Default args and expansion don't count, so .argnames.length doesn't cut it
          length_property() {
              let length = 0;

              for (const arg of this.argnames) {
                  if (arg instanceof AST_SymbolFunarg || arg instanceof AST_Destructuring) {
                      length++;
                  }
              }

              return length;
          }
      },
      AST_Scope
  );

  var AST_Accessor = DEFNODE("Accessor", null, function AST_Accessor(props) {
      if (props) {
          this.name = props.name;
          this.argnames = props.argnames;
          this.uses_arguments = props.uses_arguments;
          this.is_generator = props.is_generator;
          this.async = props.async;
          this.variables = props.variables;
          this.uses_with = props.uses_with;
          this.uses_eval = props.uses_eval;
          this.parent_scope = props.parent_scope;
          this.enclosed = props.enclosed;
          this.cname = props.cname;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A setter/getter function.  The `name` property is always null."
  }, AST_Lambda);

  var AST_Function = DEFNODE("Function", null, function AST_Function(props) {
      if (props) {
          this.name = props.name;
          this.argnames = props.argnames;
          this.uses_arguments = props.uses_arguments;
          this.is_generator = props.is_generator;
          this.async = props.async;
          this.variables = props.variables;
          this.uses_with = props.uses_with;
          this.uses_eval = props.uses_eval;
          this.parent_scope = props.parent_scope;
          this.enclosed = props.enclosed;
          this.cname = props.cname;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A function expression"
  }, AST_Lambda);

  var AST_Arrow = DEFNODE("Arrow", null, function AST_Arrow(props) {
      if (props) {
          this.name = props.name;
          this.argnames = props.argnames;
          this.uses_arguments = props.uses_arguments;
          this.is_generator = props.is_generator;
          this.async = props.async;
          this.variables = props.variables;
          this.uses_with = props.uses_with;
          this.uses_eval = props.uses_eval;
          this.parent_scope = props.parent_scope;
          this.enclosed = props.enclosed;
          this.cname = props.cname;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "An ES6 Arrow function ((a) => b)"
  }, AST_Lambda);

  var AST_Defun = DEFNODE("Defun", null, function AST_Defun(props) {
      if (props) {
          this.name = props.name;
          this.argnames = props.argnames;
          this.uses_arguments = props.uses_arguments;
          this.is_generator = props.is_generator;
          this.async = props.async;
          this.variables = props.variables;
          this.uses_with = props.uses_with;
          this.uses_eval = props.uses_eval;
          this.parent_scope = props.parent_scope;
          this.enclosed = props.enclosed;
          this.cname = props.cname;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A function definition"
  }, AST_Lambda);

  /* -----[ DESTRUCTURING ]----- */
  var AST_Destructuring = DEFNODE("Destructuring", "names is_array", function AST_Destructuring(props) {
      if (props) {
          this.names = props.names;
          this.is_array = props.is_array;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A destructuring of several names. Used in destructuring assignment and with destructuring function argument names",
      $propdoc: {
          "names": "[AST_Node*] Array of properties or elements",
          "is_array": "[Boolean] Whether the destructuring represents an object or array"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.names.forEach(function(name) {
                  name._walk(visitor);
              });
          });
      },
      _children_backwards(push) {
          let i = this.names.length;
          while (i--) push(this.names[i]);
      },
      all_symbols: function() {
          var out = [];
          this.walk(new TreeWalker(function (node) {
              if (node instanceof AST_Symbol) {
                  out.push(node);
              }
          }));
          return out;
      }
  });

  var AST_PrefixedTemplateString = DEFNODE(
      "PrefixedTemplateString",
      "template_string prefix",
      function AST_PrefixedTemplateString(props) {
          if (props) {
              this.template_string = props.template_string;
              this.prefix = props.prefix;
              this.start = props.start;
              this.end = props.end;
          }

          this.flags = 0;
      },
      {
          $documentation: "A templatestring with a prefix, such as String.raw`foobarbaz`",
          $propdoc: {
              template_string: "[AST_TemplateString] The template string",
              prefix: "[AST_Node] The prefix, which will get called."
          },
          _walk: function(visitor) {
              return visitor._visit(this, function () {
                  this.prefix._walk(visitor);
                  this.template_string._walk(visitor);
              });
          },
          _children_backwards(push) {
              push(this.template_string);
              push(this.prefix);
          },
      }
  );

  var AST_TemplateString = DEFNODE("TemplateString", "segments", function AST_TemplateString(props) {
      if (props) {
          this.segments = props.segments;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A template string literal",
      $propdoc: {
          segments: "[AST_Node*] One or more segments, starting with AST_TemplateSegment. AST_Node may follow AST_TemplateSegment, but each AST_Node must be followed by AST_TemplateSegment."
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.segments.forEach(function(seg) {
                  seg._walk(visitor);
              });
          });
      },
      _children_backwards(push) {
          let i = this.segments.length;
          while (i--) push(this.segments[i]);
      }
  });

  var AST_TemplateSegment = DEFNODE("TemplateSegment", "value raw", function AST_TemplateSegment(props) {
      if (props) {
          this.value = props.value;
          this.raw = props.raw;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A segment of a template string literal",
      $propdoc: {
          value: "Content of the segment",
          raw: "Raw source of the segment",
      }
  });

  /* -----[ JUMPS ]----- */

  var AST_Jump = DEFNODE("Jump", null, function AST_Jump(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for “jumps” (for now that's `return`, `throw`, `break` and `continue`)"
  }, AST_Statement);

  var AST_Exit = DEFNODE("Exit", "value", function AST_Exit(props) {
      if (props) {
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for “exits” (`return` and `throw`)",
      $propdoc: {
          value: "[AST_Node?] the value returned or thrown by this statement; could be null for AST_Return"
      },
      _walk: function(visitor) {
          return visitor._visit(this, this.value && function() {
              this.value._walk(visitor);
          });
      },
      _children_backwards(push) {
          if (this.value) push(this.value);
      },
  }, AST_Jump);

  var AST_Return = DEFNODE("Return", null, function AST_Return(props) {
      if (props) {
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `return` statement"
  }, AST_Exit);

  var AST_Throw = DEFNODE("Throw", null, function AST_Throw(props) {
      if (props) {
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `throw` statement"
  }, AST_Exit);

  var AST_LoopControl = DEFNODE("LoopControl", "label", function AST_LoopControl(props) {
      if (props) {
          this.label = props.label;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for loop control statements (`break` and `continue`)",
      $propdoc: {
          label: "[AST_LabelRef?] the label, or null if none",
      },
      _walk: function(visitor) {
          return visitor._visit(this, this.label && function() {
              this.label._walk(visitor);
          });
      },
      _children_backwards(push) {
          if (this.label) push(this.label);
      },
  }, AST_Jump);

  var AST_Break = DEFNODE("Break", null, function AST_Break(props) {
      if (props) {
          this.label = props.label;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `break` statement"
  }, AST_LoopControl);

  var AST_Continue = DEFNODE("Continue", null, function AST_Continue(props) {
      if (props) {
          this.label = props.label;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `continue` statement"
  }, AST_LoopControl);

  var AST_Await = DEFNODE("Await", "expression", function AST_Await(props) {
      if (props) {
          this.expression = props.expression;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "An `await` statement",
      $propdoc: {
          expression: "[AST_Node] the mandatory expression being awaited",
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.expression._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.expression);
      },
  });

  var AST_Yield = DEFNODE("Yield", "expression is_star", function AST_Yield(props) {
      if (props) {
          this.expression = props.expression;
          this.is_star = props.is_star;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `yield` statement",
      $propdoc: {
          expression: "[AST_Node?] the value returned or thrown by this statement; could be null (representing undefined) but only when is_star is set to false",
          is_star: "[Boolean] Whether this is a yield or yield* statement"
      },
      _walk: function(visitor) {
          return visitor._visit(this, this.expression && function() {
              this.expression._walk(visitor);
          });
      },
      _children_backwards(push) {
          if (this.expression) push(this.expression);
      }
  });

  /* -----[ IF ]----- */

  var AST_If = DEFNODE("If", "condition alternative", function AST_If(props) {
      if (props) {
          this.condition = props.condition;
          this.alternative = props.alternative;
          this.body = props.body;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `if` statement",
      $propdoc: {
          condition: "[AST_Node] the `if` condition",
          alternative: "[AST_Statement?] the `else` part, or null if not present"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.condition._walk(visitor);
              this.body._walk(visitor);
              if (this.alternative) this.alternative._walk(visitor);
          });
      },
      _children_backwards(push) {
          if (this.alternative) {
              push(this.alternative);
          }
          push(this.body);
          push(this.condition);
      }
  }, AST_StatementWithBody);

  /* -----[ SWITCH ]----- */

  var AST_Switch = DEFNODE("Switch", "expression", function AST_Switch(props) {
      if (props) {
          this.expression = props.expression;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `switch` statement",
      $propdoc: {
          expression: "[AST_Node] the `switch` “discriminant”"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.expression._walk(visitor);
              walk_body(this, visitor);
          });
      },
      _children_backwards(push) {
          let i = this.body.length;
          while (i--) push(this.body[i]);
          push(this.expression);
      }
  }, AST_Block);

  var AST_SwitchBranch = DEFNODE("SwitchBranch", null, function AST_SwitchBranch(props) {
      if (props) {
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for `switch` branches",
  }, AST_Block);

  var AST_Default = DEFNODE("Default", null, function AST_Default(props) {
      if (props) {
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `default` switch branch",
  }, AST_SwitchBranch);

  var AST_Case = DEFNODE("Case", "expression", function AST_Case(props) {
      if (props) {
          this.expression = props.expression;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `case` switch branch",
      $propdoc: {
          expression: "[AST_Node] the `case` expression"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.expression._walk(visitor);
              walk_body(this, visitor);
          });
      },
      _children_backwards(push) {
          let i = this.body.length;
          while (i--) push(this.body[i]);
          push(this.expression);
      },
  }, AST_SwitchBranch);

  /* -----[ EXCEPTIONS ]----- */

  var AST_Try = DEFNODE("Try", "bcatch bfinally", function AST_Try(props) {
      if (props) {
          this.bcatch = props.bcatch;
          this.bfinally = props.bfinally;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `try` statement",
      $propdoc: {
          bcatch: "[AST_Catch?] the catch block, or null if not present",
          bfinally: "[AST_Finally?] the finally block, or null if not present"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              walk_body(this, visitor);
              if (this.bcatch) this.bcatch._walk(visitor);
              if (this.bfinally) this.bfinally._walk(visitor);
          });
      },
      _children_backwards(push) {
          if (this.bfinally) push(this.bfinally);
          if (this.bcatch) push(this.bcatch);
          let i = this.body.length;
          while (i--) push(this.body[i]);
      },
  }, AST_Block);

  var AST_Catch = DEFNODE("Catch", "argname", function AST_Catch(props) {
      if (props) {
          this.argname = props.argname;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `catch` node; only makes sense as part of a `try` statement",
      $propdoc: {
          argname: "[AST_SymbolCatch|AST_Destructuring|AST_Expansion|AST_DefaultAssign] symbol for the exception"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              if (this.argname) this.argname._walk(visitor);
              walk_body(this, visitor);
          });
      },
      _children_backwards(push) {
          let i = this.body.length;
          while (i--) push(this.body[i]);
          if (this.argname) push(this.argname);
      },
  }, AST_Block);

  var AST_Finally = DEFNODE("Finally", null, function AST_Finally(props) {
      if (props) {
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `finally` node; only makes sense as part of a `try` statement"
  }, AST_Block);

  /* -----[ VAR/CONST ]----- */

  var AST_Definitions = DEFNODE("Definitions", "definitions", function AST_Definitions(props) {
      if (props) {
          this.definitions = props.definitions;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for `var` or `const` nodes (variable declarations/initializations)",
      $propdoc: {
          definitions: "[AST_VarDef*] array of variable definitions"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              var definitions = this.definitions;
              for (var i = 0, len = definitions.length; i < len; i++) {
                  definitions[i]._walk(visitor);
              }
          });
      },
      _children_backwards(push) {
          let i = this.definitions.length;
          while (i--) push(this.definitions[i]);
      },
  }, AST_Statement);

  var AST_Var = DEFNODE("Var", null, function AST_Var(props) {
      if (props) {
          this.definitions = props.definitions;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `var` statement"
  }, AST_Definitions);

  var AST_Let = DEFNODE("Let", null, function AST_Let(props) {
      if (props) {
          this.definitions = props.definitions;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `let` statement"
  }, AST_Definitions);

  var AST_Const = DEFNODE("Const", null, function AST_Const(props) {
      if (props) {
          this.definitions = props.definitions;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A `const` statement"
  }, AST_Definitions);

  var AST_VarDef = DEFNODE("VarDef", "name value", function AST_VarDef(props) {
      if (props) {
          this.name = props.name;
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A variable declaration; only appears in a AST_Definitions node",
      $propdoc: {
          name: "[AST_Destructuring|AST_SymbolConst|AST_SymbolLet|AST_SymbolVar] name of the variable",
          value: "[AST_Node?] initializer, or null of there's no initializer"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.name._walk(visitor);
              if (this.value) this.value._walk(visitor);
          });
      },
      _children_backwards(push) {
          if (this.value) push(this.value);
          push(this.name);
      },
  });

  var AST_NameMapping = DEFNODE("NameMapping", "foreign_name name", function AST_NameMapping(props) {
      if (props) {
          this.foreign_name = props.foreign_name;
          this.name = props.name;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The part of the export/import statement that declare names from a module.",
      $propdoc: {
          foreign_name: "[AST_SymbolExportForeign|AST_SymbolImportForeign] The name being exported/imported (as specified in the module)",
          name: "[AST_SymbolExport|AST_SymbolImport] The name as it is visible to this module."
      },
      _walk: function (visitor) {
          return visitor._visit(this, function() {
              this.foreign_name._walk(visitor);
              this.name._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.name);
          push(this.foreign_name);
      },
  });

  var AST_Import = DEFNODE(
      "Import",
      "imported_name imported_names module_name assert_clause",
      function AST_Import(props) {
          if (props) {
              this.imported_name = props.imported_name;
              this.imported_names = props.imported_names;
              this.module_name = props.module_name;
              this.assert_clause = props.assert_clause;
              this.start = props.start;
              this.end = props.end;
          }

          this.flags = 0;
      },
      {
          $documentation: "An `import` statement",
          $propdoc: {
              imported_name: "[AST_SymbolImport] The name of the variable holding the module's default export.",
              imported_names: "[AST_NameMapping*] The names of non-default imported variables",
              module_name: "[AST_String] String literal describing where this module came from",
              assert_clause: "[AST_Object?] The import assertion"
          },
          _walk: function(visitor) {
              return visitor._visit(this, function() {
                  if (this.imported_name) {
                      this.imported_name._walk(visitor);
                  }
                  if (this.imported_names) {
                      this.imported_names.forEach(function(name_import) {
                          name_import._walk(visitor);
                      });
                  }
                  this.module_name._walk(visitor);
              });
          },
          _children_backwards(push) {
              push(this.module_name);
              if (this.imported_names) {
                  let i = this.imported_names.length;
                  while (i--) push(this.imported_names[i]);
              }
              if (this.imported_name) push(this.imported_name);
          },
      }
  );

  var AST_ImportMeta = DEFNODE("ImportMeta", null, function AST_ImportMeta(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A reference to import.meta",
  });

  var AST_Export = DEFNODE(
      "Export",
      "exported_definition exported_value is_default exported_names module_name assert_clause",
      function AST_Export(props) {
          if (props) {
              this.exported_definition = props.exported_definition;
              this.exported_value = props.exported_value;
              this.is_default = props.is_default;
              this.exported_names = props.exported_names;
              this.module_name = props.module_name;
              this.assert_clause = props.assert_clause;
              this.start = props.start;
              this.end = props.end;
          }

          this.flags = 0;
      },
      {
          $documentation: "An `export` statement",
          $propdoc: {
              exported_definition: "[AST_Defun|AST_Definitions|AST_DefClass?] An exported definition",
              exported_value: "[AST_Node?] An exported value",
              exported_names: "[AST_NameMapping*?] List of exported names",
              module_name: "[AST_String?] Name of the file to load exports from",
              is_default: "[Boolean] Whether this is the default exported value of this module",
              assert_clause: "[AST_Object?] The import assertion"
          },
          _walk: function (visitor) {
              return visitor._visit(this, function () {
                  if (this.exported_definition) {
                      this.exported_definition._walk(visitor);
                  }
                  if (this.exported_value) {
                      this.exported_value._walk(visitor);
                  }
                  if (this.exported_names) {
                      this.exported_names.forEach(function(name_export) {
                          name_export._walk(visitor);
                      });
                  }
                  if (this.module_name) {
                      this.module_name._walk(visitor);
                  }
              });
          },
          _children_backwards(push) {
              if (this.module_name) push(this.module_name);
              if (this.exported_names) {
                  let i = this.exported_names.length;
                  while (i--) push(this.exported_names[i]);
              }
              if (this.exported_value) push(this.exported_value);
              if (this.exported_definition) push(this.exported_definition);
          }
      },
      AST_Statement
  );

  /* -----[ OTHER ]----- */

  var AST_Call = DEFNODE(
      "Call",
      "expression args optional _annotations",
      function AST_Call(props) {
          if (props) {
              this.expression = props.expression;
              this.args = props.args;
              this.optional = props.optional;
              this._annotations = props._annotations;
              this.start = props.start;
              this.end = props.end;
              this.initialize();
          }

          this.flags = 0;
      },
      {
          $documentation: "A function call expression",
          $propdoc: {
              expression: "[AST_Node] expression to invoke as function",
              args: "[AST_Node*] array of arguments",
              optional: "[boolean] whether this is an optional call (IE ?.() )",
              _annotations: "[number] bitfield containing information about the call"
          },
          initialize() {
              if (this._annotations == null) this._annotations = 0;
          },
          _walk(visitor) {
              return visitor._visit(this, function() {
                  var args = this.args;
                  for (var i = 0, len = args.length; i < len; i++) {
                      args[i]._walk(visitor);
                  }
                  this.expression._walk(visitor);  // TODO why do we need to crawl this last?
              });
          },
          _children_backwards(push) {
              let i = this.args.length;
              while (i--) push(this.args[i]);
              push(this.expression);
          },
      }
  );

  var AST_New = DEFNODE("New", null, function AST_New(props) {
      if (props) {
          this.expression = props.expression;
          this.args = props.args;
          this.optional = props.optional;
          this._annotations = props._annotations;
          this.start = props.start;
          this.end = props.end;
          this.initialize();
      }

      this.flags = 0;
  }, {
      $documentation: "An object instantiation.  Derives from a function call since it has exactly the same properties"
  }, AST_Call);

  var AST_Sequence = DEFNODE("Sequence", "expressions", function AST_Sequence(props) {
      if (props) {
          this.expressions = props.expressions;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A sequence expression (comma-separated expressions)",
      $propdoc: {
          expressions: "[AST_Node*] array of expressions (at least two)"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.expressions.forEach(function(node) {
                  node._walk(visitor);
              });
          });
      },
      _children_backwards(push) {
          let i = this.expressions.length;
          while (i--) push(this.expressions[i]);
      },
  });

  var AST_PropAccess = DEFNODE(
      "PropAccess",
      "expression property optional",
      function AST_PropAccess(props) {
          if (props) {
              this.expression = props.expression;
              this.property = props.property;
              this.optional = props.optional;
              this.start = props.start;
              this.end = props.end;
          }

          this.flags = 0;
      },
      {
          $documentation: "Base class for property access expressions, i.e. `a.foo` or `a[\"foo\"]`",
          $propdoc: {
              expression: "[AST_Node] the “container” expression",
              property: "[AST_Node|string] the property to access.  For AST_Dot & AST_DotHash this is always a plain string, while for AST_Sub it's an arbitrary AST_Node",

              optional: "[boolean] whether this is an optional property access (IE ?.)"
          }
      }
  );

  var AST_Dot = DEFNODE("Dot", "quote", function AST_Dot(props) {
      if (props) {
          this.quote = props.quote;
          this.expression = props.expression;
          this.property = props.property;
          this.optional = props.optional;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A dotted property access expression",
      $propdoc: {
          quote: "[string] the original quote character when transformed from AST_Sub",
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.expression._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.expression);
      },
  }, AST_PropAccess);

  var AST_DotHash = DEFNODE("DotHash", "", function AST_DotHash(props) {
      if (props) {
          this.expression = props.expression;
          this.property = props.property;
          this.optional = props.optional;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A dotted property access to a private property",
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.expression._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.expression);
      },
  }, AST_PropAccess);

  var AST_Sub = DEFNODE("Sub", null, function AST_Sub(props) {
      if (props) {
          this.expression = props.expression;
          this.property = props.property;
          this.optional = props.optional;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Index-style property access, i.e. `a[\"foo\"]`",
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.expression._walk(visitor);
              this.property._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.property);
          push(this.expression);
      },
  }, AST_PropAccess);

  var AST_Chain = DEFNODE("Chain", "expression", function AST_Chain(props) {
      if (props) {
          this.expression = props.expression;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A chain expression like a?.b?.(c)?.[d]",
      $propdoc: {
          expression: "[AST_Call|AST_Dot|AST_DotHash|AST_Sub] chain element."
      },
      _walk: function (visitor) {
          return visitor._visit(this, function() {
              this.expression._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.expression);
      },
  });

  var AST_Unary = DEFNODE("Unary", "operator expression", function AST_Unary(props) {
      if (props) {
          this.operator = props.operator;
          this.expression = props.expression;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for unary expressions",
      $propdoc: {
          operator: "[string] the operator",
          expression: "[AST_Node] expression that this unary operator applies to"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.expression._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.expression);
      },
  });

  var AST_UnaryPrefix = DEFNODE("UnaryPrefix", null, function AST_UnaryPrefix(props) {
      if (props) {
          this.operator = props.operator;
          this.expression = props.expression;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Unary prefix expression, i.e. `typeof i` or `++i`"
  }, AST_Unary);

  var AST_UnaryPostfix = DEFNODE("UnaryPostfix", null, function AST_UnaryPostfix(props) {
      if (props) {
          this.operator = props.operator;
          this.expression = props.expression;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Unary postfix expression, i.e. `i++`"
  }, AST_Unary);

  var AST_Binary = DEFNODE("Binary", "operator left right", function AST_Binary(props) {
      if (props) {
          this.operator = props.operator;
          this.left = props.left;
          this.right = props.right;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Binary expression, i.e. `a + b`",
      $propdoc: {
          left: "[AST_Node] left-hand side expression",
          operator: "[string] the operator",
          right: "[AST_Node] right-hand side expression"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              this.left._walk(visitor);
              this.right._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.right);
          push(this.left);
      },
  });

  var AST_Conditional = DEFNODE(
      "Conditional",
      "condition consequent alternative",
      function AST_Conditional(props) {
          if (props) {
              this.condition = props.condition;
              this.consequent = props.consequent;
              this.alternative = props.alternative;
              this.start = props.start;
              this.end = props.end;
          }

          this.flags = 0;
      },
      {
          $documentation: "Conditional expression using the ternary operator, i.e. `a ? b : c`",
          $propdoc: {
              condition: "[AST_Node]",
              consequent: "[AST_Node]",
              alternative: "[AST_Node]"
          },
          _walk: function(visitor) {
              return visitor._visit(this, function() {
                  this.condition._walk(visitor);
                  this.consequent._walk(visitor);
                  this.alternative._walk(visitor);
              });
          },
          _children_backwards(push) {
              push(this.alternative);
              push(this.consequent);
              push(this.condition);
          },
      }
  );

  var AST_Assign = DEFNODE("Assign", "logical", function AST_Assign(props) {
      if (props) {
          this.logical = props.logical;
          this.operator = props.operator;
          this.left = props.left;
          this.right = props.right;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "An assignment expression — `a = b + 5`",
      $propdoc: {
          logical: "Whether it's a logical assignment"
      }
  }, AST_Binary);

  var AST_DefaultAssign = DEFNODE("DefaultAssign", null, function AST_DefaultAssign(props) {
      if (props) {
          this.operator = props.operator;
          this.left = props.left;
          this.right = props.right;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A default assignment expression like in `(a = 3) => a`"
  }, AST_Binary);

  /* -----[ LITERALS ]----- */

  var AST_Array = DEFNODE("Array", "elements", function AST_Array(props) {
      if (props) {
          this.elements = props.elements;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "An array literal",
      $propdoc: {
          elements: "[AST_Node*] array of elements"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              var elements = this.elements;
              for (var i = 0, len = elements.length; i < len; i++) {
                  elements[i]._walk(visitor);
              }
          });
      },
      _children_backwards(push) {
          let i = this.elements.length;
          while (i--) push(this.elements[i]);
      },
  });

  var AST_Object = DEFNODE("Object", "properties", function AST_Object(props) {
      if (props) {
          this.properties = props.properties;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "An object literal",
      $propdoc: {
          properties: "[AST_ObjectProperty*] array of properties"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              var properties = this.properties;
              for (var i = 0, len = properties.length; i < len; i++) {
                  properties[i]._walk(visitor);
              }
          });
      },
      _children_backwards(push) {
          let i = this.properties.length;
          while (i--) push(this.properties[i]);
      },
  });

  var AST_ObjectProperty = DEFNODE("ObjectProperty", "key value", function AST_ObjectProperty(props) {
      if (props) {
          this.key = props.key;
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for literal object properties",
      $propdoc: {
          key: "[string|AST_Node] property name. For ObjectKeyVal this is a string. For getters, setters and computed property this is an AST_Node.",
          value: "[AST_Node] property value.  For getters and setters this is an AST_Accessor."
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              if (this.key instanceof AST_Node)
                  this.key._walk(visitor);
              this.value._walk(visitor);
          });
      },
      _children_backwards(push) {
          push(this.value);
          if (this.key instanceof AST_Node) push(this.key);
      }
  });

  var AST_ObjectKeyVal = DEFNODE("ObjectKeyVal", "quote", function AST_ObjectKeyVal(props) {
      if (props) {
          this.quote = props.quote;
          this.key = props.key;
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A key: value object property",
      $propdoc: {
          quote: "[string] the original quote character"
      },
      computed_key() {
          return this.key instanceof AST_Node;
      }
  }, AST_ObjectProperty);

  var AST_PrivateSetter = DEFNODE("PrivateSetter", "static", function AST_PrivateSetter(props) {
      if (props) {
          this.static = props.static;
          this.key = props.key;
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $propdoc: {
          static: "[boolean] whether this is a static private setter"
      },
      $documentation: "A private setter property",
      computed_key() {
          return false;
      }
  }, AST_ObjectProperty);

  var AST_PrivateGetter = DEFNODE("PrivateGetter", "static", function AST_PrivateGetter(props) {
      if (props) {
          this.static = props.static;
          this.key = props.key;
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $propdoc: {
          static: "[boolean] whether this is a static private getter"
      },
      $documentation: "A private getter property",
      computed_key() {
          return false;
      }
  }, AST_ObjectProperty);

  var AST_ObjectSetter = DEFNODE("ObjectSetter", "quote static", function AST_ObjectSetter(props) {
      if (props) {
          this.quote = props.quote;
          this.static = props.static;
          this.key = props.key;
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $propdoc: {
          quote: "[string|undefined] the original quote character, if any",
          static: "[boolean] whether this is a static setter (classes only)"
      },
      $documentation: "An object setter property",
      computed_key() {
          return !(this.key instanceof AST_SymbolMethod);
      }
  }, AST_ObjectProperty);

  var AST_ObjectGetter = DEFNODE("ObjectGetter", "quote static", function AST_ObjectGetter(props) {
      if (props) {
          this.quote = props.quote;
          this.static = props.static;
          this.key = props.key;
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $propdoc: {
          quote: "[string|undefined] the original quote character, if any",
          static: "[boolean] whether this is a static getter (classes only)"
      },
      $documentation: "An object getter property",
      computed_key() {
          return !(this.key instanceof AST_SymbolMethod);
      }
  }, AST_ObjectProperty);

  var AST_ConciseMethod = DEFNODE(
      "ConciseMethod",
      "quote static is_generator async",
      function AST_ConciseMethod(props) {
          if (props) {
              this.quote = props.quote;
              this.static = props.static;
              this.is_generator = props.is_generator;
              this.async = props.async;
              this.key = props.key;
              this.value = props.value;
              this.start = props.start;
              this.end = props.end;
          }

          this.flags = 0;
      },
      {
          $propdoc: {
              quote: "[string|undefined] the original quote character, if any",
              static: "[boolean] is this method static (classes only)",
              is_generator: "[boolean] is this a generator method",
              async: "[boolean] is this method async",
          },
          $documentation: "An ES6 concise method inside an object or class",
          computed_key() {
              return !(this.key instanceof AST_SymbolMethod);
          }
      },
      AST_ObjectProperty
  );

  var AST_PrivateMethod = DEFNODE("PrivateMethod", "", function AST_PrivateMethod(props) {
      if (props) {
          this.quote = props.quote;
          this.static = props.static;
          this.is_generator = props.is_generator;
          this.async = props.async;
          this.key = props.key;
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A private class method inside a class",
  }, AST_ConciseMethod);

  var AST_Class = DEFNODE("Class", "name extends properties", function AST_Class(props) {
      if (props) {
          this.name = props.name;
          this.extends = props.extends;
          this.properties = props.properties;
          this.variables = props.variables;
          this.uses_with = props.uses_with;
          this.uses_eval = props.uses_eval;
          this.parent_scope = props.parent_scope;
          this.enclosed = props.enclosed;
          this.cname = props.cname;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $propdoc: {
          name: "[AST_SymbolClass|AST_SymbolDefClass?] optional class name.",
          extends: "[AST_Node]? optional parent class",
          properties: "[AST_ObjectProperty*] array of properties"
      },
      $documentation: "An ES6 class",
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              if (this.name) {
                  this.name._walk(visitor);
              }
              if (this.extends) {
                  this.extends._walk(visitor);
              }
              this.properties.forEach((prop) => prop._walk(visitor));
          });
      },
      _children_backwards(push) {
          let i = this.properties.length;
          while (i--) push(this.properties[i]);
          if (this.extends) push(this.extends);
          if (this.name) push(this.name);
      },
  }, AST_Scope /* TODO a class might have a scope but it's not a scope */);

  var AST_ClassProperty = DEFNODE("ClassProperty", "static quote", function AST_ClassProperty(props) {
      if (props) {
          this.static = props.static;
          this.quote = props.quote;
          this.key = props.key;
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A class property",
      $propdoc: {
          static: "[boolean] whether this is a static key",
          quote: "[string] which quote is being used"
      },
      _walk: function(visitor) {
          return visitor._visit(this, function() {
              if (this.key instanceof AST_Node)
                  this.key._walk(visitor);
              if (this.value instanceof AST_Node)
                  this.value._walk(visitor);
          });
      },
      _children_backwards(push) {
          if (this.value instanceof AST_Node) push(this.value);
          if (this.key instanceof AST_Node) push(this.key);
      },
      computed_key() {
          return !(this.key instanceof AST_SymbolClassProperty);
      }
  }, AST_ObjectProperty);

  var AST_ClassPrivateProperty = DEFNODE("ClassPrivateProperty", "", function AST_ClassPrivateProperty(props) {
      if (props) {
          this.static = props.static;
          this.quote = props.quote;
          this.key = props.key;
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A class property for a private property",
  }, AST_ClassProperty);

  var AST_DefClass = DEFNODE("DefClass", null, function AST_DefClass(props) {
      if (props) {
          this.name = props.name;
          this.extends = props.extends;
          this.properties = props.properties;
          this.variables = props.variables;
          this.uses_with = props.uses_with;
          this.uses_eval = props.uses_eval;
          this.parent_scope = props.parent_scope;
          this.enclosed = props.enclosed;
          this.cname = props.cname;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A class definition",
  }, AST_Class);

  var AST_ClassExpression = DEFNODE("ClassExpression", null, function AST_ClassExpression(props) {
      if (props) {
          this.name = props.name;
          this.extends = props.extends;
          this.properties = props.properties;
          this.variables = props.variables;
          this.uses_with = props.uses_with;
          this.uses_eval = props.uses_eval;
          this.parent_scope = props.parent_scope;
          this.enclosed = props.enclosed;
          this.cname = props.cname;
          this.body = props.body;
          this.block_scope = props.block_scope;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A class expression."
  }, AST_Class);

  var AST_Symbol = DEFNODE("Symbol", "scope name thedef", function AST_Symbol(props) {
      if (props) {
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $propdoc: {
          name: "[string] name of this symbol",
          scope: "[AST_Scope/S] the current scope (not necessarily the definition scope)",
          thedef: "[SymbolDef/S] the definition of this symbol"
      },
      $documentation: "Base class for all symbols"
  });

  var AST_NewTarget = DEFNODE("NewTarget", null, function AST_NewTarget(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A reference to new.target"
  });

  var AST_SymbolDeclaration = DEFNODE("SymbolDeclaration", "init", function AST_SymbolDeclaration(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A declaration symbol (symbol in var/const, function name or argument, symbol in catch)",
  }, AST_Symbol);

  var AST_SymbolVar = DEFNODE("SymbolVar", null, function AST_SymbolVar(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol defining a variable",
  }, AST_SymbolDeclaration);

  var AST_SymbolBlockDeclaration = DEFNODE(
      "SymbolBlockDeclaration",
      null,
      function AST_SymbolBlockDeclaration(props) {
          if (props) {
              this.init = props.init;
              this.scope = props.scope;
              this.name = props.name;
              this.thedef = props.thedef;
              this.start = props.start;
              this.end = props.end;
          }

          this.flags = 0;
      },
      {
          $documentation: "Base class for block-scoped declaration symbols"
      },
      AST_SymbolDeclaration
  );

  var AST_SymbolConst = DEFNODE("SymbolConst", null, function AST_SymbolConst(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A constant declaration"
  }, AST_SymbolBlockDeclaration);

  var AST_SymbolLet = DEFNODE("SymbolLet", null, function AST_SymbolLet(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A block-scoped `let` declaration"
  }, AST_SymbolBlockDeclaration);

  var AST_SymbolFunarg = DEFNODE("SymbolFunarg", null, function AST_SymbolFunarg(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol naming a function argument",
  }, AST_SymbolVar);

  var AST_SymbolDefun = DEFNODE("SymbolDefun", null, function AST_SymbolDefun(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol defining a function",
  }, AST_SymbolDeclaration);

  var AST_SymbolMethod = DEFNODE("SymbolMethod", null, function AST_SymbolMethod(props) {
      if (props) {
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol in an object defining a method",
  }, AST_Symbol);

  var AST_SymbolClassProperty = DEFNODE("SymbolClassProperty", null, function AST_SymbolClassProperty(props) {
      if (props) {
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol for a class property",
  }, AST_Symbol);

  var AST_SymbolLambda = DEFNODE("SymbolLambda", null, function AST_SymbolLambda(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol naming a function expression",
  }, AST_SymbolDeclaration);

  var AST_SymbolDefClass = DEFNODE("SymbolDefClass", null, function AST_SymbolDefClass(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol naming a class's name in a class declaration. Lexically scoped to its containing scope, and accessible within the class."
  }, AST_SymbolBlockDeclaration);

  var AST_SymbolClass = DEFNODE("SymbolClass", null, function AST_SymbolClass(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol naming a class's name. Lexically scoped to the class."
  }, AST_SymbolDeclaration);

  var AST_SymbolCatch = DEFNODE("SymbolCatch", null, function AST_SymbolCatch(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol naming the exception in catch",
  }, AST_SymbolBlockDeclaration);

  var AST_SymbolImport = DEFNODE("SymbolImport", null, function AST_SymbolImport(props) {
      if (props) {
          this.init = props.init;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol referring to an imported name",
  }, AST_SymbolBlockDeclaration);

  var AST_SymbolImportForeign = DEFNODE("SymbolImportForeign", null, function AST_SymbolImportForeign(props) {
      if (props) {
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A symbol imported from a module, but it is defined in the other module, and its real name is irrelevant for this module's purposes",
  }, AST_Symbol);

  var AST_Label = DEFNODE("Label", "references", function AST_Label(props) {
      if (props) {
          this.references = props.references;
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
          this.initialize();
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol naming a label (declaration)",
      $propdoc: {
          references: "[AST_LoopControl*] a list of nodes referring to this label"
      },
      initialize: function() {
          this.references = [];
          this.thedef = this;
      }
  }, AST_Symbol);

  var AST_SymbolRef = DEFNODE("SymbolRef", null, function AST_SymbolRef(props) {
      if (props) {
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Reference to some symbol (not definition/declaration)",
  }, AST_Symbol);

  var AST_SymbolExport = DEFNODE("SymbolExport", null, function AST_SymbolExport(props) {
      if (props) {
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Symbol referring to a name to export",
  }, AST_SymbolRef);

  var AST_SymbolExportForeign = DEFNODE("SymbolExportForeign", null, function AST_SymbolExportForeign(props) {
      if (props) {
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A symbol exported from this module, but it is used in the other module, and its real name is irrelevant for this module's purposes",
  }, AST_Symbol);

  var AST_LabelRef = DEFNODE("LabelRef", null, function AST_LabelRef(props) {
      if (props) {
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Reference to a label symbol",
  }, AST_Symbol);

  var AST_This = DEFNODE("This", null, function AST_This(props) {
      if (props) {
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The `this` symbol",
  }, AST_Symbol);

  var AST_Super = DEFNODE("Super", null, function AST_Super(props) {
      if (props) {
          this.scope = props.scope;
          this.name = props.name;
          this.thedef = props.thedef;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The `super` symbol",
  }, AST_This);

  var AST_Constant = DEFNODE("Constant", null, function AST_Constant(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for all constants",
      getValue: function() {
          return this.value;
      }
  });

  var AST_String = DEFNODE("String", "value quote", function AST_String(props) {
      if (props) {
          this.value = props.value;
          this.quote = props.quote;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A string literal",
      $propdoc: {
          value: "[string] the contents of this string",
          quote: "[string] the original quote character"
      }
  }, AST_Constant);

  var AST_Number = DEFNODE("Number", "value raw", function AST_Number(props) {
      if (props) {
          this.value = props.value;
          this.raw = props.raw;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A number literal",
      $propdoc: {
          value: "[number] the numeric value",
          raw: "[string] numeric value as string"
      }
  }, AST_Constant);

  var AST_BigInt = DEFNODE("BigInt", "value", function AST_BigInt(props) {
      if (props) {
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A big int literal",
      $propdoc: {
          value: "[string] big int value"
      }
  }, AST_Constant);

  var AST_RegExp = DEFNODE("RegExp", "value", function AST_RegExp(props) {
      if (props) {
          this.value = props.value;
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A regexp literal",
      $propdoc: {
          value: "[RegExp] the actual regexp",
      }
  }, AST_Constant);

  var AST_Atom = DEFNODE("Atom", null, function AST_Atom(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for atoms",
  }, AST_Constant);

  var AST_Null = DEFNODE("Null", null, function AST_Null(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The `null` atom",
      value: null
  }, AST_Atom);

  var AST_NaN = DEFNODE("NaN", null, function AST_NaN(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The impossible value",
      value: 0/0
  }, AST_Atom);

  var AST_Undefined = DEFNODE("Undefined", null, function AST_Undefined(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The `undefined` value",
      value: (function() {}())
  }, AST_Atom);

  var AST_Hole = DEFNODE("Hole", null, function AST_Hole(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "A hole in an array",
      value: (function() {}())
  }, AST_Atom);

  var AST_Infinity = DEFNODE("Infinity", null, function AST_Infinity(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The `Infinity` value",
      value: 1/0
  }, AST_Atom);

  var AST_Boolean = DEFNODE("Boolean", null, function AST_Boolean(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "Base class for booleans",
  }, AST_Atom);

  var AST_False = DEFNODE("False", null, function AST_False(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The `false` atom",
      value: false
  }, AST_Boolean);

  var AST_True = DEFNODE("True", null, function AST_True(props) {
      if (props) {
          this.start = props.start;
          this.end = props.end;
      }

      this.flags = 0;
  }, {
      $documentation: "The `true` atom",
      value: true
  }, AST_Boolean);

  /* -----[ Walk function ]---- */

  /**
   * Walk nodes in depth-first search fashion.
   * Callback can return `walk_abort` symbol to stop iteration.
   * It can also return `true` to stop iteration just for child nodes.
   * Iteration can be stopped and continued by passing the `to_visit` argument,
   * which is given to the callback in the second argument.
   **/
  function walk(node, cb, to_visit = [node]) {
      const push = to_visit.push.bind(to_visit);
      while (to_visit.length) {
          const node = to_visit.pop();
          const ret = cb(node, to_visit);

          if (ret) {
              if (ret === walk_abort) return true;
              continue;
          }

          node._children_backwards(push);
      }
      return false;
  }

  /**
   * Walks an AST node and its children.
   *
   * {cb} can return `walk_abort` to interrupt the walk.
   *
   * @param node
   * @param cb {(node, info: { parent: (nth) => any }) => (boolean | undefined)}
   *
   * @returns {boolean} whether the walk was aborted
   *
   * @example
   * const found_some_cond = walk_parent(my_ast_node, (node, { parent }) => {
   *   if (some_cond(node, parent())) return walk_abort
   * });
   */
  function walk_parent(node, cb, initial_stack) {
      const to_visit = [node];
      const push = to_visit.push.bind(to_visit);
      const stack = initial_stack ? initial_stack.slice() : [];
      const parent_pop_indices = [];

      let current;

      const info = {
          parent: (n = 0) => {
              if (n === -1) {
                  return current;
              }

              // [ p1 p0 ] [ 1 0 ]
              if (initial_stack && n >= stack.length) {
                  n -= stack.length;
                  return initial_stack[
                      initial_stack.length - (n + 1)
                  ];
              }

              return stack[stack.length - (1 + n)];
          },
      };

      while (to_visit.length) {
          current = to_visit.pop();

          while (
              parent_pop_indices.length &&
              to_visit.length == parent_pop_indices[parent_pop_indices.length - 1]
          ) {
              stack.pop();
              parent_pop_indices.pop();
          }

          const ret = cb(current, info);

          if (ret) {
              if (ret === walk_abort) return true;
              continue;
          }

          const visit_length = to_visit.length;

          current._children_backwards(push);

          // Push only if we're going to traverse the children
          if (to_visit.length > visit_length) {
              stack.push(current);
              parent_pop_indices.push(visit_length - 1);
          }
      }

      return false;
  }

  const walk_abort = Symbol("abort walk");

  /* -----[ TreeWalker ]----- */

  class TreeWalker {
      constructor(callback) {
          this.visit = callback;
          this.stack = [];
          this.directives = Object.create(null);
      }

      _visit(node, descend) {
          this.push(node);
          var ret = this.visit(node, descend ? function() {
              descend.call(node);
          } : noop);
          if (!ret && descend) {
              descend.call(node);
          }
          this.pop();
          return ret;
      }

      parent(n) {
          return this.stack[this.stack.length - 2 - (n || 0)];
      }

      push(node) {
          if (node instanceof AST_Lambda) {
              this.directives = Object.create(this.directives);
          } else if (node instanceof AST_Directive && !this.directives[node.value]) {
              this.directives[node.value] = node;
          } else if (node instanceof AST_Class) {
              this.directives = Object.create(this.directives);
              if (!this.directives["use strict"]) {
                  this.directives["use strict"] = node;
              }
          }
          this.stack.push(node);
      }

      pop() {
          var node = this.stack.pop();
          if (node instanceof AST_Lambda || node instanceof AST_Class) {
              this.directives = Object.getPrototypeOf(this.directives);
          }
      }

      self() {
          return this.stack[this.stack.length - 1];
      }

      find_parent(type) {
          var stack = this.stack;
          for (var i = stack.length; --i >= 0;) {
              var x = stack[i];
              if (x instanceof type) return x;
          }
      }

      find_scope() {
          for (let i = 0;;i++) {
              const p = this.parent(i);
              if (p instanceof AST_Toplevel) return p;
              if (p instanceof AST_Lambda) return p;
              if (p.block_scope) return p.block_scope;
          }
      }

      has_directive(type) {
          var dir = this.directives[type];
          if (dir) return dir;
          var node = this.stack[this.stack.length - 1];
          if (node instanceof AST_Scope && node.body) {
              for (var i = 0; i < node.body.length; ++i) {
                  var st = node.body[i];
                  if (!(st instanceof AST_Directive)) break;
                  if (st.value == type) return st;
              }
          }
      }

      loopcontrol_target(node) {
          var stack = this.stack;
          if (node.label) for (var i = stack.length; --i >= 0;) {
              var x = stack[i];
              if (x instanceof AST_LabeledStatement && x.label.name == node.label.name)
                  return x.body;
          } else for (var i = stack.length; --i >= 0;) {
              var x = stack[i];
              if (x instanceof AST_IterationStatement
                  || node instanceof AST_Break && x instanceof AST_Switch)
                  return x;
          }
      }
  }

  // Tree transformer helpers.
  class TreeTransformer extends TreeWalker {
      constructor(before, after) {
          super();
          this.before = before;
          this.after = after;
      }
  }

  const _PURE     = 0b00000001;
  const _INLINE   = 0b00000010;
  const _NOINLINE = 0b00000100;

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  function def_transform(node, descend) {
      node.DEFMETHOD("transform", function(tw, in_list) {
          let transformed = undefined;
          tw.push(this);
          if (tw.before) transformed = tw.before(this, descend, in_list);
          if (transformed === undefined) {
              transformed = this;
              descend(transformed, tw);
              if (tw.after) {
                  const after_ret = tw.after(transformed, in_list);
                  if (after_ret !== undefined) transformed = after_ret;
              }
          }
          tw.pop();
          return transformed;
      });
  }

  function do_list(list, tw) {
      return MAP(list, function(node) {
          return node.transform(tw, true);
      });
  }

  def_transform(AST_Node, noop);

  def_transform(AST_LabeledStatement, function(self, tw) {
      self.label = self.label.transform(tw);
      self.body = self.body.transform(tw);
  });

  def_transform(AST_SimpleStatement, function(self, tw) {
      self.body = self.body.transform(tw);
  });

  def_transform(AST_Block, function(self, tw) {
      self.body = do_list(self.body, tw);
  });

  def_transform(AST_Do, function(self, tw) {
      self.body = self.body.transform(tw);
      self.condition = self.condition.transform(tw);
  });

  def_transform(AST_While, function(self, tw) {
      self.condition = self.condition.transform(tw);
      self.body = self.body.transform(tw);
  });

  def_transform(AST_For, function(self, tw) {
      if (self.init) self.init = self.init.transform(tw);
      if (self.condition) self.condition = self.condition.transform(tw);
      if (self.step) self.step = self.step.transform(tw);
      self.body = self.body.transform(tw);
  });

  def_transform(AST_ForIn, function(self, tw) {
      self.init = self.init.transform(tw);
      self.object = self.object.transform(tw);
      self.body = self.body.transform(tw);
  });

  def_transform(AST_With, function(self, tw) {
      self.expression = self.expression.transform(tw);
      self.body = self.body.transform(tw);
  });

  def_transform(AST_Exit, function(self, tw) {
      if (self.value) self.value = self.value.transform(tw);
  });

  def_transform(AST_LoopControl, function(self, tw) {
      if (self.label) self.label = self.label.transform(tw);
  });

  def_transform(AST_If, function(self, tw) {
      self.condition = self.condition.transform(tw);
      self.body = self.body.transform(tw);
      if (self.alternative) self.alternative = self.alternative.transform(tw);
  });

  def_transform(AST_Switch, function(self, tw) {
      self.expression = self.expression.transform(tw);
      self.body = do_list(self.body, tw);
  });

  def_transform(AST_Case, function(self, tw) {
      self.expression = self.expression.transform(tw);
      self.body = do_list(self.body, tw);
  });

  def_transform(AST_Try, function(self, tw) {
      self.body = do_list(self.body, tw);
      if (self.bcatch) self.bcatch = self.bcatch.transform(tw);
      if (self.bfinally) self.bfinally = self.bfinally.transform(tw);
  });

  def_transform(AST_Catch, function(self, tw) {
      if (self.argname) self.argname = self.argname.transform(tw);
      self.body = do_list(self.body, tw);
  });

  def_transform(AST_Definitions, function(self, tw) {
      self.definitions = do_list(self.definitions, tw);
  });

  def_transform(AST_VarDef, function(self, tw) {
      self.name = self.name.transform(tw);
      if (self.value) self.value = self.value.transform(tw);
  });

  def_transform(AST_Destructuring, function(self, tw) {
      self.names = do_list(self.names, tw);
  });

  def_transform(AST_Lambda, function(self, tw) {
      if (self.name) self.name = self.name.transform(tw);
      self.argnames = do_list(self.argnames, tw);
      if (self.body instanceof AST_Node) {
          self.body = self.body.transform(tw);
      } else {
          self.body = do_list(self.body, tw);
      }
  });

  def_transform(AST_Call, function(self, tw) {
      self.expression = self.expression.transform(tw);
      self.args = do_list(self.args, tw);
  });

  def_transform(AST_Sequence, function(self, tw) {
      const result = do_list(self.expressions, tw);
      self.expressions = result.length
          ? result
          : [new AST_Number({ value: 0 })];
  });

  def_transform(AST_PropAccess, function(self, tw) {
      self.expression = self.expression.transform(tw);
  });

  def_transform(AST_Sub, function(self, tw) {
      self.expression = self.expression.transform(tw);
      self.property = self.property.transform(tw);
  });

  def_transform(AST_Chain, function(self, tw) {
      self.expression = self.expression.transform(tw);
  });

  def_transform(AST_Yield, function(self, tw) {
      if (self.expression) self.expression = self.expression.transform(tw);
  });

  def_transform(AST_Await, function(self, tw) {
      self.expression = self.expression.transform(tw);
  });

  def_transform(AST_Unary, function(self, tw) {
      self.expression = self.expression.transform(tw);
  });

  def_transform(AST_Binary, function(self, tw) {
      self.left = self.left.transform(tw);
      self.right = self.right.transform(tw);
  });

  def_transform(AST_Conditional, function(self, tw) {
      self.condition = self.condition.transform(tw);
      self.consequent = self.consequent.transform(tw);
      self.alternative = self.alternative.transform(tw);
  });

  def_transform(AST_Array, function(self, tw) {
      self.elements = do_list(self.elements, tw);
  });

  def_transform(AST_Object, function(self, tw) {
      self.properties = do_list(self.properties, tw);
  });

  def_transform(AST_ObjectProperty, function(self, tw) {
      if (self.key instanceof AST_Node) {
          self.key = self.key.transform(tw);
      }
      if (self.value) self.value = self.value.transform(tw);
  });

  def_transform(AST_Class, function(self, tw) {
      if (self.name) self.name = self.name.transform(tw);
      if (self.extends) self.extends = self.extends.transform(tw);
      self.properties = do_list(self.properties, tw);
  });

  def_transform(AST_Expansion, function(self, tw) {
      self.expression = self.expression.transform(tw);
  });

  def_transform(AST_NameMapping, function(self, tw) {
      self.foreign_name = self.foreign_name.transform(tw);
      self.name = self.name.transform(tw);
  });

  def_transform(AST_Import, function(self, tw) {
      if (self.imported_name) self.imported_name = self.imported_name.transform(tw);
      if (self.imported_names) do_list(self.imported_names, tw);
      self.module_name = self.module_name.transform(tw);
  });

  def_transform(AST_Export, function(self, tw) {
      if (self.exported_definition) self.exported_definition = self.exported_definition.transform(tw);
      if (self.exported_value) self.exported_value = self.exported_value.transform(tw);
      if (self.exported_names) do_list(self.exported_names, tw);
      if (self.module_name) self.module_name = self.module_name.transform(tw);
  });

  def_transform(AST_TemplateString, function(self, tw) {
      self.segments = do_list(self.segments, tw);
  });

  def_transform(AST_PrefixedTemplateString, function(self, tw) {
      self.prefix = self.prefix.transform(tw);
      self.template_string = self.template_string.transform(tw);
  });

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  (function() {

      var normalize_directives = function(body) {
          var in_directive = true;

          for (var i = 0; i < body.length; i++) {
              if (in_directive && body[i] instanceof AST_Statement && body[i].body instanceof AST_String) {
                  body[i] = new AST_Directive({
                      start: body[i].start,
                      end: body[i].end,
                      value: body[i].body.value
                  });
              } else if (in_directive && !(body[i] instanceof AST_Statement && body[i].body instanceof AST_String)) {
                  in_directive = false;
              }
          }

          return body;
      };

      const assert_clause_from_moz = (assertions) => {
          if (assertions && assertions.length > 0) {
              return new AST_Object({
                  start: my_start_token(assertions),
                  end: my_end_token(assertions),
                  properties: assertions.map((assertion_kv) =>
                      new AST_ObjectKeyVal({
                          start: my_start_token(assertion_kv),
                          end: my_end_token(assertion_kv),
                          key: assertion_kv.key.name || assertion_kv.key.value,
                          value: from_moz(assertion_kv.value)
                      })
                  )
              });
          }
          return null;
      };

      var MOZ_TO_ME = {
          Program: function(M) {
              return new AST_Toplevel({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  body: normalize_directives(M.body.map(from_moz))
              });
          },

          ArrayPattern: function(M) {
              return new AST_Destructuring({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  names: M.elements.map(function(elm) {
                      if (elm === null) {
                          return new AST_Hole();
                      }
                      return from_moz(elm);
                  }),
                  is_array: true
              });
          },

          ObjectPattern: function(M) {
              return new AST_Destructuring({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  names: M.properties.map(from_moz),
                  is_array: false
              });
          },

          AssignmentPattern: function(M) {
              return new AST_DefaultAssign({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  left: from_moz(M.left),
                  operator: "=",
                  right: from_moz(M.right)
              });
          },

          SpreadElement: function(M) {
              return new AST_Expansion({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  expression: from_moz(M.argument)
              });
          },

          RestElement: function(M) {
              return new AST_Expansion({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  expression: from_moz(M.argument)
              });
          },

          TemplateElement: function(M) {
              return new AST_TemplateSegment({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  value: M.value.cooked,
                  raw: M.value.raw
              });
          },

          TemplateLiteral: function(M) {
              var segments = [];
              for (var i = 0; i < M.quasis.length; i++) {
                  segments.push(from_moz(M.quasis[i]));
                  if (M.expressions[i]) {
                      segments.push(from_moz(M.expressions[i]));
                  }
              }
              return new AST_TemplateString({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  segments: segments
              });
          },

          TaggedTemplateExpression: function(M) {
              return new AST_PrefixedTemplateString({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  template_string: from_moz(M.quasi),
                  prefix: from_moz(M.tag)
              });
          },

          FunctionDeclaration: function(M) {
              return new AST_Defun({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  name: from_moz(M.id),
                  argnames: M.params.map(from_moz),
                  is_generator: M.generator,
                  async: M.async,
                  body: normalize_directives(from_moz(M.body).body)
              });
          },

          FunctionExpression: function(M) {
              return new AST_Function({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  name: from_moz(M.id),
                  argnames: M.params.map(from_moz),
                  is_generator: M.generator,
                  async: M.async,
                  body: normalize_directives(from_moz(M.body).body)
              });
          },

          ArrowFunctionExpression: function(M) {
              const body = M.body.type === "BlockStatement"
                  ? from_moz(M.body).body
                  : [make_node(AST_Return, {}, { value: from_moz(M.body) })];
              return new AST_Arrow({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  argnames: M.params.map(from_moz),
                  body,
                  async: M.async,
              });
          },

          ExpressionStatement: function(M) {
              return new AST_SimpleStatement({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  body: from_moz(M.expression)
              });
          },

          TryStatement: function(M) {
              var handlers = M.handlers || [M.handler];
              if (handlers.length > 1 || M.guardedHandlers && M.guardedHandlers.length) {
                  throw new Error("Multiple catch clauses are not supported.");
              }
              return new AST_Try({
                  start    : my_start_token(M),
                  end      : my_end_token(M),
                  body     : from_moz(M.block).body,
                  bcatch   : from_moz(handlers[0]),
                  bfinally : M.finalizer ? new AST_Finally(from_moz(M.finalizer)) : null
              });
          },

          Property: function(M) {
              var key = M.key;
              var args = {
                  start    : my_start_token(key || M.value),
                  end      : my_end_token(M.value),
                  key      : key.type == "Identifier" ? key.name : key.value,
                  value    : from_moz(M.value)
              };
              if (M.computed) {
                  args.key = from_moz(M.key);
              }
              if (M.method) {
                  args.is_generator = M.value.generator;
                  args.async = M.value.async;
                  if (!M.computed) {
                      args.key = new AST_SymbolMethod({ name: args.key });
                  } else {
                      args.key = from_moz(M.key);
                  }
                  return new AST_ConciseMethod(args);
              }
              if (M.kind == "init") {
                  if (key.type != "Identifier" && key.type != "Literal") {
                      args.key = from_moz(key);
                  }
                  return new AST_ObjectKeyVal(args);
              }
              if (typeof args.key === "string" || typeof args.key === "number") {
                  args.key = new AST_SymbolMethod({
                      name: args.key
                  });
              }
              args.value = new AST_Accessor(args.value);
              if (M.kind == "get") return new AST_ObjectGetter(args);
              if (M.kind == "set") return new AST_ObjectSetter(args);
              if (M.kind == "method") {
                  args.async = M.value.async;
                  args.is_generator = M.value.generator;
                  args.quote = M.computed ? "\"" : null;
                  return new AST_ConciseMethod(args);
              }
          },

          MethodDefinition: function(M) {
              var args = {
                  start    : my_start_token(M),
                  end      : my_end_token(M),
                  key      : M.computed ? from_moz(M.key) : new AST_SymbolMethod({ name: M.key.name || M.key.value }),
                  value    : from_moz(M.value),
                  static   : M.static,
              };
              if (M.kind == "get") {
                  return new AST_ObjectGetter(args);
              }
              if (M.kind == "set") {
                  return new AST_ObjectSetter(args);
              }
              args.is_generator = M.value.generator;
              args.async = M.value.async;
              return new AST_ConciseMethod(args);
          },

          FieldDefinition: function(M) {
              let key;
              if (M.computed) {
                  key = from_moz(M.key);
              } else {
                  if (M.key.type !== "Identifier") throw new Error("Non-Identifier key in FieldDefinition");
                  key = from_moz(M.key);
              }
              return new AST_ClassProperty({
                  start    : my_start_token(M),
                  end      : my_end_token(M),
                  key,
                  value    : from_moz(M.value),
                  static   : M.static,
              });
          },

          PropertyDefinition: function(M) {
              let key;
              if (M.computed) {
                  key = from_moz(M.key);
              } else {
                  if (M.key.type !== "Identifier") throw new Error("Non-Identifier key in PropertyDefinition");
                  key = from_moz(M.key);
              }

              return new AST_ClassProperty({
                  start    : my_start_token(M),
                  end      : my_end_token(M),
                  key,
                  value    : from_moz(M.value),
                  static   : M.static,
              });
          },

          ArrayExpression: function(M) {
              return new AST_Array({
                  start    : my_start_token(M),
                  end      : my_end_token(M),
                  elements : M.elements.map(function(elem) {
                      return elem === null ? new AST_Hole() : from_moz(elem);
                  })
              });
          },

          ObjectExpression: function(M) {
              return new AST_Object({
                  start      : my_start_token(M),
                  end        : my_end_token(M),
                  properties : M.properties.map(function(prop) {
                      if (prop.type === "SpreadElement") {
                          return from_moz(prop);
                      }
                      prop.type = "Property";
                      return from_moz(prop);
                  })
              });
          },

          SequenceExpression: function(M) {
              return new AST_Sequence({
                  start      : my_start_token(M),
                  end        : my_end_token(M),
                  expressions: M.expressions.map(from_moz)
              });
          },

          MemberExpression: function(M) {
              return new (M.computed ? AST_Sub : AST_Dot)({
                  start      : my_start_token(M),
                  end        : my_end_token(M),
                  property   : M.computed ? from_moz(M.property) : M.property.name,
                  expression : from_moz(M.object),
                  optional   : M.optional || false
              });
          },

          ChainExpression: function(M) {
              return new AST_Chain({
                  start      : my_start_token(M),
                  end        : my_end_token(M),
                  expression : from_moz(M.expression)
              });
          },

          SwitchCase: function(M) {
              return new (M.test ? AST_Case : AST_Default)({
                  start      : my_start_token(M),
                  end        : my_end_token(M),
                  expression : from_moz(M.test),
                  body       : M.consequent.map(from_moz)
              });
          },

          VariableDeclaration: function(M) {
              return new (M.kind === "const" ? AST_Const :
                          M.kind === "let" ? AST_Let : AST_Var)({
                  start       : my_start_token(M),
                  end         : my_end_token(M),
                  definitions : M.declarations.map(from_moz)
              });
          },

          ImportDeclaration: function(M) {
              var imported_name = null;
              var imported_names = null;
              M.specifiers.forEach(function (specifier) {
                  if (specifier.type === "ImportSpecifier") {
                      if (!imported_names) { imported_names = []; }
                      imported_names.push(new AST_NameMapping({
                          start: my_start_token(specifier),
                          end: my_end_token(specifier),
                          foreign_name: from_moz(specifier.imported),
                          name: from_moz(specifier.local)
                      }));
                  } else if (specifier.type === "ImportDefaultSpecifier") {
                      imported_name = from_moz(specifier.local);
                  } else if (specifier.type === "ImportNamespaceSpecifier") {
                      if (!imported_names) { imported_names = []; }
                      imported_names.push(new AST_NameMapping({
                          start: my_start_token(specifier),
                          end: my_end_token(specifier),
                          foreign_name: new AST_SymbolImportForeign({ name: "*" }),
                          name: from_moz(specifier.local)
                      }));
                  }
              });
              return new AST_Import({
                  start       : my_start_token(M),
                  end         : my_end_token(M),
                  imported_name: imported_name,
                  imported_names : imported_names,
                  module_name : from_moz(M.source),
                  assert_clause: assert_clause_from_moz(M.assertions)
              });
          },

          ExportAllDeclaration: function(M) {
              return new AST_Export({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  exported_names: [
                      new AST_NameMapping({
                          name: new AST_SymbolExportForeign({ name: "*" }),
                          foreign_name: new AST_SymbolExportForeign({ name: "*" })
                      })
                  ],
                  module_name: from_moz(M.source),
                  assert_clause: assert_clause_from_moz(M.assertions)
              });
          },

          ExportNamedDeclaration: function(M) {
              return new AST_Export({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  exported_definition: from_moz(M.declaration),
                  exported_names: M.specifiers && M.specifiers.length ? M.specifiers.map(function (specifier) {
                      return new AST_NameMapping({
                          foreign_name: from_moz(specifier.exported),
                          name: from_moz(specifier.local)
                      });
                  }) : null,
                  module_name: from_moz(M.source),
                  assert_clause: assert_clause_from_moz(M.assertions)
              });
          },

          ExportDefaultDeclaration: function(M) {
              return new AST_Export({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  exported_value: from_moz(M.declaration),
                  is_default: true
              });
          },

          Literal: function(M) {
              var val = M.value, args = {
                  start  : my_start_token(M),
                  end    : my_end_token(M)
              };
              var rx = M.regex;
              if (rx && rx.pattern) {
                  // RegExpLiteral as per ESTree AST spec
                  args.value = {
                      source: rx.pattern,
                      flags: rx.flags
                  };
                  return new AST_RegExp(args);
              } else if (rx) {
                  // support legacy RegExp
                  const rx_source = M.raw || val;
                  const match = rx_source.match(/^\/(.*)\/(\w*)$/);
                  if (!match) throw new Error("Invalid regex source " + rx_source);
                  const [_, source, flags] = match;
                  args.value = { source, flags };
                  return new AST_RegExp(args);
              }
              if (val === null) return new AST_Null(args);
              switch (typeof val) {
                case "string":
                  args.value = val;
                  return new AST_String(args);
                case "number":
                  args.value = val;
                  args.raw = M.raw || val.toString();
                  return new AST_Number(args);
                case "boolean":
                  return new (val ? AST_True : AST_False)(args);
              }
          },

          MetaProperty: function(M) {
              if (M.meta.name === "new" && M.property.name === "target") {
                  return new AST_NewTarget({
                      start: my_start_token(M),
                      end: my_end_token(M)
                  });
              } else if (M.meta.name === "import" && M.property.name === "meta") {
                  return new AST_ImportMeta({
                      start: my_start_token(M),
                      end: my_end_token(M)
                  });
              }
          },

          Identifier: function(M) {
              var p = FROM_MOZ_STACK[FROM_MOZ_STACK.length - 2];
              return new (  p.type == "LabeledStatement" ? AST_Label
                          : p.type == "VariableDeclarator" && p.id === M ? (p.kind == "const" ? AST_SymbolConst : p.kind == "let" ? AST_SymbolLet : AST_SymbolVar)
                          : /Import.*Specifier/.test(p.type) ? (p.local === M ? AST_SymbolImport : AST_SymbolImportForeign)
                          : p.type == "ExportSpecifier" ? (p.local === M ? AST_SymbolExport : AST_SymbolExportForeign)
                          : p.type == "FunctionExpression" ? (p.id === M ? AST_SymbolLambda : AST_SymbolFunarg)
                          : p.type == "FunctionDeclaration" ? (p.id === M ? AST_SymbolDefun : AST_SymbolFunarg)
                          : p.type == "ArrowFunctionExpression" ? (p.params.includes(M)) ? AST_SymbolFunarg : AST_SymbolRef
                          : p.type == "ClassExpression" ? (p.id === M ? AST_SymbolClass : AST_SymbolRef)
                          : p.type == "Property" ? (p.key === M && p.computed || p.value === M ? AST_SymbolRef : AST_SymbolMethod)
                          : p.type == "PropertyDefinition" || p.type === "FieldDefinition" ? (p.key === M && p.computed || p.value === M ? AST_SymbolRef : AST_SymbolClassProperty)
                          : p.type == "ClassDeclaration" ? (p.id === M ? AST_SymbolDefClass : AST_SymbolRef)
                          : p.type == "MethodDefinition" ? (p.computed ? AST_SymbolRef : AST_SymbolMethod)
                          : p.type == "CatchClause" ? AST_SymbolCatch
                          : p.type == "BreakStatement" || p.type == "ContinueStatement" ? AST_LabelRef
                          : AST_SymbolRef)({
                              start : my_start_token(M),
                              end   : my_end_token(M),
                              name  : M.name
                          });
          },

          BigIntLiteral(M) {
              return new AST_BigInt({
                  start : my_start_token(M),
                  end   : my_end_token(M),
                  value : M.value
              });
          },

          EmptyStatement: function(M) {
              return new AST_EmptyStatement({
                  start: my_start_token(M),
                  end: my_end_token(M)
              });
          },

          BlockStatement: function(M) {
              return new AST_BlockStatement({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  body: M.body.map(from_moz)
              });
          },

          IfStatement: function(M) {
              return new AST_If({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  condition: from_moz(M.test),
                  body: from_moz(M.consequent),
                  alternative: from_moz(M.alternate)
              });
          },

          LabeledStatement: function(M) {
              return new AST_LabeledStatement({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  label: from_moz(M.label),
                  body: from_moz(M.body)
              });
          },

          BreakStatement: function(M) {
              return new AST_Break({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  label: from_moz(M.label)
              });
          },

          ContinueStatement: function(M) {
              return new AST_Continue({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  label: from_moz(M.label)
              });
          },

          WithStatement: function(M) {
              return new AST_With({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  expression: from_moz(M.object),
                  body: from_moz(M.body)
              });
          },

          SwitchStatement: function(M) {
              return new AST_Switch({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  expression: from_moz(M.discriminant),
                  body: M.cases.map(from_moz)
              });
          },

          ReturnStatement: function(M) {
              return new AST_Return({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  value: from_moz(M.argument)
              });
          },

          ThrowStatement: function(M) {
              return new AST_Throw({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  value: from_moz(M.argument)
              });
          },

          WhileStatement: function(M) {
              return new AST_While({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  condition: from_moz(M.test),
                  body: from_moz(M.body)
              });
          },

          DoWhileStatement: function(M) {
              return new AST_Do({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  condition: from_moz(M.test),
                  body: from_moz(M.body)
              });
          },

          ForStatement: function(M) {
              return new AST_For({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  init: from_moz(M.init),
                  condition: from_moz(M.test),
                  step: from_moz(M.update),
                  body: from_moz(M.body)
              });
          },

          ForInStatement: function(M) {
              return new AST_ForIn({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  init: from_moz(M.left),
                  object: from_moz(M.right),
                  body: from_moz(M.body)
              });
          },

          ForOfStatement: function(M) {
              return new AST_ForOf({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  init: from_moz(M.left),
                  object: from_moz(M.right),
                  body: from_moz(M.body),
                  await: M.await
              });
          },

          AwaitExpression: function(M) {
              return new AST_Await({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  expression: from_moz(M.argument)
              });
          },

          YieldExpression: function(M) {
              return new AST_Yield({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  expression: from_moz(M.argument),
                  is_star: M.delegate
              });
          },

          DebuggerStatement: function(M) {
              return new AST_Debugger({
                  start: my_start_token(M),
                  end: my_end_token(M)
              });
          },

          VariableDeclarator: function(M) {
              return new AST_VarDef({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  name: from_moz(M.id),
                  value: from_moz(M.init)
              });
          },

          CatchClause: function(M) {
              return new AST_Catch({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  argname: from_moz(M.param),
                  body: from_moz(M.body).body
              });
          },

          ThisExpression: function(M) {
              return new AST_This({
                  start: my_start_token(M),
                  end: my_end_token(M)
              });
          },

          Super: function(M) {
              return new AST_Super({
                  start: my_start_token(M),
                  end: my_end_token(M)
              });
          },

          BinaryExpression: function(M) {
              return new AST_Binary({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  operator: M.operator,
                  left: from_moz(M.left),
                  right: from_moz(M.right)
              });
          },

          LogicalExpression: function(M) {
              return new AST_Binary({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  operator: M.operator,
                  left: from_moz(M.left),
                  right: from_moz(M.right)
              });
          },

          AssignmentExpression: function(M) {
              return new AST_Assign({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  operator: M.operator,
                  left: from_moz(M.left),
                  right: from_moz(M.right)
              });
          },

          ConditionalExpression: function(M) {
              return new AST_Conditional({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  condition: from_moz(M.test),
                  consequent: from_moz(M.consequent),
                  alternative: from_moz(M.alternate)
              });
          },

          NewExpression: function(M) {
              return new AST_New({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  expression: from_moz(M.callee),
                  args: M.arguments.map(from_moz)
              });
          },

          CallExpression: function(M) {
              return new AST_Call({
                  start: my_start_token(M),
                  end: my_end_token(M),
                  expression: from_moz(M.callee),
                  optional: M.optional,
                  args: M.arguments.map(from_moz)
              });
          }
      };

      MOZ_TO_ME.UpdateExpression =
      MOZ_TO_ME.UnaryExpression = function To_Moz_Unary(M) {
          var prefix = "prefix" in M ? M.prefix
              : M.type == "UnaryExpression" ? true : false;
          return new (prefix ? AST_UnaryPrefix : AST_UnaryPostfix)({
              start      : my_start_token(M),
              end        : my_end_token(M),
              operator   : M.operator,
              expression : from_moz(M.argument)
          });
      };

      MOZ_TO_ME.ClassDeclaration =
      MOZ_TO_ME.ClassExpression = function From_Moz_Class(M) {
          return new (M.type === "ClassDeclaration" ? AST_DefClass : AST_ClassExpression)({
              start    : my_start_token(M),
              end      : my_end_token(M),
              name     : from_moz(M.id),
              extends  : from_moz(M.superClass),
              properties: M.body.body.map(from_moz)
          });
      };

      def_to_moz(AST_EmptyStatement, function To_Moz_EmptyStatement() {
          return {
              type: "EmptyStatement"
          };
      });
      def_to_moz(AST_BlockStatement, function To_Moz_BlockStatement(M) {
          return {
              type: "BlockStatement",
              body: M.body.map(to_moz)
          };
      });
      def_to_moz(AST_If, function To_Moz_IfStatement(M) {
          return {
              type: "IfStatement",
              test: to_moz(M.condition),
              consequent: to_moz(M.body),
              alternate: to_moz(M.alternative)
          };
      });
      def_to_moz(AST_LabeledStatement, function To_Moz_LabeledStatement(M) {
          return {
              type: "LabeledStatement",
              label: to_moz(M.label),
              body: to_moz(M.body)
          };
      });
      def_to_moz(AST_Break, function To_Moz_BreakStatement(M) {
          return {
              type: "BreakStatement",
              label: to_moz(M.label)
          };
      });
      def_to_moz(AST_Continue, function To_Moz_ContinueStatement(M) {
          return {
              type: "ContinueStatement",
              label: to_moz(M.label)
          };
      });
      def_to_moz(AST_With, function To_Moz_WithStatement(M) {
          return {
              type: "WithStatement",
              object: to_moz(M.expression),
              body: to_moz(M.body)
          };
      });
      def_to_moz(AST_Switch, function To_Moz_SwitchStatement(M) {
          return {
              type: "SwitchStatement",
              discriminant: to_moz(M.expression),
              cases: M.body.map(to_moz)
          };
      });
      def_to_moz(AST_Return, function To_Moz_ReturnStatement(M) {
          return {
              type: "ReturnStatement",
              argument: to_moz(M.value)
          };
      });
      def_to_moz(AST_Throw, function To_Moz_ThrowStatement(M) {
          return {
              type: "ThrowStatement",
              argument: to_moz(M.value)
          };
      });
      def_to_moz(AST_While, function To_Moz_WhileStatement(M) {
          return {
              type: "WhileStatement",
              test: to_moz(M.condition),
              body: to_moz(M.body)
          };
      });
      def_to_moz(AST_Do, function To_Moz_DoWhileStatement(M) {
          return {
              type: "DoWhileStatement",
              test: to_moz(M.condition),
              body: to_moz(M.body)
          };
      });
      def_to_moz(AST_For, function To_Moz_ForStatement(M) {
          return {
              type: "ForStatement",
              init: to_moz(M.init),
              test: to_moz(M.condition),
              update: to_moz(M.step),
              body: to_moz(M.body)
          };
      });
      def_to_moz(AST_ForIn, function To_Moz_ForInStatement(M) {
          return {
              type: "ForInStatement",
              left: to_moz(M.init),
              right: to_moz(M.object),
              body: to_moz(M.body)
          };
      });
      def_to_moz(AST_ForOf, function To_Moz_ForOfStatement(M) {
          return {
              type: "ForOfStatement",
              left: to_moz(M.init),
              right: to_moz(M.object),
              body: to_moz(M.body),
              await: M.await
          };
      });
      def_to_moz(AST_Await, function To_Moz_AwaitExpression(M) {
          return {
              type: "AwaitExpression",
              argument: to_moz(M.expression)
          };
      });
      def_to_moz(AST_Yield, function To_Moz_YieldExpression(M) {
          return {
              type: "YieldExpression",
              argument: to_moz(M.expression),
              delegate: M.is_star
          };
      });
      def_to_moz(AST_Debugger, function To_Moz_DebuggerStatement() {
          return {
              type: "DebuggerStatement"
          };
      });
      def_to_moz(AST_VarDef, function To_Moz_VariableDeclarator(M) {
          return {
              type: "VariableDeclarator",
              id: to_moz(M.name),
              init: to_moz(M.value)
          };
      });
      def_to_moz(AST_Catch, function To_Moz_CatchClause(M) {
          return {
              type: "CatchClause",
              param: to_moz(M.argname),
              body: to_moz_block(M)
          };
      });

      def_to_moz(AST_This, function To_Moz_ThisExpression() {
          return {
              type: "ThisExpression"
          };
      });
      def_to_moz(AST_Super, function To_Moz_Super() {
          return {
              type: "Super"
          };
      });
      def_to_moz(AST_Binary, function To_Moz_BinaryExpression(M) {
          return {
              type: "BinaryExpression",
              operator: M.operator,
              left: to_moz(M.left),
              right: to_moz(M.right)
          };
      });
      def_to_moz(AST_Binary, function To_Moz_LogicalExpression(M) {
          return {
              type: "LogicalExpression",
              operator: M.operator,
              left: to_moz(M.left),
              right: to_moz(M.right)
          };
      });
      def_to_moz(AST_Assign, function To_Moz_AssignmentExpression(M) {
          return {
              type: "AssignmentExpression",
              operator: M.operator,
              left: to_moz(M.left),
              right: to_moz(M.right)
          };
      });
      def_to_moz(AST_Conditional, function To_Moz_ConditionalExpression(M) {
          return {
              type: "ConditionalExpression",
              test: to_moz(M.condition),
              consequent: to_moz(M.consequent),
              alternate: to_moz(M.alternative)
          };
      });
      def_to_moz(AST_New, function To_Moz_NewExpression(M) {
          return {
              type: "NewExpression",
              callee: to_moz(M.expression),
              arguments: M.args.map(to_moz)
          };
      });
      def_to_moz(AST_Call, function To_Moz_CallExpression(M) {
          return {
              type: "CallExpression",
              callee: to_moz(M.expression),
              optional: M.optional,
              arguments: M.args.map(to_moz)
          };
      });

      def_to_moz(AST_Toplevel, function To_Moz_Program(M) {
          return to_moz_scope("Program", M);
      });

      def_to_moz(AST_Expansion, function To_Moz_Spread(M) {
          return {
              type: to_moz_in_destructuring() ? "RestElement" : "SpreadElement",
              argument: to_moz(M.expression)
          };
      });

      def_to_moz(AST_PrefixedTemplateString, function To_Moz_TaggedTemplateExpression(M) {
          return {
              type: "TaggedTemplateExpression",
              tag: to_moz(M.prefix),
              quasi: to_moz(M.template_string)
          };
      });

      def_to_moz(AST_TemplateString, function To_Moz_TemplateLiteral(M) {
          var quasis = [];
          var expressions = [];
          for (var i = 0; i < M.segments.length; i++) {
              if (i % 2 !== 0) {
                  expressions.push(to_moz(M.segments[i]));
              } else {
                  quasis.push({
                      type: "TemplateElement",
                      value: {
                          raw: M.segments[i].raw,
                          cooked: M.segments[i].value
                      },
                      tail: i === M.segments.length - 1
                  });
              }
          }
          return {
              type: "TemplateLiteral",
              quasis: quasis,
              expressions: expressions
          };
      });

      def_to_moz(AST_Defun, function To_Moz_FunctionDeclaration(M) {
          return {
              type: "FunctionDeclaration",
              id: to_moz(M.name),
              params: M.argnames.map(to_moz),
              generator: M.is_generator,
              async: M.async,
              body: to_moz_scope("BlockStatement", M)
          };
      });

      def_to_moz(AST_Function, function To_Moz_FunctionExpression(M, parent) {
          var is_generator = parent.is_generator !== undefined ?
              parent.is_generator : M.is_generator;
          return {
              type: "FunctionExpression",
              id: to_moz(M.name),
              params: M.argnames.map(to_moz),
              generator: is_generator,
              async: M.async,
              body: to_moz_scope("BlockStatement", M)
          };
      });

      def_to_moz(AST_Arrow, function To_Moz_ArrowFunctionExpression(M) {
          var body = {
              type: "BlockStatement",
              body: M.body.map(to_moz)
          };
          return {
              type: "ArrowFunctionExpression",
              params: M.argnames.map(to_moz),
              async: M.async,
              body: body
          };
      });

      def_to_moz(AST_Destructuring, function To_Moz_ObjectPattern(M) {
          if (M.is_array) {
              return {
                  type: "ArrayPattern",
                  elements: M.names.map(to_moz)
              };
          }
          return {
              type: "ObjectPattern",
              properties: M.names.map(to_moz)
          };
      });

      def_to_moz(AST_Directive, function To_Moz_Directive(M) {
          return {
              type: "ExpressionStatement",
              expression: {
                  type: "Literal",
                  value: M.value,
                  raw: M.print_to_string()
              },
              directive: M.value
          };
      });

      def_to_moz(AST_SimpleStatement, function To_Moz_ExpressionStatement(M) {
          return {
              type: "ExpressionStatement",
              expression: to_moz(M.body)
          };
      });

      def_to_moz(AST_SwitchBranch, function To_Moz_SwitchCase(M) {
          return {
              type: "SwitchCase",
              test: to_moz(M.expression),
              consequent: M.body.map(to_moz)
          };
      });

      def_to_moz(AST_Try, function To_Moz_TryStatement(M) {
          return {
              type: "TryStatement",
              block: to_moz_block(M),
              handler: to_moz(M.bcatch),
              guardedHandlers: [],
              finalizer: to_moz(M.bfinally)
          };
      });

      def_to_moz(AST_Catch, function To_Moz_CatchClause(M) {
          return {
              type: "CatchClause",
              param: to_moz(M.argname),
              guard: null,
              body: to_moz_block(M)
          };
      });

      def_to_moz(AST_Definitions, function To_Moz_VariableDeclaration(M) {
          return {
              type: "VariableDeclaration",
              kind:
                  M instanceof AST_Const ? "const" :
                  M instanceof AST_Let ? "let" : "var",
              declarations: M.definitions.map(to_moz)
          };
      });

      const assert_clause_to_moz = assert_clause => {
          const assertions = [];
          if (assert_clause) {
              for (const { key, value } of assert_clause.properties) {
                  const key_moz = is_basic_identifier_string(key)
                      ? { type: "Identifier", name: key }
                      : { type: "Literal", value: key, raw: JSON.stringify(key) };
                  assertions.push({
                      type: "ImportAttribute",
                      key: key_moz,
                      value: to_moz(value)
                  });
              }
          }
          return assertions;
      };

      def_to_moz(AST_Export, function To_Moz_ExportDeclaration(M) {
          if (M.exported_names) {
              if (M.exported_names[0].name.name === "*") {
                  return {
                      type: "ExportAllDeclaration",
                      source: to_moz(M.module_name),
                      assertions: assert_clause_to_moz(M.assert_clause)
                  };
              }
              return {
                  type: "ExportNamedDeclaration",
                  specifiers: M.exported_names.map(function (name_mapping) {
                      return {
                          type: "ExportSpecifier",
                          exported: to_moz(name_mapping.foreign_name),
                          local: to_moz(name_mapping.name)
                      };
                  }),
                  declaration: to_moz(M.exported_definition),
                  source: to_moz(M.module_name),
                  assertions: assert_clause_to_moz(M.assert_clause)
              };
          }
          return {
              type: M.is_default ? "ExportDefaultDeclaration" : "ExportNamedDeclaration",
              declaration: to_moz(M.exported_value || M.exported_definition)
          };
      });

      def_to_moz(AST_Import, function To_Moz_ImportDeclaration(M) {
          var specifiers = [];
          if (M.imported_name) {
              specifiers.push({
                  type: "ImportDefaultSpecifier",
                  local: to_moz(M.imported_name)
              });
          }
          if (M.imported_names && M.imported_names[0].foreign_name.name === "*") {
              specifiers.push({
                  type: "ImportNamespaceSpecifier",
                  local: to_moz(M.imported_names[0].name)
              });
          } else if (M.imported_names) {
              M.imported_names.forEach(function(name_mapping) {
                  specifiers.push({
                      type: "ImportSpecifier",
                      local: to_moz(name_mapping.name),
                      imported: to_moz(name_mapping.foreign_name)
                  });
              });
          }
          return {
              type: "ImportDeclaration",
              specifiers: specifiers,
              source: to_moz(M.module_name),
              assertions: assert_clause_to_moz(M.assert_clause)
          };
      });

      def_to_moz(AST_ImportMeta, function To_Moz_MetaProperty() {
          return {
              type: "MetaProperty",
              meta: {
                  type: "Identifier",
                  name: "import"
              },
              property: {
                  type: "Identifier",
                  name: "meta"
              }
          };
      });

      def_to_moz(AST_Sequence, function To_Moz_SequenceExpression(M) {
          return {
              type: "SequenceExpression",
              expressions: M.expressions.map(to_moz)
          };
      });

      def_to_moz(AST_DotHash, function To_Moz_PrivateMemberExpression(M) {
          return {
              type: "MemberExpression",
              object: to_moz(M.expression),
              computed: false,
              property: {
                  type: "PrivateIdentifier",
                  name: M.property
              },
              optional: M.optional
          };
      });

      def_to_moz(AST_PropAccess, function To_Moz_MemberExpression(M) {
          var isComputed = M instanceof AST_Sub;
          return {
              type: "MemberExpression",
              object: to_moz(M.expression),
              computed: isComputed,
              property: isComputed ? to_moz(M.property) : {type: "Identifier", name: M.property},
              optional: M.optional
          };
      });

      def_to_moz(AST_Chain, function To_Moz_ChainExpression(M) {
          return {
              type: "ChainExpression",
              expression: to_moz(M.expression)
          };
      });

      def_to_moz(AST_Unary, function To_Moz_Unary(M) {
          return {
              type: M.operator == "++" || M.operator == "--" ? "UpdateExpression" : "UnaryExpression",
              operator: M.operator,
              prefix: M instanceof AST_UnaryPrefix,
              argument: to_moz(M.expression)
          };
      });

      def_to_moz(AST_Binary, function To_Moz_BinaryExpression(M) {
          if (M.operator == "=" && to_moz_in_destructuring()) {
              return {
                  type: "AssignmentPattern",
                  left: to_moz(M.left),
                  right: to_moz(M.right)
              };
          }

          const type = M.operator == "&&" || M.operator == "||" || M.operator === "??"
              ? "LogicalExpression"
              : "BinaryExpression";

          return {
              type,
              left: to_moz(M.left),
              operator: M.operator,
              right: to_moz(M.right)
          };
      });

      def_to_moz(AST_Array, function To_Moz_ArrayExpression(M) {
          return {
              type: "ArrayExpression",
              elements: M.elements.map(to_moz)
          };
      });

      def_to_moz(AST_Object, function To_Moz_ObjectExpression(M) {
          return {
              type: "ObjectExpression",
              properties: M.properties.map(to_moz)
          };
      });

      def_to_moz(AST_ObjectProperty, function To_Moz_Property(M, parent) {
          var key = M.key instanceof AST_Node ? to_moz(M.key) : {
              type: "Identifier",
              value: M.key
          };
          if (typeof M.key === "number") {
              key = {
                  type: "Literal",
                  value: Number(M.key)
              };
          }
          if (typeof M.key === "string") {
              key = {
                  type: "Identifier",
                  name: M.key
              };
          }
          var kind;
          var string_or_num = typeof M.key === "string" || typeof M.key === "number";
          var computed = string_or_num ? false : !(M.key instanceof AST_Symbol) || M.key instanceof AST_SymbolRef;
          if (M instanceof AST_ObjectKeyVal) {
              kind = "init";
              computed = !string_or_num;
          } else
          if (M instanceof AST_ObjectGetter) {
              kind = "get";
          } else
          if (M instanceof AST_ObjectSetter) {
              kind = "set";
          }
          if (M instanceof AST_PrivateGetter || M instanceof AST_PrivateSetter) {
              const kind = M instanceof AST_PrivateGetter ? "get" : "set";
              return {
                  type: "MethodDefinition",
                  computed: false,
                  kind: kind,
                  static: M.static,
                  key: {
                      type: "PrivateIdentifier",
                      name: M.key.name
                  },
                  value: to_moz(M.value)
              };
          }
          if (M instanceof AST_ClassPrivateProperty) {
              return {
                  type: "PropertyDefinition",
                  key: {
                      type: "PrivateIdentifier",
                      name: M.key.name
                  },
                  value: to_moz(M.value),
                  computed: false,
                  static: M.static
              };
          }
          if (M instanceof AST_ClassProperty) {
              return {
                  type: "PropertyDefinition",
                  key,
                  value: to_moz(M.value),
                  computed,
                  static: M.static
              };
          }
          if (parent instanceof AST_Class) {
              return {
                  type: "MethodDefinition",
                  computed: computed,
                  kind: kind,
                  static: M.static,
                  key: to_moz(M.key),
                  value: to_moz(M.value)
              };
          }
          return {
              type: "Property",
              computed: computed,
              kind: kind,
              key: key,
              value: to_moz(M.value)
          };
      });

      def_to_moz(AST_ConciseMethod, function To_Moz_MethodDefinition(M, parent) {
          if (parent instanceof AST_Object) {
              return {
                  type: "Property",
                  computed: !(M.key instanceof AST_Symbol) || M.key instanceof AST_SymbolRef,
                  kind: "init",
                  method: true,
                  shorthand: false,
                  key: to_moz(M.key),
                  value: to_moz(M.value)
              };
          }

          const key = M instanceof AST_PrivateMethod
              ? {
                  type: "PrivateIdentifier",
                  name: M.key.name
              }
              : to_moz(M.key);

          return {
              type: "MethodDefinition",
              kind: M.key === "constructor" ? "constructor" : "method",
              key,
              value: to_moz(M.value),
              computed: !(M.key instanceof AST_Symbol) || M.key instanceof AST_SymbolRef,
              static: M.static,
          };
      });

      def_to_moz(AST_Class, function To_Moz_Class(M) {
          var type = M instanceof AST_ClassExpression ? "ClassExpression" : "ClassDeclaration";
          return {
              type: type,
              superClass: to_moz(M.extends),
              id: M.name ? to_moz(M.name) : null,
              body: {
                  type: "ClassBody",
                  body: M.properties.map(to_moz)
              }
          };
      });

      def_to_moz(AST_NewTarget, function To_Moz_MetaProperty() {
          return {
              type: "MetaProperty",
              meta: {
                  type: "Identifier",
                  name: "new"
              },
              property: {
                  type: "Identifier",
                  name: "target"
              }
          };
      });

      def_to_moz(AST_Symbol, function To_Moz_Identifier(M, parent) {
          if (M instanceof AST_SymbolMethod && parent.quote) {
              return {
                  type: "Literal",
                  value: M.name
              };
          }
          var def = M.definition();
          return {
              type: "Identifier",
              name: def ? def.mangled_name || def.name : M.name
          };
      });

      def_to_moz(AST_RegExp, function To_Moz_RegExpLiteral(M) {
          const pattern = M.value.source;
          const flags = M.value.flags;
          return {
              type: "Literal",
              value: null,
              raw: M.print_to_string(),
              regex: { pattern, flags }
          };
      });

      def_to_moz(AST_Constant, function To_Moz_Literal(M) {
          var value = M.value;
          return {
              type: "Literal",
              value: value,
              raw: M.raw || M.print_to_string()
          };
      });

      def_to_moz(AST_Atom, function To_Moz_Atom(M) {
          return {
              type: "Identifier",
              name: String(M.value)
          };
      });

      def_to_moz(AST_BigInt, M => ({
          type: "BigIntLiteral",
          value: M.value
      }));

      AST_Boolean.DEFMETHOD("to_mozilla_ast", AST_Constant.prototype.to_mozilla_ast);
      AST_Null.DEFMETHOD("to_mozilla_ast", AST_Constant.prototype.to_mozilla_ast);
      AST_Hole.DEFMETHOD("to_mozilla_ast", function To_Moz_ArrayHole() { return null; });

      AST_Block.DEFMETHOD("to_mozilla_ast", AST_BlockStatement.prototype.to_mozilla_ast);
      AST_Lambda.DEFMETHOD("to_mozilla_ast", AST_Function.prototype.to_mozilla_ast);

      /* -----[ tools ]----- */

      function my_start_token(moznode) {
          var loc = moznode.loc, start = loc && loc.start;
          var range = moznode.range;
          return new AST_Token(
              "",
              "",
              start && start.line || 0,
              start && start.column || 0,
              range ? range [0] : moznode.start,
              false,
              [],
              [],
              loc && loc.source,
          );
      }

      function my_end_token(moznode) {
          var loc = moznode.loc, end = loc && loc.end;
          var range = moznode.range;
          return new AST_Token(
              "",
              "",
              end && end.line || 0,
              end && end.column || 0,
              range ? range [0] : moznode.end,
              false,
              [],
              [],
              loc && loc.source,
          );
      }

      var FROM_MOZ_STACK = null;

      function from_moz(node) {
          FROM_MOZ_STACK.push(node);
          var ret = node != null ? MOZ_TO_ME[node.type](node) : null;
          FROM_MOZ_STACK.pop();
          return ret;
      }

      AST_Node.from_mozilla_ast = function(node) {
          var save_stack = FROM_MOZ_STACK;
          FROM_MOZ_STACK = [];
          var ast = from_moz(node);
          FROM_MOZ_STACK = save_stack;
          return ast;
      };

      function set_moz_loc(mynode, moznode) {
          var start = mynode.start;
          var end = mynode.end;
          if (!(start && end)) {
              return moznode;
          }
          if (start.pos != null && end.endpos != null) {
              moznode.range = [start.pos, end.endpos];
          }
          if (start.line) {
              moznode.loc = {
                  start: {line: start.line, column: start.col},
                  end: end.endline ? {line: end.endline, column: end.endcol} : null
              };
              if (start.file) {
                  moznode.loc.source = start.file;
              }
          }
          return moznode;
      }

      function def_to_moz(mytype, handler) {
          mytype.DEFMETHOD("to_mozilla_ast", function(parent) {
              return set_moz_loc(this, handler(this, parent));
          });
      }

      var TO_MOZ_STACK = null;

      function to_moz(node) {
          if (TO_MOZ_STACK === null) { TO_MOZ_STACK = []; }
          TO_MOZ_STACK.push(node);
          var ast = node != null ? node.to_mozilla_ast(TO_MOZ_STACK[TO_MOZ_STACK.length - 2]) : null;
          TO_MOZ_STACK.pop();
          if (TO_MOZ_STACK.length === 0) { TO_MOZ_STACK = null; }
          return ast;
      }

      function to_moz_in_destructuring() {
          var i = TO_MOZ_STACK.length;
          while (i--) {
              if (TO_MOZ_STACK[i] instanceof AST_Destructuring) {
                  return true;
              }
          }
          return false;
      }

      function to_moz_block(node) {
          return {
              type: "BlockStatement",
              body: node.body.map(to_moz)
          };
      }

      function to_moz_scope(type, node) {
          var body = node.body.map(to_moz);
          if (node.body[0] instanceof AST_SimpleStatement && node.body[0].body instanceof AST_String) {
              body.unshift(to_moz(new AST_EmptyStatement(node.body[0])));
          }
          return {
              type: type,
              body: body
          };
      }
  })();

  // return true if the node at the top of the stack (that means the
  // innermost node in the current output) is lexically the first in
  // a statement.
  function first_in_statement(stack) {
      let node = stack.parent(-1);
      for (let i = 0, p; p = stack.parent(i); i++) {
          if (p instanceof AST_Statement && p.body === node)
              return true;
          if ((p instanceof AST_Sequence && p.expressions[0] === node) ||
              (p.TYPE === "Call" && p.expression === node) ||
              (p instanceof AST_PrefixedTemplateString && p.prefix === node) ||
              (p instanceof AST_Dot && p.expression === node) ||
              (p instanceof AST_Sub && p.expression === node) ||
              (p instanceof AST_Conditional && p.condition === node) ||
              (p instanceof AST_Binary && p.left === node) ||
              (p instanceof AST_UnaryPostfix && p.expression === node)
          ) {
              node = p;
          } else {
              return false;
          }
      }
  }

  // Returns whether the leftmost item in the expression is an object
  function left_is_object(node) {
      if (node instanceof AST_Object) return true;
      if (node instanceof AST_Sequence) return left_is_object(node.expressions[0]);
      if (node.TYPE === "Call") return left_is_object(node.expression);
      if (node instanceof AST_PrefixedTemplateString) return left_is_object(node.prefix);
      if (node instanceof AST_Dot || node instanceof AST_Sub) return left_is_object(node.expression);
      if (node instanceof AST_Conditional) return left_is_object(node.condition);
      if (node instanceof AST_Binary) return left_is_object(node.left);
      if (node instanceof AST_UnaryPostfix) return left_is_object(node.expression);
      return false;
  }

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  const EXPECT_DIRECTIVE = /^$|[;{][\s\n]*$/;
  const CODE_LINE_BREAK = 10;
  const CODE_SPACE = 32;

  const r_annotation = /[@#]__(PURE|INLINE|NOINLINE)__/g;

  function is_some_comments(comment) {
      // multiline comment
      return (
          (comment.type === "comment2" || comment.type === "comment1")
          && /@preserve|@copyright|@lic|@cc_on|^\**!/i.test(comment.value)
      );
  }

  class Rope {
      constructor() {
          this.committed = "";
          this.current = "";
      }

      append(str) {
          this.current += str;
      }

      insertAt(char, index) {
          const { committed, current } = this;
          if (index < committed.length) {
              this.committed = committed.slice(0, index) + char + committed.slice(index);
          } else if (index === committed.length) {
              this.committed += char;
          } else {
              index -= committed.length;
              this.committed += current.slice(0, index) + char;
              this.current = current.slice(index);
          }
      }

      charAt(index) {
          const { committed } = this;
          if (index < committed.length) return committed[index];
          return this.current[index - committed.length];
      }

      curLength() {
          return this.current.length;
      }

      length() {
          return this.committed.length + this.current.length;
      }

      toString() {
          return this.committed + this.current;
      }
  }

  function OutputStream(options) {

      var readonly = !options;
      options = defaults(options, {
          ascii_only           : false,
          beautify             : false,
          braces               : false,
          comments             : "some",
          ecma                 : 5,
          ie8                  : false,
          indent_level         : 4,
          indent_start         : 0,
          inline_script        : true,
          keep_numbers         : false,
          keep_quoted_props    : false,
          max_line_len         : false,
          preamble             : null,
          preserve_annotations : false,
          quote_keys           : false,
          quote_style          : 0,
          safari10             : false,
          semicolons           : true,
          shebang              : true,
          shorthand            : undefined,
          source_map           : null,
          webkit               : false,
          width                : 80,
          wrap_iife            : false,
          wrap_func_args       : true,

          _destroy_ast         : false
      }, true);

      if (options.shorthand === undefined)
          options.shorthand = options.ecma > 5;

      // Convert comment option to RegExp if neccessary and set up comments filter
      var comment_filter = return_false; // Default case, throw all comments away
      if (options.comments) {
          let comments = options.comments;
          if (typeof options.comments === "string" && /^\/.*\/[a-zA-Z]*$/.test(options.comments)) {
              var regex_pos = options.comments.lastIndexOf("/");
              comments = new RegExp(
                  options.comments.substr(1, regex_pos - 1),
                  options.comments.substr(regex_pos + 1)
              );
          }
          if (comments instanceof RegExp) {
              comment_filter = function(comment) {
                  return comment.type != "comment5" && comments.test(comment.value);
              };
          } else if (typeof comments === "function") {
              comment_filter = function(comment) {
                  return comment.type != "comment5" && comments(this, comment);
              };
          } else if (comments === "some") {
              comment_filter = is_some_comments;
          } else { // NOTE includes "all" option
              comment_filter = return_true;
          }
      }

      var indentation = 0;
      var current_col = 0;
      var current_line = 1;
      var current_pos = 0;
      var OUTPUT = new Rope();
      let printed_comments = new Set();

      var to_utf8 = options.ascii_only ? function(str, identifier = false, regexp = false) {
          if (options.ecma >= 2015 && !options.safari10 && !regexp) {
              str = str.replace(/[\ud800-\udbff][\udc00-\udfff]/g, function(ch) {
                  var code = get_full_char_code(ch, 0).toString(16);
                  return "\\u{" + code + "}";
              });
          }
          return str.replace(/[\u0000-\u001f\u007f-\uffff]/g, function(ch) {
              var code = ch.charCodeAt(0).toString(16);
              if (code.length <= 2 && !identifier) {
                  while (code.length < 2) code = "0" + code;
                  return "\\x" + code;
              } else {
                  while (code.length < 4) code = "0" + code;
                  return "\\u" + code;
              }
          });
      } : function(str) {
          return str.replace(/[\ud800-\udbff][\udc00-\udfff]|([\ud800-\udbff]|[\udc00-\udfff])/g, function(match, lone) {
              if (lone) {
                  return "\\u" + lone.charCodeAt(0).toString(16);
              }
              return match;
          });
      };

      function make_string(str, quote) {
          var dq = 0, sq = 0;
          str = str.replace(/[\\\b\f\n\r\v\t\x22\x27\u2028\u2029\0\ufeff]/g,
            function(s, i) {
              switch (s) {
                case '"': ++dq; return '"';
                case "'": ++sq; return "'";
                case "\\": return "\\\\";
                case "\n": return "\\n";
                case "\r": return "\\r";
                case "\t": return "\\t";
                case "\b": return "\\b";
                case "\f": return "\\f";
                case "\x0B": return options.ie8 ? "\\x0B" : "\\v";
                case "\u2028": return "\\u2028";
                case "\u2029": return "\\u2029";
                case "\ufeff": return "\\ufeff";
                case "\0":
                    return /[0-9]/.test(get_full_char(str, i+1)) ? "\\x00" : "\\0";
              }
              return s;
          });
          function quote_single() {
              return "'" + str.replace(/\x27/g, "\\'") + "'";
          }
          function quote_double() {
              return '"' + str.replace(/\x22/g, '\\"') + '"';
          }
          function quote_template() {
              return "`" + str.replace(/`/g, "\\`") + "`";
          }
          str = to_utf8(str);
          if (quote === "`") return quote_template();
          switch (options.quote_style) {
            case 1:
              return quote_single();
            case 2:
              return quote_double();
            case 3:
              return quote == "'" ? quote_single() : quote_double();
            default:
              return dq > sq ? quote_single() : quote_double();
          }
      }

      function encode_string(str, quote) {
          var ret = make_string(str, quote);
          if (options.inline_script) {
              ret = ret.replace(/<\x2f(script)([>\/\t\n\f\r ])/gi, "<\\/$1$2");
              ret = ret.replace(/\x3c!--/g, "\\x3c!--");
              ret = ret.replace(/--\x3e/g, "--\\x3e");
          }
          return ret;
      }

      function make_name(name) {
          name = name.toString();
          name = to_utf8(name, true);
          return name;
      }

      function make_indent(back) {
          return " ".repeat(options.indent_start + indentation - back * options.indent_level);
      }

      /* -----[ beautification/minification ]----- */

      var has_parens = false;
      var might_need_space = false;
      var might_need_semicolon = false;
      var might_add_newline = 0;
      var need_newline_indented = false;
      var need_space = false;
      var newline_insert = -1;
      var last = "";
      var mapping_token, mapping_name, mappings = options.source_map && [];

      var do_add_mapping = mappings ? function() {
          mappings.forEach(function(mapping) {
              try {
                  let { name, token } = mapping;
                  if (token.type == "name" || token.type === "privatename") {
                      name = token.value;
                  } else if (name instanceof AST_Symbol) {
                      name = token.type === "string" ? token.value : name.name;
                  }
                  options.source_map.add(
                      mapping.token.file,
                      mapping.line, mapping.col,
                      mapping.token.line, mapping.token.col,
                      is_basic_identifier_string(name) ? name : undefined
                  );
              } catch(ex) {
                  // Ignore bad mapping
              }
          });
          mappings = [];
      } : noop;

      var ensure_line_len = options.max_line_len ? function() {
          if (current_col > options.max_line_len) {
              if (might_add_newline) {
                  OUTPUT.insertAt("\n", might_add_newline);
                  const curLength = OUTPUT.curLength();
                  if (mappings) {
                      var delta = curLength - current_col;
                      mappings.forEach(function(mapping) {
                          mapping.line++;
                          mapping.col += delta;
                      });
                  }
                  current_line++;
                  current_pos++;
                  current_col = curLength;
              }
          }
          if (might_add_newline) {
              might_add_newline = 0;
              do_add_mapping();
          }
      } : noop;

      var requireSemicolonChars = makePredicate("( [ + * / - , . `");

      function print(str) {
          str = String(str);
          var ch = get_full_char(str, 0);
          if (need_newline_indented && ch) {
              need_newline_indented = false;
              if (ch !== "\n") {
                  print("\n");
                  indent();
              }
          }
          if (need_space && ch) {
              need_space = false;
              if (!/[\s;})]/.test(ch)) {
                  space();
              }
          }
          newline_insert = -1;
          var prev = last.charAt(last.length - 1);
          if (might_need_semicolon) {
              might_need_semicolon = false;

              if (prev === ":" && ch === "}" || (!ch || !";}".includes(ch)) && prev !== ";") {
                  if (options.semicolons || requireSemicolonChars.has(ch)) {
                      OUTPUT.append(";");
                      current_col++;
                      current_pos++;
                  } else {
                      ensure_line_len();
                      if (current_col > 0) {
                          OUTPUT.append("\n");
                          current_pos++;
                          current_line++;
                          current_col = 0;
                      }

                      if (/^\s+$/.test(str)) {
                          // reset the semicolon flag, since we didn't print one
                          // now and might still have to later
                          might_need_semicolon = true;
                      }
                  }

                  if (!options.beautify)
                      might_need_space = false;
              }
          }

          if (might_need_space) {
              if ((is_identifier_char(prev)
                      && (is_identifier_char(ch) || ch == "\\"))
                  || (ch == "/" && ch == prev)
                  || ((ch == "+" || ch == "-") && ch == last)
              ) {
                  OUTPUT.append(" ");
                  current_col++;
                  current_pos++;
              }
              might_need_space = false;
          }

          if (mapping_token) {
              mappings.push({
                  token: mapping_token,
                  name: mapping_name,
                  line: current_line,
                  col: current_col
              });
              mapping_token = false;
              if (!might_add_newline) do_add_mapping();
          }

          OUTPUT.append(str);
          has_parens = str[str.length - 1] == "(";
          current_pos += str.length;
          var a = str.split(/\r?\n/), n = a.length - 1;
          current_line += n;
          current_col += a[0].length;
          if (n > 0) {
              ensure_line_len();
              current_col = a[n].length;
          }
          last = str;
      }

      var star = function() {
          print("*");
      };

      var space = options.beautify ? function() {
          print(" ");
      } : function() {
          might_need_space = true;
      };

      var indent = options.beautify ? function(half) {
          if (options.beautify) {
              print(make_indent(half ? 0.5 : 0));
          }
      } : noop;

      var with_indent = options.beautify ? function(col, cont) {
          if (col === true) col = next_indent();
          var save_indentation = indentation;
          indentation = col;
          var ret = cont();
          indentation = save_indentation;
          return ret;
      } : function(col, cont) { return cont(); };

      var newline = options.beautify ? function() {
          if (newline_insert < 0) return print("\n");
          if (OUTPUT.charAt(newline_insert) != "\n") {
              OUTPUT.insertAt("\n", newline_insert);
              current_pos++;
              current_line++;
          }
          newline_insert++;
      } : options.max_line_len ? function() {
          ensure_line_len();
          might_add_newline = OUTPUT.length();
      } : noop;

      var semicolon = options.beautify ? function() {
          print(";");
      } : function() {
          might_need_semicolon = true;
      };

      function force_semicolon() {
          might_need_semicolon = false;
          print(";");
      }

      function next_indent() {
          return indentation + options.indent_level;
      }

      function with_block(cont) {
          var ret;
          print("{");
          newline();
          with_indent(next_indent(), function() {
              ret = cont();
          });
          indent();
          print("}");
          return ret;
      }

      function with_parens(cont) {
          print("(");
          //XXX: still nice to have that for argument lists
          //var ret = with_indent(current_col, cont);
          var ret = cont();
          print(")");
          return ret;
      }

      function with_square(cont) {
          print("[");
          //var ret = with_indent(current_col, cont);
          var ret = cont();
          print("]");
          return ret;
      }

      function comma() {
          print(",");
          space();
      }

      function colon() {
          print(":");
          space();
      }

      var add_mapping = mappings ? function(token, name) {
          mapping_token = token;
          mapping_name = name;
      } : noop;

      function get() {
          if (might_add_newline) {
              ensure_line_len();
          }
          return OUTPUT.toString();
      }

      function has_nlb() {
          const output = OUTPUT.toString();
          let n = output.length - 1;
          while (n >= 0) {
              const code = output.charCodeAt(n);
              if (code === CODE_LINE_BREAK) {
                  return true;
              }

              if (code !== CODE_SPACE) {
                  return false;
              }
              n--;
          }
          return true;
      }

      function filter_comment(comment) {
          if (!options.preserve_annotations) {
              comment = comment.replace(r_annotation, " ");
          }
          if (/^\s*$/.test(comment)) {
              return "";
          }
          return comment.replace(/(<\s*\/\s*)(script)/i, "<\\/$2");
      }

      function prepend_comments(node) {
          var self = this;
          var start = node.start;
          if (!start) return;
          var printed_comments = self.printed_comments;

          // There cannot be a newline between return and its value.
          const return_with_value = node instanceof AST_Exit && node.value;

          if (
              start.comments_before
              && printed_comments.has(start.comments_before)
          ) {
              if (return_with_value) {
                  start.comments_before = [];
              } else {
                  return;
              }
          }

          var comments = start.comments_before;
          if (!comments) {
              comments = start.comments_before = [];
          }
          printed_comments.add(comments);

          if (return_with_value) {
              var tw = new TreeWalker(function(node) {
                  var parent = tw.parent();
                  if (parent instanceof AST_Exit
                      || parent instanceof AST_Binary && parent.left === node
                      || parent.TYPE == "Call" && parent.expression === node
                      || parent instanceof AST_Conditional && parent.condition === node
                      || parent instanceof AST_Dot && parent.expression === node
                      || parent instanceof AST_Sequence && parent.expressions[0] === node
                      || parent instanceof AST_Sub && parent.expression === node
                      || parent instanceof AST_UnaryPostfix) {
                      if (!node.start) return;
                      var text = node.start.comments_before;
                      if (text && !printed_comments.has(text)) {
                          printed_comments.add(text);
                          comments = comments.concat(text);
                      }
                  } else {
                      return true;
                  }
              });
              tw.push(node);
              node.value.walk(tw);
          }

          if (current_pos == 0) {
              if (comments.length > 0 && options.shebang && comments[0].type === "comment5"
                  && !printed_comments.has(comments[0])) {
                  print("#!" + comments.shift().value + "\n");
                  indent();
              }
              var preamble = options.preamble;
              if (preamble) {
                  print(preamble.replace(/\r\n?|[\n\u2028\u2029]|\s*$/g, "\n"));
              }
          }

          comments = comments.filter(comment_filter, node).filter(c => !printed_comments.has(c));
          if (comments.length == 0) return;
          var last_nlb = has_nlb();
          comments.forEach(function(c, i) {
              printed_comments.add(c);
              if (!last_nlb) {
                  if (c.nlb) {
                      print("\n");
                      indent();
                      last_nlb = true;
                  } else if (i > 0) {
                      space();
                  }
              }

              if (/comment[134]/.test(c.type)) {
                  var value = filter_comment(c.value);
                  if (value) {
                      print("//" + value + "\n");
                      indent();
                  }
                  last_nlb = true;
              } else if (c.type == "comment2") {
                  var value = filter_comment(c.value);
                  if (value) {
                      print("/*" + value + "*/");
                  }
                  last_nlb = false;
              }
          });
          if (!last_nlb) {
              if (start.nlb) {
                  print("\n");
                  indent();
              } else {
                  space();
              }
          }
      }

      function append_comments(node, tail) {
          var self = this;
          var token = node.end;
          if (!token) return;
          var printed_comments = self.printed_comments;
          var comments = token[tail ? "comments_before" : "comments_after"];
          if (!comments || printed_comments.has(comments)) return;
          if (!(node instanceof AST_Statement || comments.every((c) =>
              !/comment[134]/.test(c.type)
          ))) return;
          printed_comments.add(comments);
          var insert = OUTPUT.length();
          comments.filter(comment_filter, node).forEach(function(c, i) {
              if (printed_comments.has(c)) return;
              printed_comments.add(c);
              need_space = false;
              if (need_newline_indented) {
                  print("\n");
                  indent();
                  need_newline_indented = false;
              } else if (c.nlb && (i > 0 || !has_nlb())) {
                  print("\n");
                  indent();
              } else if (i > 0 || !tail) {
                  space();
              }
              if (/comment[134]/.test(c.type)) {
                  const value = filter_comment(c.value);
                  if (value) {
                      print("//" + value);
                  }
                  need_newline_indented = true;
              } else if (c.type == "comment2") {
                  const value = filter_comment(c.value);
                  if (value) {
                      print("/*" + value + "*/");
                  }
                  need_space = true;
              }
          });
          if (OUTPUT.length() > insert) newline_insert = insert;
      }

      /**
       * When output.option("_destroy_ast") is enabled, destroy the function.
       * Call this after printing it.
       */
      const gc_scope =
        options["_destroy_ast"]
          ? function gc_scope(scope) {
              scope.body.length = 0;
              scope.argnames.length = 0;
          }
          : noop;

      var stack = [];
      return {
          get             : get,
          toString        : get,
          indent          : indent,
          in_directive    : false,
          use_asm         : null,
          active_scope    : null,
          indentation     : function() { return indentation; },
          current_width   : function() { return current_col - indentation; },
          should_break    : function() { return options.width && this.current_width() >= options.width; },
          has_parens      : function() { return has_parens; },
          newline         : newline,
          print           : print,
          star            : star,
          space           : space,
          comma           : comma,
          colon           : colon,
          last            : function() { return last; },
          semicolon       : semicolon,
          force_semicolon : force_semicolon,
          to_utf8         : to_utf8,
          print_name      : function(name) { print(make_name(name)); },
          print_string    : function(str, quote, escape_directive) {
              var encoded = encode_string(str, quote);
              if (escape_directive === true && !encoded.includes("\\")) {
                  // Insert semicolons to break directive prologue
                  if (!EXPECT_DIRECTIVE.test(OUTPUT.toString())) {
                      force_semicolon();
                  }
                  force_semicolon();
              }
              print(encoded);
          },
          print_template_string_chars: function(str) {
              var encoded = encode_string(str, "`").replace(/\${/g, "\\${");
              return print(encoded.substr(1, encoded.length - 2));
          },
          encode_string   : encode_string,
          next_indent     : next_indent,
          with_indent     : with_indent,
          with_block      : with_block,
          with_parens     : with_parens,
          with_square     : with_square,
          add_mapping     : add_mapping,
          option          : function(opt) { return options[opt]; },
          gc_scope,
          printed_comments: printed_comments,
          prepend_comments: readonly ? noop : prepend_comments,
          append_comments : readonly || comment_filter === return_false ? noop : append_comments,
          line            : function() { return current_line; },
          col             : function() { return current_col; },
          pos             : function() { return current_pos; },
          push_node       : function(node) { stack.push(node); },
          pop_node        : function() { return stack.pop(); },
          parent          : function(n) {
              return stack[stack.length - 2 - (n || 0)];
          }
      };

  }

  /* -----[ code generators ]----- */

  (function() {

      /* -----[ utils ]----- */

      function DEFPRINT(nodetype, generator) {
          nodetype.DEFMETHOD("_codegen", generator);
      }

      AST_Node.DEFMETHOD("print", function(output, force_parens) {
          var self = this, generator = self._codegen;
          if (self instanceof AST_Scope) {
              output.active_scope = self;
          } else if (!output.use_asm && self instanceof AST_Directive && self.value == "use asm") {
              output.use_asm = output.active_scope;
          }
          function doit() {
              output.prepend_comments(self);
              self.add_source_map(output);
              generator(self, output);
              output.append_comments(self);
          }
          output.push_node(self);
          if (force_parens || self.needs_parens(output)) {
              output.with_parens(doit);
          } else {
              doit();
          }
          output.pop_node();
          if (self === output.use_asm) {
              output.use_asm = null;
          }
      });
      AST_Node.DEFMETHOD("_print", AST_Node.prototype.print);

      AST_Node.DEFMETHOD("print_to_string", function(options) {
          var output = OutputStream(options);
          this.print(output);
          return output.get();
      });

      /* -----[ PARENTHESES ]----- */

      function PARENS(nodetype, func) {
          if (Array.isArray(nodetype)) {
              nodetype.forEach(function(nodetype) {
                  PARENS(nodetype, func);
              });
          } else {
              nodetype.DEFMETHOD("needs_parens", func);
          }
      }

      PARENS(AST_Node, return_false);

      // a function expression needs parens around it when it's provably
      // the first token to appear in a statement.
      PARENS(AST_Function, function(output) {
          if (!output.has_parens() && first_in_statement(output)) {
              return true;
          }

          if (output.option("webkit")) {
              var p = output.parent();
              if (p instanceof AST_PropAccess && p.expression === this) {
                  return true;
              }
          }

          if (output.option("wrap_iife")) {
              var p = output.parent();
              if (p instanceof AST_Call && p.expression === this) {
                  return true;
              }
          }

          if (output.option("wrap_func_args")) {
              var p = output.parent();
              if (p instanceof AST_Call && p.args.includes(this)) {
                  return true;
              }
          }

          return false;
      });

      PARENS(AST_Arrow, function(output) {
          var p = output.parent();

          if (
              output.option("wrap_func_args")
              && p instanceof AST_Call
              && p.args.includes(this)
          ) {
              return true;
          }
          return p instanceof AST_PropAccess && p.expression === this;
      });

      // same goes for an object literal (as in AST_Function), because
      // otherwise {...} would be interpreted as a block of code.
      PARENS(AST_Object, function(output) {
          return !output.has_parens() && first_in_statement(output);
      });

      PARENS(AST_ClassExpression, first_in_statement);

      PARENS(AST_Unary, function(output) {
          var p = output.parent();
          return p instanceof AST_PropAccess && p.expression === this
              || p instanceof AST_Call && p.expression === this
              || p instanceof AST_Binary
                  && p.operator === "**"
                  && this instanceof AST_UnaryPrefix
                  && p.left === this
                  && this.operator !== "++"
                  && this.operator !== "--";
      });

      PARENS(AST_Await, function(output) {
          var p = output.parent();
          return p instanceof AST_PropAccess && p.expression === this
              || p instanceof AST_Call && p.expression === this
              || p instanceof AST_Binary && p.operator === "**" && p.left === this
              || output.option("safari10") && p instanceof AST_UnaryPrefix;
      });

      PARENS(AST_Sequence, function(output) {
          var p = output.parent();
          return p instanceof AST_Call                          // (foo, bar)() or foo(1, (2, 3), 4)
              || p instanceof AST_Unary                         // !(foo, bar, baz)
              || p instanceof AST_Binary                        // 1 + (2, 3) + 4 ==> 8
              || p instanceof AST_VarDef                        // var a = (1, 2), b = a + a; ==> b == 4
              || p instanceof AST_PropAccess                    // (1, {foo:2}).foo or (1, {foo:2})["foo"] ==> 2
              || p instanceof AST_Array                         // [ 1, (2, 3), 4 ] ==> [ 1, 3, 4 ]
              || p instanceof AST_ObjectProperty                // { foo: (1, 2) }.foo ==> 2
              || p instanceof AST_Conditional                   /* (false, true) ? (a = 10, b = 20) : (c = 30)
                                                                 * ==> 20 (side effect, set a := 10 and b := 20) */
              || p instanceof AST_Arrow                         // x => (x, x)
              || p instanceof AST_DefaultAssign                 // x => (x = (0, function(){}))
              || p instanceof AST_Expansion                     // [...(a, b)]
              || p instanceof AST_ForOf && this === p.object    // for (e of (foo, bar)) {}
              || p instanceof AST_Yield                         // yield (foo, bar)
              || p instanceof AST_Export                        // export default (foo, bar)
          ;
      });

      PARENS(AST_Binary, function(output) {
          var p = output.parent();
          // (foo && bar)()
          if (p instanceof AST_Call && p.expression === this)
              return true;
          // typeof (foo && bar)
          if (p instanceof AST_Unary)
              return true;
          // (foo && bar)["prop"], (foo && bar).prop
          if (p instanceof AST_PropAccess && p.expression === this)
              return true;
          // this deals with precedence: 3 * (2 + 1)
          if (p instanceof AST_Binary) {
              const po = p.operator;
              const so = this.operator;

              if (so === "??" && (po === "||" || po === "&&")) {
                  return true;
              }

              if (po === "??" && (so === "||" || so === "&&")) {
                  return true;
              }

              const pp = PRECEDENCE[po];
              const sp = PRECEDENCE[so];
              if (pp > sp
                  || (pp == sp
                      && (this === p.right || po == "**"))) {
                  return true;
              }
          }
      });

      PARENS(AST_Yield, function(output) {
          var p = output.parent();
          // (yield 1) + (yield 2)
          // a = yield 3
          if (p instanceof AST_Binary && p.operator !== "=")
              return true;
          // (yield 1)()
          // new (yield 1)()
          if (p instanceof AST_Call && p.expression === this)
              return true;
          // (yield 1) ? yield 2 : yield 3
          if (p instanceof AST_Conditional && p.condition === this)
              return true;
          // -(yield 4)
          if (p instanceof AST_Unary)
              return true;
          // (yield x).foo
          // (yield x)['foo']
          if (p instanceof AST_PropAccess && p.expression === this)
              return true;
      });

      PARENS(AST_PropAccess, function(output) {
          var p = output.parent();
          if (p instanceof AST_New && p.expression === this) {
              // i.e. new (foo.bar().baz)
              //
              // if there's one call into this subtree, then we need
              // parens around it too, otherwise the call will be
              // interpreted as passing the arguments to the upper New
              // expression.
              return walk(this, node => {
                  if (node instanceof AST_Scope) return true;
                  if (node instanceof AST_Call) {
                      return walk_abort;  // makes walk() return true.
                  }
              });
          }
      });

      PARENS(AST_Call, function(output) {
          var p = output.parent(), p1;
          if (p instanceof AST_New && p.expression === this
              || p instanceof AST_Export && p.is_default && this.expression instanceof AST_Function)
              return true;

          // workaround for Safari bug.
          // https://bugs.webkit.org/show_bug.cgi?id=123506
          return this.expression instanceof AST_Function
              && p instanceof AST_PropAccess
              && p.expression === this
              && (p1 = output.parent(1)) instanceof AST_Assign
              && p1.left === p;
      });

      PARENS(AST_New, function(output) {
          var p = output.parent();
          if (this.args.length === 0
              && (p instanceof AST_PropAccess // (new Date).getTime(), (new Date)["getTime"]()
                  || p instanceof AST_Call && p.expression === this
                  || p instanceof AST_PrefixedTemplateString && p.prefix === this)) // (new foo)(bar)
              return true;
      });

      PARENS(AST_Number, function(output) {
          var p = output.parent();
          if (p instanceof AST_PropAccess && p.expression === this) {
              var value = this.getValue();
              if (value < 0 || /^0/.test(make_num(value))) {
                  return true;
              }
          }
      });

      PARENS(AST_BigInt, function(output) {
          var p = output.parent();
          if (p instanceof AST_PropAccess && p.expression === this) {
              var value = this.getValue();
              if (value.startsWith("-")) {
                  return true;
              }
          }
      });

      PARENS([ AST_Assign, AST_Conditional ], function(output) {
          var p = output.parent();
          // !(a = false) → true
          if (p instanceof AST_Unary)
              return true;
          // 1 + (a = 2) + 3 → 6, side effect setting a = 2
          if (p instanceof AST_Binary && !(p instanceof AST_Assign))
              return true;
          // (a = func)() —or— new (a = Object)()
          if (p instanceof AST_Call && p.expression === this)
              return true;
          // (a = foo) ? bar : baz
          if (p instanceof AST_Conditional && p.condition === this)
              return true;
          // (a = foo)["prop"] —or— (a = foo).prop
          if (p instanceof AST_PropAccess && p.expression === this)
              return true;
          // ({a, b} = {a: 1, b: 2}), a destructuring assignment
          if (this instanceof AST_Assign && this.left instanceof AST_Destructuring && this.left.is_array === false)
              return true;
      });

      /* -----[ PRINTERS ]----- */

      DEFPRINT(AST_Directive, function(self, output) {
          output.print_string(self.value, self.quote);
          output.semicolon();
      });

      DEFPRINT(AST_Expansion, function (self, output) {
          output.print("...");
          self.expression.print(output);
      });

      DEFPRINT(AST_Destructuring, function (self, output) {
          output.print(self.is_array ? "[" : "{");
          var len = self.names.length;
          self.names.forEach(function (name, i) {
              if (i > 0) output.comma();
              name.print(output);
              // If the final element is a hole, we need to make sure it
              // doesn't look like a trailing comma, by inserting an actual
              // trailing comma.
              if (i == len - 1 && name instanceof AST_Hole) output.comma();
          });
          output.print(self.is_array ? "]" : "}");
      });

      DEFPRINT(AST_Debugger, function(self, output) {
          output.print("debugger");
          output.semicolon();
      });

      /* -----[ statements ]----- */

      function display_body(body, is_toplevel, output, allow_directives) {
          var last = body.length - 1;
          output.in_directive = allow_directives;
          body.forEach(function(stmt, i) {
              if (output.in_directive === true && !(stmt instanceof AST_Directive ||
                  stmt instanceof AST_EmptyStatement ||
                  (stmt instanceof AST_SimpleStatement && stmt.body instanceof AST_String)
              )) {
                  output.in_directive = false;
              }
              if (!(stmt instanceof AST_EmptyStatement)) {
                  output.indent();
                  stmt.print(output);
                  if (!(i == last && is_toplevel)) {
                      output.newline();
                      if (is_toplevel) output.newline();
                  }
              }
              if (output.in_directive === true &&
                  stmt instanceof AST_SimpleStatement &&
                  stmt.body instanceof AST_String
              ) {
                  output.in_directive = false;
              }
          });
          output.in_directive = false;
      }

      AST_StatementWithBody.DEFMETHOD("_do_print_body", function(output) {
          force_statement(this.body, output);
      });

      DEFPRINT(AST_Statement, function(self, output) {
          self.body.print(output);
          output.semicolon();
      });
      DEFPRINT(AST_Toplevel, function(self, output) {
          display_body(self.body, true, output, true);
          output.print("");
      });
      DEFPRINT(AST_LabeledStatement, function(self, output) {
          self.label.print(output);
          output.colon();
          self.body.print(output);
      });
      DEFPRINT(AST_SimpleStatement, function(self, output) {
          self.body.print(output);
          output.semicolon();
      });
      function print_braced_empty(self, output) {
          output.print("{");
          output.with_indent(output.next_indent(), function() {
              output.append_comments(self, true);
          });
          output.add_mapping(self.end);
          output.print("}");
      }
      function print_braced(self, output, allow_directives) {
          if (self.body.length > 0) {
              output.with_block(function() {
                  display_body(self.body, false, output, allow_directives);
                  output.add_mapping(self.end);
              });
          } else print_braced_empty(self, output);
      }
      DEFPRINT(AST_BlockStatement, function(self, output) {
          print_braced(self, output);
      });
      DEFPRINT(AST_EmptyStatement, function(self, output) {
          output.semicolon();
      });
      DEFPRINT(AST_Do, function(self, output) {
          output.print("do");
          output.space();
          make_block(self.body, output);
          output.space();
          output.print("while");
          output.space();
          output.with_parens(function() {
              self.condition.print(output);
          });
          output.semicolon();
      });
      DEFPRINT(AST_While, function(self, output) {
          output.print("while");
          output.space();
          output.with_parens(function() {
              self.condition.print(output);
          });
          output.space();
          self._do_print_body(output);
      });
      DEFPRINT(AST_For, function(self, output) {
          output.print("for");
          output.space();
          output.with_parens(function() {
              if (self.init) {
                  if (self.init instanceof AST_Definitions) {
                      self.init.print(output);
                  } else {
                      parenthesize_for_noin(self.init, output, true);
                  }
                  output.print(";");
                  output.space();
              } else {
                  output.print(";");
              }
              if (self.condition) {
                  self.condition.print(output);
                  output.print(";");
                  output.space();
              } else {
                  output.print(";");
              }
              if (self.step) {
                  self.step.print(output);
              }
          });
          output.space();
          self._do_print_body(output);
      });
      DEFPRINT(AST_ForIn, function(self, output) {
          output.print("for");
          if (self.await) {
              output.space();
              output.print("await");
          }
          output.space();
          output.with_parens(function() {
              self.init.print(output);
              output.space();
              output.print(self instanceof AST_ForOf ? "of" : "in");
              output.space();
              self.object.print(output);
          });
          output.space();
          self._do_print_body(output);
      });
      DEFPRINT(AST_With, function(self, output) {
          output.print("with");
          output.space();
          output.with_parens(function() {
              self.expression.print(output);
          });
          output.space();
          self._do_print_body(output);
      });

      /* -----[ functions ]----- */
      AST_Lambda.DEFMETHOD("_do_print", function(output, nokeyword) {
          var self = this;
          if (!nokeyword) {
              if (self.async) {
                  output.print("async");
                  output.space();
              }
              output.print("function");
              if (self.is_generator) {
                  output.star();
              }
              if (self.name) {
                  output.space();
              }
          }
          if (self.name instanceof AST_Symbol) {
              self.name.print(output);
          } else if (nokeyword && self.name instanceof AST_Node) {
              output.with_square(function() {
                  self.name.print(output); // Computed method name
              });
          }
          output.with_parens(function() {
              self.argnames.forEach(function(arg, i) {
                  if (i) output.comma();
                  arg.print(output);
              });
          });
          output.space();
          print_braced(self, output, true);
      });
      DEFPRINT(AST_Lambda, function(self, output) {
          self._do_print(output);
          output.gc_scope(self);
      });

      DEFPRINT(AST_PrefixedTemplateString, function(self, output) {
          var tag = self.prefix;
          var parenthesize_tag = tag instanceof AST_Lambda
              || tag instanceof AST_Binary
              || tag instanceof AST_Conditional
              || tag instanceof AST_Sequence
              || tag instanceof AST_Unary
              || tag instanceof AST_Dot && tag.expression instanceof AST_Object;
          if (parenthesize_tag) output.print("(");
          self.prefix.print(output);
          if (parenthesize_tag) output.print(")");
          self.template_string.print(output);
      });
      DEFPRINT(AST_TemplateString, function(self, output) {
          var is_tagged = output.parent() instanceof AST_PrefixedTemplateString;

          output.print("`");
          for (var i = 0; i < self.segments.length; i++) {
              if (!(self.segments[i] instanceof AST_TemplateSegment)) {
                  output.print("${");
                  self.segments[i].print(output);
                  output.print("}");
              } else if (is_tagged) {
                  output.print(self.segments[i].raw);
              } else {
                  output.print_template_string_chars(self.segments[i].value);
              }
          }
          output.print("`");
      });
      DEFPRINT(AST_TemplateSegment, function(self, output) {
          output.print_template_string_chars(self.value);
      });

      AST_Arrow.DEFMETHOD("_do_print", function(output) {
          var self = this;
          var parent = output.parent();
          var needs_parens = (parent instanceof AST_Binary && !(parent instanceof AST_Assign)) ||
              parent instanceof AST_Unary ||
              (parent instanceof AST_Call && self === parent.expression);
          if (needs_parens) { output.print("("); }
          if (self.async) {
              output.print("async");
              output.space();
          }
          if (self.argnames.length === 1 && self.argnames[0] instanceof AST_Symbol) {
              self.argnames[0].print(output);
          } else {
              output.with_parens(function() {
                  self.argnames.forEach(function(arg, i) {
                      if (i) output.comma();
                      arg.print(output);
                  });
              });
          }
          output.space();
          output.print("=>");
          output.space();
          const first_statement = self.body[0];
          if (
              self.body.length === 1
              && first_statement instanceof AST_Return
          ) {
              const returned = first_statement.value;
              if (!returned) {
                  output.print("{}");
              } else if (left_is_object(returned)) {
                  output.print("(");
                  returned.print(output);
                  output.print(")");
              } else {
                  returned.print(output);
              }
          } else {
              print_braced(self, output);
          }
          if (needs_parens) { output.print(")"); }
          output.gc_scope(self);
      });

      /* -----[ exits ]----- */
      AST_Exit.DEFMETHOD("_do_print", function(output, kind) {
          output.print(kind);
          if (this.value) {
              output.space();
              const comments = this.value.start.comments_before;
              if (comments && comments.length && !output.printed_comments.has(comments)) {
                  output.print("(");
                  this.value.print(output);
                  output.print(")");
              } else {
                  this.value.print(output);
              }
          }
          output.semicolon();
      });
      DEFPRINT(AST_Return, function(self, output) {
          self._do_print(output, "return");
      });
      DEFPRINT(AST_Throw, function(self, output) {
          self._do_print(output, "throw");
      });

      /* -----[ yield ]----- */

      DEFPRINT(AST_Yield, function(self, output) {
          var star = self.is_star ? "*" : "";
          output.print("yield" + star);
          if (self.expression) {
              output.space();
              self.expression.print(output);
          }
      });

      DEFPRINT(AST_Await, function(self, output) {
          output.print("await");
          output.space();
          var e = self.expression;
          var parens = !(
                 e instanceof AST_Call
              || e instanceof AST_SymbolRef
              || e instanceof AST_PropAccess
              || e instanceof AST_Unary
              || e instanceof AST_Constant
              || e instanceof AST_Await
              || e instanceof AST_Object
          );
          if (parens) output.print("(");
          self.expression.print(output);
          if (parens) output.print(")");
      });

      /* -----[ loop control ]----- */
      AST_LoopControl.DEFMETHOD("_do_print", function(output, kind) {
          output.print(kind);
          if (this.label) {
              output.space();
              this.label.print(output);
          }
          output.semicolon();
      });
      DEFPRINT(AST_Break, function(self, output) {
          self._do_print(output, "break");
      });
      DEFPRINT(AST_Continue, function(self, output) {
          self._do_print(output, "continue");
      });

      /* -----[ if ]----- */
      function make_then(self, output) {
          var b = self.body;
          if (output.option("braces")
              || output.option("ie8") && b instanceof AST_Do)
              return make_block(b, output);
          // The squeezer replaces "block"-s that contain only a single
          // statement with the statement itself; technically, the AST
          // is correct, but this can create problems when we output an
          // IF having an ELSE clause where the THEN clause ends in an
          // IF *without* an ELSE block (then the outer ELSE would refer
          // to the inner IF).  This function checks for this case and
          // adds the block braces if needed.
          if (!b) return output.force_semicolon();
          while (true) {
              if (b instanceof AST_If) {
                  if (!b.alternative) {
                      make_block(self.body, output);
                      return;
                  }
                  b = b.alternative;
              } else if (b instanceof AST_StatementWithBody) {
                  b = b.body;
              } else break;
          }
          force_statement(self.body, output);
      }
      DEFPRINT(AST_If, function(self, output) {
          output.print("if");
          output.space();
          output.with_parens(function() {
              self.condition.print(output);
          });
          output.space();
          if (self.alternative) {
              make_then(self, output);
              output.space();
              output.print("else");
              output.space();
              if (self.alternative instanceof AST_If)
                  self.alternative.print(output);
              else
                  force_statement(self.alternative, output);
          } else {
              self._do_print_body(output);
          }
      });

      /* -----[ switch ]----- */
      DEFPRINT(AST_Switch, function(self, output) {
          output.print("switch");
          output.space();
          output.with_parens(function() {
              self.expression.print(output);
          });
          output.space();
          var last = self.body.length - 1;
          if (last < 0) print_braced_empty(self, output);
          else output.with_block(function() {
              self.body.forEach(function(branch, i) {
                  output.indent(true);
                  branch.print(output);
                  if (i < last && branch.body.length > 0)
                      output.newline();
              });
          });
      });
      AST_SwitchBranch.DEFMETHOD("_do_print_body", function(output) {
          output.newline();
          this.body.forEach(function(stmt) {
              output.indent();
              stmt.print(output);
              output.newline();
          });
      });
      DEFPRINT(AST_Default, function(self, output) {
          output.print("default:");
          self._do_print_body(output);
      });
      DEFPRINT(AST_Case, function(self, output) {
          output.print("case");
          output.space();
          self.expression.print(output);
          output.print(":");
          self._do_print_body(output);
      });

      /* -----[ exceptions ]----- */
      DEFPRINT(AST_Try, function(self, output) {
          output.print("try");
          output.space();
          print_braced(self, output);
          if (self.bcatch) {
              output.space();
              self.bcatch.print(output);
          }
          if (self.bfinally) {
              output.space();
              self.bfinally.print(output);
          }
      });
      DEFPRINT(AST_Catch, function(self, output) {
          output.print("catch");
          if (self.argname) {
              output.space();
              output.with_parens(function() {
                  self.argname.print(output);
              });
          }
          output.space();
          print_braced(self, output);
      });
      DEFPRINT(AST_Finally, function(self, output) {
          output.print("finally");
          output.space();
          print_braced(self, output);
      });

      /* -----[ var/const ]----- */
      AST_Definitions.DEFMETHOD("_do_print", function(output, kind) {
          output.print(kind);
          output.space();
          this.definitions.forEach(function(def, i) {
              if (i) output.comma();
              def.print(output);
          });
          var p = output.parent();
          var in_for = p instanceof AST_For || p instanceof AST_ForIn;
          var output_semicolon = !in_for || p && p.init !== this;
          if (output_semicolon)
              output.semicolon();
      });
      DEFPRINT(AST_Let, function(self, output) {
          self._do_print(output, "let");
      });
      DEFPRINT(AST_Var, function(self, output) {
          self._do_print(output, "var");
      });
      DEFPRINT(AST_Const, function(self, output) {
          self._do_print(output, "const");
      });
      DEFPRINT(AST_Import, function(self, output) {
          output.print("import");
          output.space();
          if (self.imported_name) {
              self.imported_name.print(output);
          }
          if (self.imported_name && self.imported_names) {
              output.print(",");
              output.space();
          }
          if (self.imported_names) {
              if (self.imported_names.length === 1 && self.imported_names[0].foreign_name.name === "*") {
                  self.imported_names[0].print(output);
              } else {
                  output.print("{");
                  self.imported_names.forEach(function (name_import, i) {
                      output.space();
                      name_import.print(output);
                      if (i < self.imported_names.length - 1) {
                          output.print(",");
                      }
                  });
                  output.space();
                  output.print("}");
              }
          }
          if (self.imported_name || self.imported_names) {
              output.space();
              output.print("from");
              output.space();
          }
          self.module_name.print(output);
          if (self.assert_clause) {
              output.print("assert");
              self.assert_clause.print(output);
          }
          output.semicolon();
      });
      DEFPRINT(AST_ImportMeta, function(self, output) {
          output.print("import.meta");
      });

      DEFPRINT(AST_NameMapping, function(self, output) {
          var is_import = output.parent() instanceof AST_Import;
          var definition = self.name.definition();
          var names_are_different =
              (definition && definition.mangled_name || self.name.name) !==
              self.foreign_name.name;
          if (names_are_different) {
              if (is_import) {
                  output.print(self.foreign_name.name);
              } else {
                  self.name.print(output);
              }
              output.space();
              output.print("as");
              output.space();
              if (is_import) {
                  self.name.print(output);
              } else {
                  output.print(self.foreign_name.name);
              }
          } else {
              self.name.print(output);
          }
      });

      DEFPRINT(AST_Export, function(self, output) {
          output.print("export");
          output.space();
          if (self.is_default) {
              output.print("default");
              output.space();
          }
          if (self.exported_names) {
              if (self.exported_names.length === 1 && self.exported_names[0].name.name === "*") {
                  self.exported_names[0].print(output);
              } else {
                  output.print("{");
                  self.exported_names.forEach(function(name_export, i) {
                      output.space();
                      name_export.print(output);
                      if (i < self.exported_names.length - 1) {
                          output.print(",");
                      }
                  });
                  output.space();
                  output.print("}");
              }
          } else if (self.exported_value) {
              self.exported_value.print(output);
          } else if (self.exported_definition) {
              self.exported_definition.print(output);
              if (self.exported_definition instanceof AST_Definitions) return;
          }
          if (self.module_name) {
              output.space();
              output.print("from");
              output.space();
              self.module_name.print(output);
          }
          if (self.assert_clause) {
              output.print("assert");
              self.assert_clause.print(output);
          }
          if (self.exported_value
                  && !(self.exported_value instanceof AST_Defun ||
                      self.exported_value instanceof AST_Function ||
                      self.exported_value instanceof AST_Class)
              || self.module_name
              || self.exported_names
          ) {
              output.semicolon();
          }
      });

      function parenthesize_for_noin(node, output, noin) {
          var parens = false;
          // need to take some precautions here:
          //    https://github.com/mishoo/UglifyJS2/issues/60
          if (noin) {
              parens = walk(node, node => {
                  // Don't go into scopes -- except arrow functions:
                  // https://github.com/terser/terser/issues/1019#issuecomment-877642607
                  if (node instanceof AST_Scope && !(node instanceof AST_Arrow)) {
                      return true;
                  }
                  if (node instanceof AST_Binary && node.operator == "in") {
                      return walk_abort;  // makes walk() return true
                  }
              });
          }
          node.print(output, parens);
      }

      DEFPRINT(AST_VarDef, function(self, output) {
          self.name.print(output);
          if (self.value) {
              output.space();
              output.print("=");
              output.space();
              var p = output.parent(1);
              var noin = p instanceof AST_For || p instanceof AST_ForIn;
              parenthesize_for_noin(self.value, output, noin);
          }
      });

      /* -----[ other expressions ]----- */
      DEFPRINT(AST_Call, function(self, output) {
          self.expression.print(output);
          if (self instanceof AST_New && self.args.length === 0)
              return;
          if (self.expression instanceof AST_Call || self.expression instanceof AST_Lambda) {
              output.add_mapping(self.start);
          }
          if (self.optional) output.print("?.");
          output.with_parens(function() {
              self.args.forEach(function(expr, i) {
                  if (i) output.comma();
                  expr.print(output);
              });
          });
      });
      DEFPRINT(AST_New, function(self, output) {
          output.print("new");
          output.space();
          AST_Call.prototype._codegen(self, output);
      });

      AST_Sequence.DEFMETHOD("_do_print", function(output) {
          this.expressions.forEach(function(node, index) {
              if (index > 0) {
                  output.comma();
                  if (output.should_break()) {
                      output.newline();
                      output.indent();
                  }
              }
              node.print(output);
          });
      });
      DEFPRINT(AST_Sequence, function(self, output) {
          self._do_print(output);
          // var p = output.parent();
          // if (p instanceof AST_Statement) {
          //     output.with_indent(output.next_indent(), function(){
          //         self._do_print(output);
          //     });
          // } else {
          //     self._do_print(output);
          // }
      });
      DEFPRINT(AST_Dot, function(self, output) {
          var expr = self.expression;
          expr.print(output);
          var prop = self.property;
          var print_computed = ALL_RESERVED_WORDS.has(prop)
              ? output.option("ie8")
              : !is_identifier_string(
                  prop,
                  output.option("ecma") >= 2015 || output.option("safari10")
              );

          if (self.optional) output.print("?.");

          if (print_computed) {
              output.print("[");
              output.add_mapping(self.end);
              output.print_string(prop);
              output.print("]");
          } else {
              if (expr instanceof AST_Number && expr.getValue() >= 0) {
                  if (!/[xa-f.)]/i.test(output.last())) {
                      output.print(".");
                  }
              }
              if (!self.optional) output.print(".");
              // the name after dot would be mapped about here.
              output.add_mapping(self.end);
              output.print_name(prop);
          }
      });
      DEFPRINT(AST_DotHash, function(self, output) {
          var expr = self.expression;
          expr.print(output);
          var prop = self.property;

          if (self.optional) output.print("?");
          output.print(".#");
          output.add_mapping(self.end);
          output.print_name(prop);
      });
      DEFPRINT(AST_Sub, function(self, output) {
          self.expression.print(output);
          if (self.optional) output.print("?.");
          output.print("[");
          self.property.print(output);
          output.print("]");
      });
      DEFPRINT(AST_Chain, function(self, output) {
          self.expression.print(output);
      });
      DEFPRINT(AST_UnaryPrefix, function(self, output) {
          var op = self.operator;
          output.print(op);
          if (/^[a-z]/i.test(op)
              || (/[+-]$/.test(op)
                  && self.expression instanceof AST_UnaryPrefix
                  && /^[+-]/.test(self.expression.operator))) {
              output.space();
          }
          self.expression.print(output);
      });
      DEFPRINT(AST_UnaryPostfix, function(self, output) {
          self.expression.print(output);
          output.print(self.operator);
      });
      DEFPRINT(AST_Binary, function(self, output) {
          var op = self.operator;
          self.left.print(output);
          if (op[0] == ">" /* ">>" ">>>" ">" ">=" */
              && self.left instanceof AST_UnaryPostfix
              && self.left.operator == "--") {
              // space is mandatory to avoid outputting -->
              output.print(" ");
          } else {
              // the space is optional depending on "beautify"
              output.space();
          }
          output.print(op);
          if ((op == "<" || op == "<<")
              && self.right instanceof AST_UnaryPrefix
              && self.right.operator == "!"
              && self.right.expression instanceof AST_UnaryPrefix
              && self.right.expression.operator == "--") {
              // space is mandatory to avoid outputting <!--
              output.print(" ");
          } else {
              // the space is optional depending on "beautify"
              output.space();
          }
          self.right.print(output);
      });
      DEFPRINT(AST_Conditional, function(self, output) {
          self.condition.print(output);
          output.space();
          output.print("?");
          output.space();
          self.consequent.print(output);
          output.space();
          output.colon();
          self.alternative.print(output);
      });

      /* -----[ literals ]----- */
      DEFPRINT(AST_Array, function(self, output) {
          output.with_square(function() {
              var a = self.elements, len = a.length;
              if (len > 0) output.space();
              a.forEach(function(exp, i) {
                  if (i) output.comma();
                  exp.print(output);
                  // If the final element is a hole, we need to make sure it
                  // doesn't look like a trailing comma, by inserting an actual
                  // trailing comma.
                  if (i === len - 1 && exp instanceof AST_Hole)
                    output.comma();
              });
              if (len > 0) output.space();
          });
      });
      DEFPRINT(AST_Object, function(self, output) {
          if (self.properties.length > 0) output.with_block(function() {
              self.properties.forEach(function(prop, i) {
                  if (i) {
                      output.print(",");
                      output.newline();
                  }
                  output.indent();
                  prop.print(output);
              });
              output.newline();
          });
          else print_braced_empty(self, output);
      });
      DEFPRINT(AST_Class, function(self, output) {
          output.print("class");
          output.space();
          if (self.name) {
              self.name.print(output);
              output.space();
          }
          if (self.extends) {
              var parens = (
                     !(self.extends instanceof AST_SymbolRef)
                  && !(self.extends instanceof AST_PropAccess)
                  && !(self.extends instanceof AST_ClassExpression)
                  && !(self.extends instanceof AST_Function)
              );
              output.print("extends");
              if (parens) {
                  output.print("(");
              } else {
                  output.space();
              }
              self.extends.print(output);
              if (parens) {
                  output.print(")");
              } else {
                  output.space();
              }
          }
          if (self.properties.length > 0) output.with_block(function() {
              self.properties.forEach(function(prop, i) {
                  if (i) {
                      output.newline();
                  }
                  output.indent();
                  prop.print(output);
              });
              output.newline();
          });
          else output.print("{}");
      });
      DEFPRINT(AST_NewTarget, function(self, output) {
          output.print("new.target");
      });

      function print_property_name(key, quote, output) {
          if (output.option("quote_keys")) {
              return output.print_string(key);
          }
          if ("" + +key == key && key >= 0) {
              if (output.option("keep_numbers")) {
                  return output.print(key);
              }
              return output.print(make_num(key));
          }
          var print_string = ALL_RESERVED_WORDS.has(key)
              ? output.option("ie8")
              : (
                  output.option("ecma") < 2015 || output.option("safari10")
                      ? !is_basic_identifier_string(key)
                      : !is_identifier_string(key, true)
              );
          if (print_string || (quote && output.option("keep_quoted_props"))) {
              return output.print_string(key, quote);
          }
          return output.print_name(key);
      }

      DEFPRINT(AST_ObjectKeyVal, function(self, output) {
          function get_name(self) {
              var def = self.definition();
              return def ? def.mangled_name || def.name : self.name;
          }

          var allowShortHand = output.option("shorthand");
          if (allowShortHand &&
              self.value instanceof AST_Symbol &&
              is_identifier_string(
                  self.key,
                  output.option("ecma") >= 2015 || output.option("safari10")
              ) &&
              get_name(self.value) === self.key &&
              !ALL_RESERVED_WORDS.has(self.key)
          ) {
              print_property_name(self.key, self.quote, output);

          } else if (allowShortHand &&
              self.value instanceof AST_DefaultAssign &&
              self.value.left instanceof AST_Symbol &&
              is_identifier_string(
                  self.key,
                  output.option("ecma") >= 2015 || output.option("safari10")
              ) &&
              get_name(self.value.left) === self.key
          ) {
              print_property_name(self.key, self.quote, output);
              output.space();
              output.print("=");
              output.space();
              self.value.right.print(output);
          } else {
              if (!(self.key instanceof AST_Node)) {
                  print_property_name(self.key, self.quote, output);
              } else {
                  output.with_square(function() {
                      self.key.print(output);
                  });
              }
              output.colon();
              self.value.print(output);
          }
      });
      DEFPRINT(AST_ClassPrivateProperty, (self, output) => {
          if (self.static) {
              output.print("static");
              output.space();
          }

          output.print("#");
          
          print_property_name(self.key.name, self.quote, output);

          if (self.value) {
              output.print("=");
              self.value.print(output);
          }

          output.semicolon();
      });
      DEFPRINT(AST_ClassProperty, (self, output) => {
          if (self.static) {
              output.print("static");
              output.space();
          }

          if (self.key instanceof AST_SymbolClassProperty) {
              print_property_name(self.key.name, self.quote, output);
          } else {
              output.print("[");
              self.key.print(output);
              output.print("]");
          }

          if (self.value) {
              output.print("=");
              self.value.print(output);
          }

          output.semicolon();
      });
      AST_ObjectProperty.DEFMETHOD("_print_getter_setter", function(type, is_private, output) {
          var self = this;
          if (self.static) {
              output.print("static");
              output.space();
          }
          if (type) {
              output.print(type);
              output.space();
          }
          if (self.key instanceof AST_SymbolMethod) {
              if (is_private) output.print("#");
              print_property_name(self.key.name, self.quote, output);
          } else {
              output.with_square(function() {
                  self.key.print(output);
              });
          }
          self.value._do_print(output, true);
      });
      DEFPRINT(AST_ObjectSetter, function(self, output) {
          self._print_getter_setter("set", false, output);
      });
      DEFPRINT(AST_ObjectGetter, function(self, output) {
          self._print_getter_setter("get", false, output);
      });
      DEFPRINT(AST_PrivateSetter, function(self, output) {
          self._print_getter_setter("set", true, output);
      });
      DEFPRINT(AST_PrivateGetter, function(self, output) {
          self._print_getter_setter("get", true, output);
      });
      DEFPRINT(AST_PrivateMethod, function(self, output) {
          var type;
          if (self.is_generator && self.async) {
              type = "async*";
          } else if (self.is_generator) {
              type = "*";
          } else if (self.async) {
              type = "async";
          }
          self._print_getter_setter(type, true, output);
      });
      DEFPRINT(AST_ConciseMethod, function(self, output) {
          var type;
          if (self.is_generator && self.async) {
              type = "async*";
          } else if (self.is_generator) {
              type = "*";
          } else if (self.async) {
              type = "async";
          }
          self._print_getter_setter(type, false, output);
      });
      AST_Symbol.DEFMETHOD("_do_print", function(output) {
          var def = this.definition();
          output.print_name(def ? def.mangled_name || def.name : this.name);
      });
      DEFPRINT(AST_Symbol, function (self, output) {
          self._do_print(output);
      });
      DEFPRINT(AST_Hole, noop);
      DEFPRINT(AST_This, function(self, output) {
          output.print("this");
      });
      DEFPRINT(AST_Super, function(self, output) {
          output.print("super");
      });
      DEFPRINT(AST_Constant, function(self, output) {
          output.print(self.getValue());
      });
      DEFPRINT(AST_String, function(self, output) {
          output.print_string(self.getValue(), self.quote, output.in_directive);
      });
      DEFPRINT(AST_Number, function(self, output) {
          if ((output.option("keep_numbers") || output.use_asm) && self.raw) {
              output.print(self.raw);
          } else {
              output.print(make_num(self.getValue()));
          }
      });
      DEFPRINT(AST_BigInt, function(self, output) {
          output.print(self.getValue() + "n");
      });

      const r_slash_script = /(<\s*\/\s*script)/i;
      const slash_script_replace = (_, $1) => $1.replace("/", "\\/");
      DEFPRINT(AST_RegExp, function(self, output) {
          let { source, flags } = self.getValue();
          source = regexp_source_fix(source);
          flags = flags ? sort_regexp_flags(flags) : "";
          source = source.replace(r_slash_script, slash_script_replace);

          output.print(output.to_utf8(`/${source}/${flags}`, false, true));

          const parent = output.parent();
          if (
              parent instanceof AST_Binary
              && /^\w/.test(parent.operator)
              && parent.left === self
          ) {
              output.print(" ");
          }
      });

      function force_statement(stat, output) {
          if (output.option("braces")) {
              make_block(stat, output);
          } else {
              if (!stat || stat instanceof AST_EmptyStatement)
                  output.force_semicolon();
              else
                  stat.print(output);
          }
      }

      function best_of(a) {
          var best = a[0], len = best.length;
          for (var i = 1; i < a.length; ++i) {
              if (a[i].length < len) {
                  best = a[i];
                  len = best.length;
              }
          }
          return best;
      }

      function make_num(num) {
          var str = num.toString(10).replace(/^0\./, ".").replace("e+", "e");
          var candidates = [ str ];
          if (Math.floor(num) === num) {
              if (num < 0) {
                  candidates.push("-0x" + (-num).toString(16).toLowerCase());
              } else {
                  candidates.push("0x" + num.toString(16).toLowerCase());
              }
          }
          var match, len, digits;
          if (match = /^\.0+/.exec(str)) {
              len = match[0].length;
              digits = str.slice(len);
              candidates.push(digits + "e-" + (digits.length + len - 1));
          } else if (match = /0+$/.exec(str)) {
              len = match[0].length;
              candidates.push(str.slice(0, -len) + "e" + len);
          } else if (match = /^(\d)\.(\d+)e(-?\d+)$/.exec(str)) {
              candidates.push(match[1] + match[2] + "e" + (match[3] - match[2].length));
          }
          return best_of(candidates);
      }

      function make_block(stmt, output) {
          if (!stmt || stmt instanceof AST_EmptyStatement)
              output.print("{}");
          else if (stmt instanceof AST_BlockStatement)
              stmt.print(output);
          else output.with_block(function() {
              output.indent();
              stmt.print(output);
              output.newline();
          });
      }

      /* -----[ source map generators ]----- */

      function DEFMAP(nodetype, generator) {
          nodetype.forEach(function(nodetype) {
              nodetype.DEFMETHOD("add_source_map", generator);
          });
      }

      DEFMAP([
          // We could easily add info for ALL nodes, but it seems to me that
          // would be quite wasteful, hence this noop in the base class.
          AST_Node,
          // since the label symbol will mark it
          AST_LabeledStatement,
          AST_Toplevel,
      ], noop);

      // XXX: I'm not exactly sure if we need it for all of these nodes,
      // or if we should add even more.
      DEFMAP([
          AST_Array,
          AST_BlockStatement,
          AST_Catch,
          AST_Class,
          AST_Constant,
          AST_Debugger,
          AST_Definitions,
          AST_Directive,
          AST_Finally,
          AST_Jump,
          AST_Lambda,
          AST_New,
          AST_Object,
          AST_StatementWithBody,
          AST_Symbol,
          AST_Switch,
          AST_SwitchBranch,
          AST_TemplateString,
          AST_TemplateSegment,
          AST_Try,
      ], function(output) {
          output.add_mapping(this.start);
      });

      DEFMAP([
          AST_ObjectGetter,
          AST_ObjectSetter,
          AST_PrivateGetter,
          AST_PrivateSetter,
      ], function(output) {
          output.add_mapping(this.key.end, this.key.name);
      });

      DEFMAP([ AST_ObjectProperty ], function(output) {
          output.add_mapping(this.start, this.key);
      });
  })();

  const shallow_cmp = (node1, node2) => {
      return (
          node1 === null && node2 === null
          || node1.TYPE === node2.TYPE && node1.shallow_cmp(node2)
      );
  };

  const equivalent_to = (tree1, tree2) => {
      if (!shallow_cmp(tree1, tree2)) return false;
      const walk_1_state = [tree1];
      const walk_2_state = [tree2];

      const walk_1_push = walk_1_state.push.bind(walk_1_state);
      const walk_2_push = walk_2_state.push.bind(walk_2_state);

      while (walk_1_state.length && walk_2_state.length) {
          const node_1 = walk_1_state.pop();
          const node_2 = walk_2_state.pop();

          if (!shallow_cmp(node_1, node_2)) return false;

          node_1._children_backwards(walk_1_push);
          node_2._children_backwards(walk_2_push);

          if (walk_1_state.length !== walk_2_state.length) {
              // Different number of children
              return false;
          }
      }

      return walk_1_state.length == 0 && walk_2_state.length == 0;
  };

  const pass_through = () => true;

  AST_Node.prototype.shallow_cmp = function () {
      throw new Error("did not find a shallow_cmp function for " + this.constructor.name);
  };

  AST_Debugger.prototype.shallow_cmp = pass_through;

  AST_Directive.prototype.shallow_cmp = function(other) {
      return this.value === other.value;
  };

  AST_SimpleStatement.prototype.shallow_cmp = pass_through;

  AST_Block.prototype.shallow_cmp = pass_through;

  AST_EmptyStatement.prototype.shallow_cmp = pass_through;

  AST_LabeledStatement.prototype.shallow_cmp = function(other) {
      return this.label.name === other.label.name;
  };

  AST_Do.prototype.shallow_cmp = pass_through;

  AST_While.prototype.shallow_cmp = pass_through;

  AST_For.prototype.shallow_cmp = function(other) {
      return (this.init == null ? other.init == null : this.init === other.init) && (this.condition == null ? other.condition == null : this.condition === other.condition) && (this.step == null ? other.step == null : this.step === other.step);
  };

  AST_ForIn.prototype.shallow_cmp = pass_through;

  AST_ForOf.prototype.shallow_cmp = pass_through;

  AST_With.prototype.shallow_cmp = pass_through;

  AST_Toplevel.prototype.shallow_cmp = pass_through;

  AST_Expansion.prototype.shallow_cmp = pass_through;

  AST_Lambda.prototype.shallow_cmp = function(other) {
      return this.is_generator === other.is_generator && this.async === other.async;
  };

  AST_Destructuring.prototype.shallow_cmp = function(other) {
      return this.is_array === other.is_array;
  };

  AST_PrefixedTemplateString.prototype.shallow_cmp = pass_through;

  AST_TemplateString.prototype.shallow_cmp = pass_through;

  AST_TemplateSegment.prototype.shallow_cmp = function(other) {
      return this.value === other.value;
  };

  AST_Jump.prototype.shallow_cmp = pass_through;

  AST_LoopControl.prototype.shallow_cmp = pass_through;

  AST_Await.prototype.shallow_cmp = pass_through;

  AST_Yield.prototype.shallow_cmp = function(other) {
      return this.is_star === other.is_star;
  };

  AST_If.prototype.shallow_cmp = function(other) {
      return this.alternative == null ? other.alternative == null : this.alternative === other.alternative;
  };

  AST_Switch.prototype.shallow_cmp = pass_through;

  AST_SwitchBranch.prototype.shallow_cmp = pass_through;

  AST_Try.prototype.shallow_cmp = function(other) {
      return (this.bcatch == null ? other.bcatch == null : this.bcatch === other.bcatch) && (this.bfinally == null ? other.bfinally == null : this.bfinally === other.bfinally);
  };

  AST_Catch.prototype.shallow_cmp = function(other) {
      return this.argname == null ? other.argname == null : this.argname === other.argname;
  };

  AST_Finally.prototype.shallow_cmp = pass_through;

  AST_Definitions.prototype.shallow_cmp = pass_through;

  AST_VarDef.prototype.shallow_cmp = function(other) {
      return this.value == null ? other.value == null : this.value === other.value;
  };

  AST_NameMapping.prototype.shallow_cmp = pass_through;

  AST_Import.prototype.shallow_cmp = function(other) {
      return (this.imported_name == null ? other.imported_name == null : this.imported_name === other.imported_name) && (this.imported_names == null ? other.imported_names == null : this.imported_names === other.imported_names);
  };

  AST_ImportMeta.prototype.shallow_cmp = pass_through;

  AST_Export.prototype.shallow_cmp = function(other) {
      return (this.exported_definition == null ? other.exported_definition == null : this.exported_definition === other.exported_definition) && (this.exported_value == null ? other.exported_value == null : this.exported_value === other.exported_value) && (this.exported_names == null ? other.exported_names == null : this.exported_names === other.exported_names) && this.module_name === other.module_name && this.is_default === other.is_default;
  };

  AST_Call.prototype.shallow_cmp = pass_through;

  AST_Sequence.prototype.shallow_cmp = pass_through;

  AST_PropAccess.prototype.shallow_cmp = pass_through;

  AST_Chain.prototype.shallow_cmp = pass_through;

  AST_Dot.prototype.shallow_cmp = function(other) {
      return this.property === other.property;
  };

  AST_DotHash.prototype.shallow_cmp = function(other) {
      return this.property === other.property;
  };

  AST_Unary.prototype.shallow_cmp = function(other) {
      return this.operator === other.operator;
  };

  AST_Binary.prototype.shallow_cmp = function(other) {
      return this.operator === other.operator;
  };

  AST_Conditional.prototype.shallow_cmp = pass_through;

  AST_Array.prototype.shallow_cmp = pass_through;

  AST_Object.prototype.shallow_cmp = pass_through;

  AST_ObjectProperty.prototype.shallow_cmp = pass_through;

  AST_ObjectKeyVal.prototype.shallow_cmp = function(other) {
      return this.key === other.key;
  };

  AST_ObjectSetter.prototype.shallow_cmp = function(other) {
      return this.static === other.static;
  };

  AST_ObjectGetter.prototype.shallow_cmp = function(other) {
      return this.static === other.static;
  };

  AST_ConciseMethod.prototype.shallow_cmp = function(other) {
      return this.static === other.static && this.is_generator === other.is_generator && this.async === other.async;
  };

  AST_Class.prototype.shallow_cmp = function(other) {
      return (this.name == null ? other.name == null : this.name === other.name) && (this.extends == null ? other.extends == null : this.extends === other.extends);
  };

  AST_ClassProperty.prototype.shallow_cmp = function(other) {
      return this.static === other.static;
  };

  AST_Symbol.prototype.shallow_cmp = function(other) {
      return this.name === other.name;
  };

  AST_NewTarget.prototype.shallow_cmp = pass_through;

  AST_This.prototype.shallow_cmp = pass_through;

  AST_Super.prototype.shallow_cmp = pass_through;

  AST_String.prototype.shallow_cmp = function(other) {
      return this.value === other.value;
  };

  AST_Number.prototype.shallow_cmp = function(other) {
      return this.value === other.value;
  };

  AST_BigInt.prototype.shallow_cmp = function(other) {
      return this.value === other.value;
  };

  AST_RegExp.prototype.shallow_cmp = function (other) {
      return (
          this.value.flags === other.value.flags
          && this.value.source === other.value.source
      );
  };

  AST_Atom.prototype.shallow_cmp = pass_through;

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  const MASK_EXPORT_DONT_MANGLE = 1 << 0;
  const MASK_EXPORT_WANT_MANGLE = 1 << 1;

  let function_defs = null;
  let unmangleable_names = null;
  /**
   * When defined, there is a function declaration somewhere that's inside of a block.
   * See https://tc39.es/ecma262/multipage/additional-ecmascript-features-for-web-browsers.html#sec-block-level-function-declarations-web-legacy-compatibility-semantics
  */
  let scopes_with_block_defuns = null;

  class SymbolDef {
      constructor(scope, orig, init) {
          this.name = orig.name;
          this.orig = [ orig ];
          this.init = init;
          this.eliminated = 0;
          this.assignments = 0;
          this.scope = scope;
          this.replaced = 0;
          this.global = false;
          this.export = 0;
          this.mangled_name = null;
          this.undeclared = false;
          this.id = SymbolDef.next_id++;
          this.chained = false;
          this.direct_access = false;
          this.escaped = 0;
          this.recursive_refs = 0;
          this.references = [];
          this.should_replace = undefined;
          this.single_use = false;
          this.fixed = false;
          Object.seal(this);
      }
      fixed_value() {
          if (!this.fixed || this.fixed instanceof AST_Node) return this.fixed;
          return this.fixed();
      }
      unmangleable(options) {
          if (!options) options = {};

          if (
              function_defs &&
              function_defs.has(this.id) &&
              keep_name(options.keep_fnames, this.orig[0].name)
          ) return true;

          return this.global && !options.toplevel
              || (this.export & MASK_EXPORT_DONT_MANGLE)
              || this.undeclared
              || !options.eval && this.scope.pinned()
              || (this.orig[0] instanceof AST_SymbolLambda
                    || this.orig[0] instanceof AST_SymbolDefun) && keep_name(options.keep_fnames, this.orig[0].name)
              || this.orig[0] instanceof AST_SymbolMethod
              || (this.orig[0] instanceof AST_SymbolClass
                    || this.orig[0] instanceof AST_SymbolDefClass) && keep_name(options.keep_classnames, this.orig[0].name);
      }
      mangle(options) {
          const cache = options.cache && options.cache.props;
          if (this.global && cache && cache.has(this.name)) {
              this.mangled_name = cache.get(this.name);
          } else if (!this.mangled_name && !this.unmangleable(options)) {
              var s = this.scope;
              var sym = this.orig[0];
              if (options.ie8 && sym instanceof AST_SymbolLambda)
                  s = s.parent_scope;
              const redefinition = redefined_catch_def(this);
              this.mangled_name = redefinition
                  ? redefinition.mangled_name || redefinition.name
                  : s.next_mangled(options, this);
              if (this.global && cache) {
                  cache.set(this.name, this.mangled_name);
              }
          }
      }
  }

  SymbolDef.next_id = 1;

  function redefined_catch_def(def) {
      if (def.orig[0] instanceof AST_SymbolCatch
          && def.scope.is_block_scope()
      ) {
          return def.scope.get_defun_scope().variables.get(def.name);
      }
  }

  AST_Scope.DEFMETHOD("figure_out_scope", function(options, { parent_scope = null, toplevel = this } = {}) {
      options = defaults(options, {
          cache: null,
          ie8: false,
          safari10: false,
      });

      if (!(toplevel instanceof AST_Toplevel)) {
          throw new Error("Invalid toplevel scope");
      }

      // pass 1: setup scope chaining and handle definitions
      var scope = this.parent_scope = parent_scope;
      var labels = new Map();
      var defun = null;
      var in_destructuring = null;
      var for_scopes = [];
      var tw = new TreeWalker((node, descend) => {
          if (node.is_block_scope()) {
              const save_scope = scope;
              node.block_scope = scope = new AST_Scope(node);
              scope._block_scope = true;
              // AST_Try in the AST sadly *is* (not has) a body itself,
              // and its catch and finally branches are children of the AST_Try itself
              const parent_scope = node instanceof AST_Catch
                  ? save_scope.parent_scope
                  : save_scope;
              scope.init_scope_vars(parent_scope);
              scope.uses_with = save_scope.uses_with;
              scope.uses_eval = save_scope.uses_eval;
              if (options.safari10) {
                  if (node instanceof AST_For || node instanceof AST_ForIn) {
                      for_scopes.push(scope);
                  }
              }

              if (node instanceof AST_Switch) {
                  // XXX: HACK! Ensure the switch expression gets the correct scope (the parent scope) and the body gets the contained scope
                  // AST_Switch has a scope within the body, but it itself "is a block scope"
                  // This means the switched expression has to belong to the outer scope
                  // while the body inside belongs to the switch itself.
                  // This is pretty nasty and warrants an AST change similar to AST_Try (read above)
                  const the_block_scope = scope;
                  scope = save_scope;
                  node.expression.walk(tw);
                  scope = the_block_scope;
                  for (let i = 0; i < node.body.length; i++) {
                      node.body[i].walk(tw);
                  }
              } else {
                  descend();
              }
              scope = save_scope;
              return true;
          }
          if (node instanceof AST_Destructuring) {
              const save_destructuring = in_destructuring;
              in_destructuring = node;
              descend();
              in_destructuring = save_destructuring;
              return true;
          }
          if (node instanceof AST_Scope) {
              node.init_scope_vars(scope);
              var save_scope = scope;
              var save_defun = defun;
              var save_labels = labels;
              defun = scope = node;
              labels = new Map();
              descend();
              scope = save_scope;
              defun = save_defun;
              labels = save_labels;
              return true;        // don't descend again in TreeWalker
          }
          if (node instanceof AST_LabeledStatement) {
              var l = node.label;
              if (labels.has(l.name)) {
                  throw new Error(string_template("Label {name} defined twice", l));
              }
              labels.set(l.name, l);
              descend();
              labels.delete(l.name);
              return true;        // no descend again
          }
          if (node instanceof AST_With) {
              for (var s = scope; s; s = s.parent_scope)
                  s.uses_with = true;
              return;
          }
          if (node instanceof AST_Symbol) {
              node.scope = scope;
          }
          if (node instanceof AST_Label) {
              node.thedef = node;
              node.references = [];
          }
          if (node instanceof AST_SymbolLambda) {
              defun.def_function(node, node.name == "arguments" ? undefined : defun);
          } else if (node instanceof AST_SymbolDefun) {
              // Careful here, the scope where this should be defined is
              // the parent scope.  The reason is that we enter a new
              // scope when we encounter the AST_Defun node (which is
              // instanceof AST_Scope) but we get to the symbol a bit
              // later.
              const closest_scope = defun.parent_scope;

              // In strict mode, function definitions are block-scoped
              node.scope = tw.directives["use strict"]
                  ? closest_scope
                  : closest_scope.get_defun_scope();

              mark_export(node.scope.def_function(node, defun), 1);
          } else if (node instanceof AST_SymbolClass) {
              mark_export(defun.def_variable(node, defun), 1);
          } else if (node instanceof AST_SymbolImport) {
              scope.def_variable(node);
          } else if (node instanceof AST_SymbolDefClass) {
              // This deals with the name of the class being available
              // inside the class.
              mark_export((node.scope = defun.parent_scope).def_function(node, defun), 1);
          } else if (
              node instanceof AST_SymbolVar
              || node instanceof AST_SymbolLet
              || node instanceof AST_SymbolConst
              || node instanceof AST_SymbolCatch
          ) {
              var def;
              if (node instanceof AST_SymbolBlockDeclaration) {
                  def = scope.def_variable(node, null);
              } else {
                  def = defun.def_variable(node, node.TYPE == "SymbolVar" ? null : undefined);
              }
              if (!def.orig.every((sym) => {
                  if (sym === node) return true;
                  if (node instanceof AST_SymbolBlockDeclaration) {
                      return sym instanceof AST_SymbolLambda;
                  }
                  return !(sym instanceof AST_SymbolLet || sym instanceof AST_SymbolConst);
              })) {
                  js_error(
                      `"${node.name}" is redeclared`,
                      node.start.file,
                      node.start.line,
                      node.start.col,
                      node.start.pos
                  );
              }
              if (!(node instanceof AST_SymbolFunarg)) mark_export(def, 2);
              if (defun !== scope) {
                  node.mark_enclosed();
                  var def = scope.find_variable(node);
                  if (node.thedef !== def) {
                      node.thedef = def;
                      node.reference();
                  }
              }
          } else if (node instanceof AST_LabelRef) {
              var sym = labels.get(node.name);
              if (!sym) throw new Error(string_template("Undefined label {name} [{line},{col}]", {
                  name: node.name,
                  line: node.start.line,
                  col: node.start.col
              }));
              node.thedef = sym;
          }
          if (!(scope instanceof AST_Toplevel) && (node instanceof AST_Export || node instanceof AST_Import)) {
              js_error(
                  `"${node.TYPE}" statement may only appear at the top level`,
                  node.start.file,
                  node.start.line,
                  node.start.col,
                  node.start.pos
              );
          }
      });
      this.walk(tw);

      function mark_export(def, level) {
          if (in_destructuring) {
              var i = 0;
              do {
                  level++;
              } while (tw.parent(i++) !== in_destructuring);
          }
          var node = tw.parent(level);
          if (def.export = node instanceof AST_Export ? MASK_EXPORT_DONT_MANGLE : 0) {
              var exported = node.exported_definition;
              if ((exported instanceof AST_Defun || exported instanceof AST_DefClass) && node.is_default) {
                  def.export = MASK_EXPORT_WANT_MANGLE;
              }
          }
      }

      // pass 2: find back references and eval
      const is_toplevel = this instanceof AST_Toplevel;
      if (is_toplevel) {
          this.globals = new Map();
      }

      var tw = new TreeWalker(node => {
          if (node instanceof AST_LoopControl && node.label) {
              node.label.thedef.references.push(node);
              return true;
          }
          if (node instanceof AST_SymbolRef) {
              var name = node.name;
              if (name == "eval" && tw.parent() instanceof AST_Call) {
                  for (var s = node.scope; s && !s.uses_eval; s = s.parent_scope) {
                      s.uses_eval = true;
                  }
              }
              var sym;
              if (tw.parent() instanceof AST_NameMapping && tw.parent(1).module_name
                  || !(sym = node.scope.find_variable(name))) {

                  sym = toplevel.def_global(node);
                  if (node instanceof AST_SymbolExport) sym.export = MASK_EXPORT_DONT_MANGLE;
              } else if (sym.scope instanceof AST_Lambda && name == "arguments") {
                  sym.scope.uses_arguments = true;
              }
              node.thedef = sym;
              node.reference();
              if (node.scope.is_block_scope()
                  && !(sym.orig[0] instanceof AST_SymbolBlockDeclaration)) {
                  node.scope = node.scope.get_defun_scope();
              }
              return true;
          }
          // ensure mangling works if catch reuses a scope variable
          var def;
          if (node instanceof AST_SymbolCatch && (def = redefined_catch_def(node.definition()))) {
              var s = node.scope;
              while (s) {
                  push_uniq(s.enclosed, def);
                  if (s === def.scope) break;
                  s = s.parent_scope;
              }
          }
      });
      this.walk(tw);

      // pass 3: work around IE8 and Safari catch scope bugs
      if (options.ie8 || options.safari10) {
          walk(this, node => {
              if (node instanceof AST_SymbolCatch) {
                  var name = node.name;
                  var refs = node.thedef.references;
                  var scope = node.scope.get_defun_scope();
                  var def = scope.find_variable(name)
                      || toplevel.globals.get(name)
                      || scope.def_variable(node);
                  refs.forEach(function(ref) {
                      ref.thedef = def;
                      ref.reference();
                  });
                  node.thedef = def;
                  node.reference();
                  return true;
              }
          });
      }

      // pass 4: add symbol definitions to loop scopes
      // Safari/Webkit bug workaround - loop init let variable shadowing argument.
      // https://github.com/mishoo/UglifyJS2/issues/1753
      // https://bugs.webkit.org/show_bug.cgi?id=171041
      if (options.safari10) {
          for (const scope of for_scopes) {
              scope.parent_scope.variables.forEach(function(def) {
                  push_uniq(scope.enclosed, def);
              });
          }
      }
  });

  AST_Toplevel.DEFMETHOD("def_global", function(node) {
      var globals = this.globals, name = node.name;
      if (globals.has(name)) {
          return globals.get(name);
      } else {
          var g = new SymbolDef(this, node);
          g.undeclared = true;
          g.global = true;
          globals.set(name, g);
          return g;
      }
  });

  AST_Scope.DEFMETHOD("init_scope_vars", function(parent_scope) {
      this.variables = new Map();         // map name to AST_SymbolVar (variables defined in this scope; includes functions)
      this.uses_with = false;             // will be set to true if this or some nested scope uses the `with` statement
      this.uses_eval = false;             // will be set to true if this or nested scope uses the global `eval`
      this.parent_scope = parent_scope;   // the parent scope
      this.enclosed = [];                 // a list of variables from this or outer scope(s) that are referenced from this or inner scopes
      this.cname = -1;                    // the current index for mangling functions/variables
  });

  AST_Scope.DEFMETHOD("conflicting_def", function (name) {
      return (
          this.enclosed.find(def => def.name === name)
          || this.variables.has(name)
          || (this.parent_scope && this.parent_scope.conflicting_def(name))
      );
  });

  AST_Scope.DEFMETHOD("conflicting_def_shallow", function (name) {
      return (
          this.enclosed.find(def => def.name === name)
          || this.variables.has(name)
      );
  });

  AST_Scope.DEFMETHOD("add_child_scope", function (scope) {
      // `scope` is going to be moved into `this` right now.
      // Update the required scopes' information

      if (scope.parent_scope === this) return;

      scope.parent_scope = this;

      // TODO uses_with, uses_eval, etc

      const scope_ancestry = (() => {
          const ancestry = [];
          let cur = this;
          do {
              ancestry.push(cur);
          } while ((cur = cur.parent_scope));
          ancestry.reverse();
          return ancestry;
      })();

      const new_scope_enclosed_set = new Set(scope.enclosed);
      const to_enclose = [];
      for (const scope_topdown of scope_ancestry) {
          to_enclose.forEach(e => push_uniq(scope_topdown.enclosed, e));
          for (const def of scope_topdown.variables.values()) {
              if (new_scope_enclosed_set.has(def)) {
                  push_uniq(to_enclose, def);
                  push_uniq(scope_topdown.enclosed, def);
              }
          }
      }
  });

  function find_scopes_visible_from(scopes) {
      const found_scopes = new Set();

      for (const scope of new Set(scopes)) {
          (function bubble_up(scope) {
              if (scope == null || found_scopes.has(scope)) return;

              found_scopes.add(scope);

              bubble_up(scope.parent_scope);
          })(scope);
      }

      return [...found_scopes];
  }

  // Creates a symbol during compression
  AST_Scope.DEFMETHOD("create_symbol", function(SymClass, {
      source,
      tentative_name,
      scope,
      conflict_scopes = [scope],
      init = null
  } = {}) {
      let symbol_name;

      conflict_scopes = find_scopes_visible_from(conflict_scopes);

      if (tentative_name) {
          // Implement hygiene (no new names are conflicting with existing names)
          tentative_name =
              symbol_name =
              tentative_name.replace(/(?:^[^a-z_$]|[^a-z0-9_$])/ig, "_");

          let i = 0;
          while (conflict_scopes.find(s => s.conflicting_def_shallow(symbol_name))) {
              symbol_name = tentative_name + "$" + i++;
          }
      }

      if (!symbol_name) {
          throw new Error("No symbol name could be generated in create_symbol()");
      }

      const symbol = make_node(SymClass, source, {
          name: symbol_name,
          scope
      });

      this.def_variable(symbol, init || null);

      symbol.mark_enclosed();

      return symbol;
  });


  AST_Node.DEFMETHOD("is_block_scope", return_false);
  AST_Class.DEFMETHOD("is_block_scope", return_false);
  AST_Lambda.DEFMETHOD("is_block_scope", return_false);
  AST_Toplevel.DEFMETHOD("is_block_scope", return_false);
  AST_SwitchBranch.DEFMETHOD("is_block_scope", return_false);
  AST_Block.DEFMETHOD("is_block_scope", return_true);
  AST_Scope.DEFMETHOD("is_block_scope", function () {
      return this._block_scope || false;
  });
  AST_IterationStatement.DEFMETHOD("is_block_scope", return_true);

  AST_Lambda.DEFMETHOD("init_scope_vars", function() {
      AST_Scope.prototype.init_scope_vars.apply(this, arguments);
      this.uses_arguments = false;
      this.def_variable(new AST_SymbolFunarg({
          name: "arguments",
          start: this.start,
          end: this.end
      }));
  });

  AST_Arrow.DEFMETHOD("init_scope_vars", function() {
      AST_Scope.prototype.init_scope_vars.apply(this, arguments);
      this.uses_arguments = false;
  });

  AST_Symbol.DEFMETHOD("mark_enclosed", function() {
      var def = this.definition();
      var s = this.scope;
      while (s) {
          push_uniq(s.enclosed, def);
          if (s === def.scope) break;
          s = s.parent_scope;
      }
  });

  AST_Symbol.DEFMETHOD("reference", function() {
      this.definition().references.push(this);
      this.mark_enclosed();
  });

  AST_Scope.DEFMETHOD("find_variable", function(name) {
      if (name instanceof AST_Symbol) name = name.name;
      return this.variables.get(name)
          || (this.parent_scope && this.parent_scope.find_variable(name));
  });

  AST_Scope.DEFMETHOD("def_function", function(symbol, init) {
      var def = this.def_variable(symbol, init);
      if (!def.init || def.init instanceof AST_Defun) def.init = init;
      return def;
  });

  AST_Scope.DEFMETHOD("def_variable", function(symbol, init) {
      var def = this.variables.get(symbol.name);
      if (def) {
          def.orig.push(symbol);
          if (def.init && (def.scope !== symbol.scope || def.init instanceof AST_Function)) {
              def.init = init;
          }
      } else {
          def = new SymbolDef(this, symbol, init);
          this.variables.set(symbol.name, def);
          def.global = !this.parent_scope;
      }
      return symbol.thedef = def;
  });

  function next_mangled(scope, options) {
      let defun_scope;
      if (
          scopes_with_block_defuns
          && (defun_scope = scope.get_defun_scope())
          && scopes_with_block_defuns.has(defun_scope)
      ) {
          scope = defun_scope;
      }

      var ext = scope.enclosed;
      var nth_identifier = options.nth_identifier;
      out: while (true) {
          var m = nth_identifier.get(++scope.cname);
          if (ALL_RESERVED_WORDS.has(m)) continue; // skip over "do"

          // https://github.com/mishoo/UglifyJS2/issues/242 -- do not
          // shadow a name reserved from mangling.
          if (options.reserved.has(m)) continue;

          // Functions with short names might collide with base54 output
          // and therefore cause collisions when keep_fnames is true.
          if (unmangleable_names && unmangleable_names.has(m)) continue out;

          // we must ensure that the mangled name does not shadow a name
          // from some parent scope that is referenced in this or in
          // inner scopes.
          for (let i = ext.length; --i >= 0;) {
              const def = ext[i];
              const name = def.mangled_name || (def.unmangleable(options) && def.name);
              if (m == name) continue out;
          }
          return m;
      }
  }

  AST_Scope.DEFMETHOD("next_mangled", function(options) {
      return next_mangled(this, options);
  });

  AST_Toplevel.DEFMETHOD("next_mangled", function(options) {
      let name;
      const mangled_names = this.mangled_names;
      do {
          name = next_mangled(this, options);
      } while (mangled_names.has(name));
      return name;
  });

  AST_Function.DEFMETHOD("next_mangled", function(options, def) {
      // #179, #326
      // in Safari strict mode, something like (function x(x){...}) is a syntax error;
      // a function expression's argument cannot shadow the function expression's name

      var tricky_def = def.orig[0] instanceof AST_SymbolFunarg && this.name && this.name.definition();

      // the function's mangled_name is null when keep_fnames is true
      var tricky_name = tricky_def ? tricky_def.mangled_name || tricky_def.name : null;

      while (true) {
          var name = next_mangled(this, options);
          if (!tricky_name || tricky_name != name)
              return name;
      }
  });

  AST_Symbol.DEFMETHOD("unmangleable", function(options) {
      var def = this.definition();
      return !def || def.unmangleable(options);
  });

  // labels are always mangleable
  AST_Label.DEFMETHOD("unmangleable", return_false);

  AST_Symbol.DEFMETHOD("unreferenced", function() {
      return !this.definition().references.length && !this.scope.pinned();
  });

  AST_Symbol.DEFMETHOD("definition", function() {
      return this.thedef;
  });

  AST_Symbol.DEFMETHOD("global", function() {
      return this.thedef.global;
  });

  AST_Toplevel.DEFMETHOD("_default_mangler_options", function(options) {
      options = defaults(options, {
          eval        : false,
          nth_identifier : base54,
          ie8         : false,
          keep_classnames: false,
          keep_fnames : false,
          module      : false,
          reserved    : [],
          toplevel    : false,
      });
      if (options.module) options.toplevel = true;
      if (!Array.isArray(options.reserved)
          && !(options.reserved instanceof Set)
      ) {
          options.reserved = [];
      }
      options.reserved = new Set(options.reserved);
      // Never mangle arguments
      options.reserved.add("arguments");
      return options;
  });

  AST_Toplevel.DEFMETHOD("mangle_names", function(options) {
      options = this._default_mangler_options(options);
      var nth_identifier = options.nth_identifier;

      // We only need to mangle declaration nodes.  Special logic wired
      // into the code generator will display the mangled name if it's
      // present (and for AST_SymbolRef-s it'll use the mangled name of
      // the AST_SymbolDeclaration that it points to).
      var lname = -1;
      var to_mangle = [];

      if (options.keep_fnames) {
          function_defs = new Set();
      }

      const mangled_names = this.mangled_names = new Set();
      unmangleable_names = new Set();

      if (options.cache) {
          this.globals.forEach(collect);
          if (options.cache.props) {
              options.cache.props.forEach(function(mangled_name) {
                  mangled_names.add(mangled_name);
              });
          }
      }

      var tw = new TreeWalker(function(node, descend) {
          if (node instanceof AST_LabeledStatement) {
              // lname is incremented when we get to the AST_Label
              var save_nesting = lname;
              descend();
              lname = save_nesting;
              return true;        // don't descend again in TreeWalker
          }
          if (
              node instanceof AST_Defun
              && !(tw.parent() instanceof AST_Scope)
          ) {
              scopes_with_block_defuns = scopes_with_block_defuns || new Set();
              scopes_with_block_defuns.add(node.parent_scope.get_defun_scope());
          }
          if (node instanceof AST_Scope) {
              node.variables.forEach(collect);
              return;
          }
          if (node.is_block_scope()) {
              node.block_scope.variables.forEach(collect);
              return;
          }
          if (
              function_defs
              && node instanceof AST_VarDef
              && node.value instanceof AST_Lambda
              && !node.value.name
              && keep_name(options.keep_fnames, node.name.name)
          ) {
              function_defs.add(node.name.definition().id);
              return;
          }
          if (node instanceof AST_Label) {
              let name;
              do {
                  name = nth_identifier.get(++lname);
              } while (ALL_RESERVED_WORDS.has(name));
              node.mangled_name = name;
              return true;
          }
          if (!(options.ie8 || options.safari10) && node instanceof AST_SymbolCatch) {
              to_mangle.push(node.definition());
              return;
          }
      });

      this.walk(tw);

      if (options.keep_fnames || options.keep_classnames) {
          // Collect a set of short names which are unmangleable,
          // for use in avoiding collisions in next_mangled.
          to_mangle.forEach(def => {
              if (def.name.length < 6 && def.unmangleable(options)) {
                  unmangleable_names.add(def.name);
              }
          });
      }

      to_mangle.forEach(def => { def.mangle(options); });

      function_defs = null;
      unmangleable_names = null;
      scopes_with_block_defuns = null;

      function collect(symbol) {
          if (symbol.export & MASK_EXPORT_DONT_MANGLE) {
              unmangleable_names.add(symbol.name);
          } else if (!options.reserved.has(symbol.name)) {
              to_mangle.push(symbol);
          }
      }
  });

  AST_Toplevel.DEFMETHOD("find_colliding_names", function(options) {
      const cache = options.cache && options.cache.props;
      const avoid = new Set();
      options.reserved.forEach(to_avoid);
      this.globals.forEach(add_def);
      this.walk(new TreeWalker(function(node) {
          if (node instanceof AST_Scope) node.variables.forEach(add_def);
          if (node instanceof AST_SymbolCatch) add_def(node.definition());
      }));
      return avoid;

      function to_avoid(name) {
          avoid.add(name);
      }

      function add_def(def) {
          var name = def.name;
          if (def.global && cache && cache.has(name)) name = cache.get(name);
          else if (!def.unmangleable(options)) return;
          to_avoid(name);
      }
  });

  AST_Toplevel.DEFMETHOD("expand_names", function(options) {
      options = this._default_mangler_options(options);
      var nth_identifier = options.nth_identifier;
      if (nth_identifier.reset && nth_identifier.sort) {
          nth_identifier.reset();
          nth_identifier.sort();
      }
      var avoid = this.find_colliding_names(options);
      var cname = 0;
      this.globals.forEach(rename);
      this.walk(new TreeWalker(function(node) {
          if (node instanceof AST_Scope) node.variables.forEach(rename);
          if (node instanceof AST_SymbolCatch) rename(node.definition());
      }));

      function next_name() {
          var name;
          do {
              name = nth_identifier.get(cname++);
          } while (avoid.has(name) || ALL_RESERVED_WORDS.has(name));
          return name;
      }

      function rename(def) {
          if (def.global && options.cache) return;
          if (def.unmangleable(options)) return;
          if (options.reserved.has(def.name)) return;
          const redefinition = redefined_catch_def(def);
          const name = def.name = redefinition ? redefinition.name : next_name();
          def.orig.forEach(function(sym) {
              sym.name = name;
          });
          def.references.forEach(function(sym) {
              sym.name = name;
          });
      }
  });

  AST_Node.DEFMETHOD("tail_node", return_this);
  AST_Sequence.DEFMETHOD("tail_node", function() {
      return this.expressions[this.expressions.length - 1];
  });

  AST_Toplevel.DEFMETHOD("compute_char_frequency", function(options) {
      options = this._default_mangler_options(options);
      var nth_identifier = options.nth_identifier;
      if (!nth_identifier.reset || !nth_identifier.consider || !nth_identifier.sort) {
          // If the identifier mangler is invariant, skip computing character frequency.
          return;
      }
      nth_identifier.reset();

      try {
          AST_Node.prototype.print = function(stream, force_parens) {
              this._print(stream, force_parens);
              if (this instanceof AST_Symbol && !this.unmangleable(options)) {
                  nth_identifier.consider(this.name, -1);
              } else if (options.properties) {
                  if (this instanceof AST_DotHash) {
                      nth_identifier.consider("#" + this.property, -1);
                  } else if (this instanceof AST_Dot) {
                      nth_identifier.consider(this.property, -1);
                  } else if (this instanceof AST_Sub) {
                      skip_string(this.property);
                  }
              }
          };
          nth_identifier.consider(this.print_to_string(), 1);
      } finally {
          AST_Node.prototype.print = AST_Node.prototype._print;
      }
      nth_identifier.sort();

      function skip_string(node) {
          if (node instanceof AST_String) {
              nth_identifier.consider(node.value, -1);
          } else if (node instanceof AST_Conditional) {
              skip_string(node.consequent);
              skip_string(node.alternative);
          } else if (node instanceof AST_Sequence) {
              skip_string(node.tail_node());
          }
      }
  });

  const base54 = (() => {
      const leading = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ$_".split("");
      const digits = "0123456789".split("");
      let chars;
      let frequency;
      function reset() {
          frequency = new Map();
          leading.forEach(function(ch) {
              frequency.set(ch, 0);
          });
          digits.forEach(function(ch) {
              frequency.set(ch, 0);
          });
      }
      function consider(str, delta) {
          for (var i = str.length; --i >= 0;) {
              frequency.set(str[i], frequency.get(str[i]) + delta);
          }
      }
      function compare(a, b) {
          return frequency.get(b) - frequency.get(a);
      }
      function sort() {
          chars = mergeSort(leading, compare).concat(mergeSort(digits, compare));
      }
      // Ensure this is in a usable initial state.
      reset();
      sort();
      function base54(num) {
          var ret = "", base = 54;
          num++;
          do {
              num--;
              ret += chars[num % base];
              num = Math.floor(num / base);
              base = 64;
          } while (num > 0);
          return ret;
      }

      return {
          get: base54,
          consider,
          reset,
          sort
      };
  })();

  let mangle_options = undefined;
  AST_Node.prototype.size = function (compressor, stack) {
      mangle_options = compressor && compressor.mangle_options;

      let size = 0;
      walk_parent(this, (node, info) => {
          size += node._size(info);

          // Braceless arrow functions have fake "return" statements
          if (node instanceof AST_Arrow && node.is_braceless()) {
              size += node.body[0].value._size(info);
              return true;
          }
      }, stack || (compressor && compressor.stack));

      // just to save a bit of memory
      mangle_options = undefined;

      return size;
  };

  AST_Node.prototype._size = () => 0;

  AST_Debugger.prototype._size = () => 8;

  AST_Directive.prototype._size = function () {
      // TODO string encoding stuff
      return 2 + this.value.length;
  };

  /** Count commas/semicolons necessary to show a list of expressions/statements */
  const list_overhead = (array) => array.length && array.length - 1;

  AST_Block.prototype._size = function () {
      return 2 + list_overhead(this.body);
  };

  AST_Toplevel.prototype._size = function() {
      return list_overhead(this.body);
  };

  AST_EmptyStatement.prototype._size = () => 1;

  AST_LabeledStatement.prototype._size = () => 2;  // x:

  AST_Do.prototype._size = () => 9;

  AST_While.prototype._size = () => 7;

  AST_For.prototype._size = () => 8;

  AST_ForIn.prototype._size = () => 8;
  // AST_ForOf inherits ^

  AST_With.prototype._size = () => 6;

  AST_Expansion.prototype._size = () => 3;

  const lambda_modifiers = func =>
      (func.is_generator ? 1 : 0) + (func.async ? 6 : 0);

  AST_Accessor.prototype._size = function () {
      return lambda_modifiers(this) + 4 + list_overhead(this.argnames) + list_overhead(this.body);
  };

  AST_Function.prototype._size = function (info) {
      const first = !!first_in_statement(info);
      return (first * 2) + lambda_modifiers(this) + 12 + list_overhead(this.argnames) + list_overhead(this.body);
  };

  AST_Defun.prototype._size = function () {
      return lambda_modifiers(this) + 13 + list_overhead(this.argnames) + list_overhead(this.body);
  };

  AST_Arrow.prototype._size = function () {
      let args_and_arrow = 2 + list_overhead(this.argnames);

      if (
          !(
              this.argnames.length === 1
              && this.argnames[0] instanceof AST_Symbol
          )
      ) {
          args_and_arrow += 2; // parens around the args
      }

      const body_overhead = this.is_braceless() ? 0 : list_overhead(this.body) + 2;

      return lambda_modifiers(this) + args_and_arrow + body_overhead;
  };

  AST_Destructuring.prototype._size = () => 2;

  AST_TemplateString.prototype._size = function () {
      return 2 + (Math.floor(this.segments.length / 2) * 3);  /* "${}" */
  };

  AST_TemplateSegment.prototype._size = function () {
      return this.value.length;
  };

  AST_Return.prototype._size = function () {
      return this.value ? 7 : 6;
  };

  AST_Throw.prototype._size = () => 6;

  AST_Break.prototype._size = function () {
      return this.label ? 6 : 5;
  };

  AST_Continue.prototype._size = function () {
      return this.label ? 9 : 8;
  };

  AST_If.prototype._size = () => 4;

  AST_Switch.prototype._size = function () {
      return 8 + list_overhead(this.body);
  };

  AST_Case.prototype._size = function () {
      return 5 + list_overhead(this.body);
  };

  AST_Default.prototype._size = function () {
      return 8 + list_overhead(this.body);
  };

  AST_Try.prototype._size = function () {
      return 3 + list_overhead(this.body);
  };

  AST_Catch.prototype._size = function () {
      let size = 7 + list_overhead(this.body);
      if (this.argname) {
          size += 2;
      }
      return size;
  };

  AST_Finally.prototype._size = function () {
      return 7 + list_overhead(this.body);
  };

  AST_Var.prototype._size = function () {
      return 4 + list_overhead(this.definitions);
  };

  AST_Let.prototype._size = function () {
      return 4 + list_overhead(this.definitions);
  };

  AST_Const.prototype._size = function () {
      return 6 + list_overhead(this.definitions);
  };

  AST_VarDef.prototype._size = function () {
      return this.value ? 1 : 0;
  };

  AST_NameMapping.prototype._size = function () {
      // foreign name isn't mangled
      return this.name ? 4 : 0;
  };

  AST_Import.prototype._size = function () {
      // import
      let size = 6;

      if (this.imported_name) size += 1;

      // from
      if (this.imported_name || this.imported_names) size += 5;

      // braces, and the commas
      if (this.imported_names) {
          size += 2 + list_overhead(this.imported_names);
      }

      return size;
  };

  AST_ImportMeta.prototype._size = () => 11;

  AST_Export.prototype._size = function () {
      let size = 7 + (this.is_default ? 8 : 0);

      if (this.exported_value) {
          size += this.exported_value._size();
      }

      if (this.exported_names) {
          // Braces and commas
          size += 2 + list_overhead(this.exported_names);
      }

      if (this.module_name) {
          // "from "
          size += 5;
      }

      return size;
  };

  AST_Call.prototype._size = function () {
      if (this.optional) {
          return 4 + list_overhead(this.args);
      }
      return 2 + list_overhead(this.args);
  };

  AST_New.prototype._size = function () {
      return 6 + list_overhead(this.args);
  };

  AST_Sequence.prototype._size = function () {
      return list_overhead(this.expressions);
  };

  AST_Dot.prototype._size = function () {
      if (this.optional) {
          return this.property.length + 2;
      }
      return this.property.length + 1;
  };

  AST_DotHash.prototype._size = function () {
      if (this.optional) {
          return this.property.length + 3;
      }
      return this.property.length + 2;
  };

  AST_Sub.prototype._size = function () {
      return this.optional ? 4 : 2;
  };

  AST_Unary.prototype._size = function () {
      if (this.operator === "typeof") return 7;
      if (this.operator === "void") return 5;
      return this.operator.length;
  };

  AST_Binary.prototype._size = function (info) {
      if (this.operator === "in") return 4;

      let size = this.operator.length;

      if (
          (this.operator === "+" || this.operator === "-")
          && this.right instanceof AST_Unary && this.right.operator === this.operator
      ) {
          // 1+ +a > needs space between the +
          size += 1;
      }

      if (this.needs_parens(info)) {
          size += 2;
      }

      return size;
  };

  AST_Conditional.prototype._size = () => 3;

  AST_Array.prototype._size = function () {
      return 2 + list_overhead(this.elements);
  };

  AST_Object.prototype._size = function (info) {
      let base = 2;
      if (first_in_statement(info)) {
          base += 2; // parens
      }
      return base + list_overhead(this.properties);
  };

  /*#__INLINE__*/
  const key_size = key =>
      typeof key === "string" ? key.length : 0;

  AST_ObjectKeyVal.prototype._size = function () {
      return key_size(this.key) + 1;
  };

  /*#__INLINE__*/
  const static_size = is_static => is_static ? 7 : 0;

  AST_ObjectGetter.prototype._size = function () {
      return 5 + static_size(this.static) + key_size(this.key);
  };

  AST_ObjectSetter.prototype._size = function () {
      return 5 + static_size(this.static) + key_size(this.key);
  };

  AST_ConciseMethod.prototype._size = function () {
      return static_size(this.static) + key_size(this.key) + lambda_modifiers(this);
  };

  AST_PrivateMethod.prototype._size = function () {
      return AST_ConciseMethod.prototype._size.call(this) + 1;
  };

  AST_PrivateGetter.prototype._size = AST_PrivateSetter.prototype._size = function () {
      return AST_ConciseMethod.prototype._size.call(this) + 4;
  };

  AST_Class.prototype._size = function () {
      return (
          (this.name ? 8 : 7)
          + (this.extends ? 8 : 0)
      );
  };

  AST_ClassProperty.prototype._size = function () {
      return (
          static_size(this.static)
          + (typeof this.key === "string" ? this.key.length + 2 : 0)
          + (this.value ? 1 : 0)
      );
  };

  AST_ClassPrivateProperty.prototype._size = function () {
      return AST_ClassProperty.prototype._size.call(this) + 1;
  };

  AST_Symbol.prototype._size = function () {
      return !mangle_options || this.definition().unmangleable(mangle_options)
          ? this.name.length
          : 1;
  };

  // TODO take propmangle into account
  AST_SymbolClassProperty.prototype._size = function () {
      return this.name.length;
  };

  AST_SymbolRef.prototype._size = AST_SymbolDeclaration.prototype._size = function () {
      const { name, thedef } = this;

      if (thedef && thedef.global) return name.length;

      if (name === "arguments") return 9;

      return AST_Symbol.prototype._size.call(this);
  };

  AST_NewTarget.prototype._size = () => 10;

  AST_SymbolImportForeign.prototype._size = function () {
      return this.name.length;
  };

  AST_SymbolExportForeign.prototype._size = function () {
      return this.name.length;
  };

  AST_This.prototype._size = () => 4;

  AST_Super.prototype._size = () => 5;

  AST_String.prototype._size = function () {
      return this.value.length + 2;
  };

  AST_Number.prototype._size = function () {
      const { value } = this;
      if (value === 0) return 1;
      if (value > 0 && Math.floor(value) === value) {
          return Math.floor(Math.log10(value) + 1);
      }
      return value.toString().length;
  };

  AST_BigInt.prototype._size = function () {
      return this.value.length;
  };

  AST_RegExp.prototype._size = function () {
      return this.value.toString().length;
  };

  AST_Null.prototype._size = () => 4;

  AST_NaN.prototype._size = () => 3;

  AST_Undefined.prototype._size = () => 6; // "void 0"

  AST_Hole.prototype._size = () => 0;  // comma is taken into account by list_overhead()

  AST_Infinity.prototype._size = () => 8;

  AST_True.prototype._size = () => 4;

  AST_False.prototype._size = () => 5;

  AST_Await.prototype._size = () => 6;

  AST_Yield.prototype._size = () => 6;

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  // bitfield flags to be stored in node.flags.
  // These are set and unset during compression, and store information in the node without requiring multiple fields.
  const UNUSED = 0b00000001;
  const TRUTHY = 0b00000010;
  const FALSY = 0b00000100;
  const UNDEFINED = 0b00001000;
  const INLINED = 0b00010000;

  // Nodes to which values are ever written. Used when keep_assign is part of the unused option string.
  const WRITE_ONLY = 0b00100000;

  // information specific to a single compression pass
  const SQUEEZED = 0b0000000100000000;
  const OPTIMIZED = 0b0000001000000000;
  const TOP = 0b0000010000000000;
  const CLEAR_BETWEEN_PASSES = SQUEEZED | OPTIMIZED | TOP;

  const has_flag = (node, flag) => node.flags & flag;
  const set_flag = (node, flag) => { node.flags |= flag; };
  const clear_flag = (node, flag) => { node.flags &= ~flag; };

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  function merge_sequence(array, node) {
      if (node instanceof AST_Sequence) {
          array.push(...node.expressions);
      } else {
          array.push(node);
      }
      return array;
  }

  function make_sequence(orig, expressions) {
      if (expressions.length == 1) return expressions[0];
      if (expressions.length == 0) throw new Error("trying to create a sequence with length zero!");
      return make_node(AST_Sequence, orig, {
          expressions: expressions.reduce(merge_sequence, [])
      });
  }

  function make_node_from_constant(val, orig) {
      switch (typeof val) {
        case "string":
          return make_node(AST_String, orig, {
              value: val
          });
        case "number":
          if (isNaN(val)) return make_node(AST_NaN, orig);
          if (isFinite(val)) {
              return 1 / val < 0 ? make_node(AST_UnaryPrefix, orig, {
                  operator: "-",
                  expression: make_node(AST_Number, orig, { value: -val })
              }) : make_node(AST_Number, orig, { value: val });
          }
          return val < 0 ? make_node(AST_UnaryPrefix, orig, {
              operator: "-",
              expression: make_node(AST_Infinity, orig)
          }) : make_node(AST_Infinity, orig);
        case "boolean":
          return make_node(val ? AST_True : AST_False, orig);
        case "undefined":
          return make_node(AST_Undefined, orig);
        default:
          if (val === null) {
              return make_node(AST_Null, orig, { value: null });
          }
          if (val instanceof RegExp) {
              return make_node(AST_RegExp, orig, {
                  value: {
                      source: regexp_source_fix(val.source),
                      flags: val.flags
                  }
              });
          }
          throw new Error(string_template("Can't handle constant of type: {type}", {
              type: typeof val
          }));
      }
  }

  function best_of_expression(ast1, ast2) {
      return ast1.size() > ast2.size() ? ast2 : ast1;
  }

  function best_of_statement(ast1, ast2) {
      return best_of_expression(
          make_node(AST_SimpleStatement, ast1, {
              body: ast1
          }),
          make_node(AST_SimpleStatement, ast2, {
              body: ast2
          })
      ).body;
  }

  /** Find which node is smaller, and return that */
  function best_of(compressor, ast1, ast2) {
      if (first_in_statement(compressor)) {
          return best_of_statement(ast1, ast2);
      } else {
          return best_of_expression(ast1, ast2);
      }
  }

  /** Simplify an object property's key, if possible */
  function get_simple_key(key) {
      if (key instanceof AST_Constant) {
          return key.getValue();
      }
      if (key instanceof AST_UnaryPrefix
          && key.operator == "void"
          && key.expression instanceof AST_Constant) {
          return;
      }
      return key;
  }

  function read_property(obj, key) {
      key = get_simple_key(key);
      if (key instanceof AST_Node) return;

      var value;
      if (obj instanceof AST_Array) {
          var elements = obj.elements;
          if (key == "length") return make_node_from_constant(elements.length, obj);
          if (typeof key == "number" && key in elements) value = elements[key];
      } else if (obj instanceof AST_Object) {
          key = "" + key;
          var props = obj.properties;
          for (var i = props.length; --i >= 0;) {
              var prop = props[i];
              if (!(prop instanceof AST_ObjectKeyVal)) return;
              if (!value && props[i].key === key) value = props[i].value;
          }
      }

      return value instanceof AST_SymbolRef && value.fixed_value() || value;
  }

  function has_break_or_continue(loop, parent) {
      var found = false;
      var tw = new TreeWalker(function(node) {
          if (found || node instanceof AST_Scope) return true;
          if (node instanceof AST_LoopControl && tw.loopcontrol_target(node) === loop) {
              return found = true;
          }
      });
      if (parent instanceof AST_LabeledStatement) tw.push(parent);
      tw.push(loop);
      loop.body.walk(tw);
      return found;
  }

  // we shouldn't compress (1,func)(something) to
  // func(something) because that changes the meaning of
  // the func (becomes lexical instead of global).
  function maintain_this_binding(parent, orig, val) {
      if (
          parent instanceof AST_UnaryPrefix && parent.operator == "delete"
          || parent instanceof AST_Call && parent.expression === orig
              && (
                  val instanceof AST_PropAccess
                  || val instanceof AST_SymbolRef && val.name == "eval"
              )
      ) {
          const zero = make_node(AST_Number, orig, { value: 0 });
          return make_sequence(orig, [ zero, val ]);
      } else {
          return val;
      }
  }

  function is_func_expr(node) {
      return node instanceof AST_Arrow || node instanceof AST_Function;
  }

  function is_iife_call(node) {
      // Used to determine whether the node can benefit from negation.
      // Not the case with arrow functions (you need an extra set of parens).
      if (node.TYPE != "Call") return false;
      return node.expression instanceof AST_Function || is_iife_call(node.expression);
  }

  function is_empty(thing) {
      if (thing === null) return true;
      if (thing instanceof AST_EmptyStatement) return true;
      if (thing instanceof AST_BlockStatement) return thing.body.length == 0;
      return false;
  }

  const identifier_atom = makePredicate("Infinity NaN undefined");
  function is_identifier_atom(node) {
      return node instanceof AST_Infinity
          || node instanceof AST_NaN
          || node instanceof AST_Undefined;
  }

  /** Check if this is a SymbolRef node which has one def of a certain AST type */
  function is_ref_of(ref, type) {
      if (!(ref instanceof AST_SymbolRef)) return false;
      var orig = ref.definition().orig;
      for (var i = orig.length; --i >= 0;) {
          if (orig[i] instanceof type) return true;
      }
  }

  // Can we turn { block contents... } into just the block contents ?
  // Not if one of these is inside.
  function can_be_evicted_from_block(node) {
      return !(
          node instanceof AST_DefClass ||
          node instanceof AST_Defun ||
          node instanceof AST_Let ||
          node instanceof AST_Const ||
          node instanceof AST_Export ||
          node instanceof AST_Import
      );
  }

  function as_statement_array(thing) {
      if (thing === null) return [];
      if (thing instanceof AST_BlockStatement) return thing.body;
      if (thing instanceof AST_EmptyStatement) return [];
      if (thing instanceof AST_Statement) return [ thing ];
      throw new Error("Can't convert thing to statement array");
  }

  function is_reachable(scope_node, defs) {
      const find_ref = node => {
          if (node instanceof AST_SymbolRef && defs.includes(node.definition())) {
              return walk_abort;
          }
      };

      return walk_parent(scope_node, (node, info) => {
          if (node instanceof AST_Scope && node !== scope_node) {
              var parent = info.parent();

              if (
                  parent instanceof AST_Call
                  && parent.expression === node
                  // Async/Generators aren't guaranteed to sync evaluate all of
                  // their body steps, so it's possible they close over the variable.
                  && !(node.async || node.is_generator)
              ) {
                  return;
              }

              if (walk(node, find_ref)) return walk_abort;

              return true;
          }
      });
  }

  /** Check if a ref refers to the name of a function/class it's defined within */
  function is_recursive_ref(compressor, def) {
      var node;
      for (var i = 0; node = compressor.parent(i); i++) {
          if (node instanceof AST_Lambda || node instanceof AST_Class) {
              var name = node.name;
              if (name && name.definition() === def) {
                  return true;
              }
          }
      }
      return false;
  }

  // TODO this only works with AST_Defun, shouldn't it work for other ways of defining functions?
  function retain_top_func(fn, compressor) {
      return compressor.top_retain
          && fn instanceof AST_Defun
          && has_flag(fn, TOP)
          && fn.name
          && compressor.top_retain(fn.name);
  }

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  // Lists of native methods, useful for `unsafe` option which assumes they exist.
  // Note: Lots of methods and functions are missing here, in case they aren't pure
  // or not available in all JS environments.

  function make_nested_lookup(obj) {
      const out = new Map();
      for (var key of Object.keys(obj)) {
          out.set(key, makePredicate(obj[key]));
      }

      const does_have = (global_name, fname) => {
          const inner_map = out.get(global_name);
          return inner_map != null && inner_map.has(fname);
      };
      return does_have;
  }

  // Objects which are safe to access without throwing or causing a side effect.
  // Usually we'd check the `unsafe` option first but these are way too common for that
  const pure_prop_access_globals = new Set([
      "Number",
      "String",
      "Array",
      "Object",
      "Function",
      "Promise",
  ]);

  const object_methods = [
      "constructor",
      "toString",
      "valueOf",
  ];

  const is_pure_native_method = make_nested_lookup({
      Array: [
          "indexOf",
          "join",
          "lastIndexOf",
          "slice",
          ...object_methods,
      ],
      Boolean: object_methods,
      Function: object_methods,
      Number: [
          "toExponential",
          "toFixed",
          "toPrecision",
          ...object_methods,
      ],
      Object: object_methods,
      RegExp: [
          "test",
          ...object_methods,
      ],
      String: [
          "charAt",
          "charCodeAt",
          "concat",
          "indexOf",
          "italics",
          "lastIndexOf",
          "match",
          "replace",
          "search",
          "slice",
          "split",
          "substr",
          "substring",
          "toLowerCase",
          "toUpperCase",
          "trim",
          ...object_methods,
      ],
  });

  const is_pure_native_fn = make_nested_lookup({
      Array: [
          "isArray",
      ],
      Math: [
          "abs",
          "acos",
          "asin",
          "atan",
          "ceil",
          "cos",
          "exp",
          "floor",
          "log",
          "round",
          "sin",
          "sqrt",
          "tan",
          "atan2",
          "pow",
          "max",
          "min",
      ],
      Number: [
          "isFinite",
          "isNaN",
      ],
      Object: [
          "create",
          "getOwnPropertyDescriptor",
          "getOwnPropertyNames",
          "getPrototypeOf",
          "isExtensible",
          "isFrozen",
          "isSealed",
          "hasOwn",
          "keys",
      ],
      String: [
          "fromCharCode",
      ],
  });

  // Known numeric values which come with JS environments
  const is_pure_native_value = make_nested_lookup({
      Math: [
          "E",
          "LN10",
          "LN2",
          "LOG2E",
          "LOG10E",
          "PI",
          "SQRT1_2",
          "SQRT2",
      ],
      Number: [
          "MAX_VALUE",
          "MIN_VALUE",
          "NaN",
          "NEGATIVE_INFINITY",
          "POSITIVE_INFINITY",
      ],
  });

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  // Functions and methods to infer certain facts about expressions
  // It's not always possible to be 100% sure about something just by static analysis,
  // so `true` means yes, and `false` means maybe

  const is_undeclared_ref = (node) =>
      node instanceof AST_SymbolRef && node.definition().undeclared;

  const lazy_op = makePredicate("&& || ??");
  const unary_side_effects = makePredicate("delete ++ --");

  // methods to determine whether an expression has a boolean result type
  (function(def_is_boolean) {
      const unary_bool = makePredicate("! delete");
      const binary_bool = makePredicate("in instanceof == != === !== < <= >= >");
      def_is_boolean(AST_Node, return_false);
      def_is_boolean(AST_UnaryPrefix, function() {
          return unary_bool.has(this.operator);
      });
      def_is_boolean(AST_Binary, function() {
          return binary_bool.has(this.operator)
              || lazy_op.has(this.operator)
                  && this.left.is_boolean()
                  && this.right.is_boolean();
      });
      def_is_boolean(AST_Conditional, function() {
          return this.consequent.is_boolean() && this.alternative.is_boolean();
      });
      def_is_boolean(AST_Assign, function() {
          return this.operator == "=" && this.right.is_boolean();
      });
      def_is_boolean(AST_Sequence, function() {
          return this.tail_node().is_boolean();
      });
      def_is_boolean(AST_True, return_true);
      def_is_boolean(AST_False, return_true);
  })(function(node, func) {
      node.DEFMETHOD("is_boolean", func);
  });

  // methods to determine if an expression has a numeric result type
  (function(def_is_number) {
      def_is_number(AST_Node, return_false);
      def_is_number(AST_Number, return_true);
      const unary = makePredicate("+ - ~ ++ --");
      def_is_number(AST_Unary, function() {
          return unary.has(this.operator);
      });
      const numeric_ops = makePredicate("- * / % & | ^ << >> >>>");
      def_is_number(AST_Binary, function(compressor) {
          return numeric_ops.has(this.operator) || this.operator == "+"
              && this.left.is_number(compressor)
              && this.right.is_number(compressor);
      });
      def_is_number(AST_Assign, function(compressor) {
          return numeric_ops.has(this.operator.slice(0, -1))
              || this.operator == "=" && this.right.is_number(compressor);
      });
      def_is_number(AST_Sequence, function(compressor) {
          return this.tail_node().is_number(compressor);
      });
      def_is_number(AST_Conditional, function(compressor) {
          return this.consequent.is_number(compressor) && this.alternative.is_number(compressor);
      });
  })(function(node, func) {
      node.DEFMETHOD("is_number", func);
  });

  // methods to determine if an expression has a string result type
  (function(def_is_string) {
      def_is_string(AST_Node, return_false);
      def_is_string(AST_String, return_true);
      def_is_string(AST_TemplateString, return_true);
      def_is_string(AST_UnaryPrefix, function() {
          return this.operator == "typeof";
      });
      def_is_string(AST_Binary, function(compressor) {
          return this.operator == "+" &&
              (this.left.is_string(compressor) || this.right.is_string(compressor));
      });
      def_is_string(AST_Assign, function(compressor) {
          return (this.operator == "=" || this.operator == "+=") && this.right.is_string(compressor);
      });
      def_is_string(AST_Sequence, function(compressor) {
          return this.tail_node().is_string(compressor);
      });
      def_is_string(AST_Conditional, function(compressor) {
          return this.consequent.is_string(compressor) && this.alternative.is_string(compressor);
      });
  })(function(node, func) {
      node.DEFMETHOD("is_string", func);
  });

  function is_undefined(node, compressor) {
      return (
          has_flag(node, UNDEFINED)
          || node instanceof AST_Undefined
          || node instanceof AST_UnaryPrefix
              && node.operator == "void"
              && !node.expression.has_side_effects(compressor)
      );
  }

  // Is the node explicitly null or undefined.
  function is_null_or_undefined(node, compressor) {
      let fixed;
      return (
          node instanceof AST_Null
          || is_undefined(node, compressor)
          || (
              node instanceof AST_SymbolRef
              && (fixed = node.definition().fixed) instanceof AST_Node
              && is_nullish(fixed, compressor)
          )
      );
  }

  // Find out if this expression is optionally chained from a base-point that we
  // can statically analyze as null or undefined.
  function is_nullish_shortcircuited(node, compressor) {
      if (node instanceof AST_PropAccess || node instanceof AST_Call) {
          return (
              (node.optional && is_null_or_undefined(node.expression, compressor))
              || is_nullish_shortcircuited(node.expression, compressor)
          );
      }
      if (node instanceof AST_Chain) return is_nullish_shortcircuited(node.expression, compressor);
      return false;
  }

  // Find out if something is == null, or can short circuit into nullish.
  // Used to optimize ?. and ??
  function is_nullish(node, compressor) {
      if (is_null_or_undefined(node, compressor)) return true;
      return is_nullish_shortcircuited(node, compressor);
  }

  // Determine if expression might cause side effects
  // If there's a possibility that a node may change something when it's executed, this returns true
  (function(def_has_side_effects) {
      def_has_side_effects(AST_Node, return_true);

      def_has_side_effects(AST_EmptyStatement, return_false);
      def_has_side_effects(AST_Constant, return_false);
      def_has_side_effects(AST_This, return_false);

      function any(list, compressor) {
          for (var i = list.length; --i >= 0;)
              if (list[i].has_side_effects(compressor))
                  return true;
          return false;
      }

      def_has_side_effects(AST_Block, function(compressor) {
          return any(this.body, compressor);
      });
      def_has_side_effects(AST_Call, function(compressor) {
          if (
              !this.is_callee_pure(compressor)
              && (!this.expression.is_call_pure(compressor)
                  || this.expression.has_side_effects(compressor))
          ) {
              return true;
          }
          return any(this.args, compressor);
      });
      def_has_side_effects(AST_Switch, function(compressor) {
          return this.expression.has_side_effects(compressor)
              || any(this.body, compressor);
      });
      def_has_side_effects(AST_Case, function(compressor) {
          return this.expression.has_side_effects(compressor)
              || any(this.body, compressor);
      });
      def_has_side_effects(AST_Try, function(compressor) {
          return any(this.body, compressor)
              || this.bcatch && this.bcatch.has_side_effects(compressor)
              || this.bfinally && this.bfinally.has_side_effects(compressor);
      });
      def_has_side_effects(AST_If, function(compressor) {
          return this.condition.has_side_effects(compressor)
              || this.body && this.body.has_side_effects(compressor)
              || this.alternative && this.alternative.has_side_effects(compressor);
      });
      def_has_side_effects(AST_LabeledStatement, function(compressor) {
          return this.body.has_side_effects(compressor);
      });
      def_has_side_effects(AST_SimpleStatement, function(compressor) {
          return this.body.has_side_effects(compressor);
      });
      def_has_side_effects(AST_Lambda, return_false);
      def_has_side_effects(AST_Class, function (compressor) {
          if (this.extends && this.extends.has_side_effects(compressor)) {
              return true;
          }
          return any(this.properties, compressor);
      });
      def_has_side_effects(AST_Binary, function(compressor) {
          return this.left.has_side_effects(compressor)
              || this.right.has_side_effects(compressor);
      });
      def_has_side_effects(AST_Assign, return_true);
      def_has_side_effects(AST_Conditional, function(compressor) {
          return this.condition.has_side_effects(compressor)
              || this.consequent.has_side_effects(compressor)
              || this.alternative.has_side_effects(compressor);
      });
      def_has_side_effects(AST_Unary, function(compressor) {
          return unary_side_effects.has(this.operator)
              || this.expression.has_side_effects(compressor);
      });
      def_has_side_effects(AST_SymbolRef, function(compressor) {
          return !this.is_declared(compressor) && !pure_prop_access_globals.has(this.name);
      });
      def_has_side_effects(AST_SymbolClassProperty, return_false);
      def_has_side_effects(AST_SymbolDeclaration, return_false);
      def_has_side_effects(AST_Object, function(compressor) {
          return any(this.properties, compressor);
      });
      def_has_side_effects(AST_ObjectProperty, function(compressor) {
          return (
              this.computed_key() && this.key.has_side_effects(compressor)
              || this.value && this.value.has_side_effects(compressor)
          );
      });
      def_has_side_effects(AST_ClassProperty, function(compressor) {
          return (
              this.computed_key() && this.key.has_side_effects(compressor)
              || this.static && this.value && this.value.has_side_effects(compressor)
          );
      });
      def_has_side_effects(AST_ConciseMethod, function(compressor) {
          return this.computed_key() && this.key.has_side_effects(compressor);
      });
      def_has_side_effects(AST_ObjectGetter, function(compressor) {
          return this.computed_key() && this.key.has_side_effects(compressor);
      });
      def_has_side_effects(AST_ObjectSetter, function(compressor) {
          return this.computed_key() && this.key.has_side_effects(compressor);
      });
      def_has_side_effects(AST_Array, function(compressor) {
          return any(this.elements, compressor);
      });
      def_has_side_effects(AST_Dot, function(compressor) {
          if (is_nullish(this, compressor)) return false;
          return !this.optional && this.expression.may_throw_on_access(compressor)
              || this.expression.has_side_effects(compressor);
      });
      def_has_side_effects(AST_Sub, function(compressor) {
          if (is_nullish(this, compressor)) return false;

          return !this.optional && this.expression.may_throw_on_access(compressor)
              || this.expression.has_side_effects(compressor)
              || this.property.has_side_effects(compressor);
      });
      def_has_side_effects(AST_Chain, function (compressor) {
          return this.expression.has_side_effects(compressor);
      });
      def_has_side_effects(AST_Sequence, function(compressor) {
          return any(this.expressions, compressor);
      });
      def_has_side_effects(AST_Definitions, function(compressor) {
          return any(this.definitions, compressor);
      });
      def_has_side_effects(AST_VarDef, function() {
          return this.value;
      });
      def_has_side_effects(AST_TemplateSegment, return_false);
      def_has_side_effects(AST_TemplateString, function(compressor) {
          return any(this.segments, compressor);
      });
  })(function(node, func) {
      node.DEFMETHOD("has_side_effects", func);
  });

  // determine if expression may throw
  (function(def_may_throw) {
      def_may_throw(AST_Node, return_true);

      def_may_throw(AST_Constant, return_false);
      def_may_throw(AST_EmptyStatement, return_false);
      def_may_throw(AST_Lambda, return_false);
      def_may_throw(AST_SymbolDeclaration, return_false);
      def_may_throw(AST_This, return_false);

      function any(list, compressor) {
          for (var i = list.length; --i >= 0;)
              if (list[i].may_throw(compressor))
                  return true;
          return false;
      }

      def_may_throw(AST_Class, function(compressor) {
          if (this.extends && this.extends.may_throw(compressor)) return true;
          return any(this.properties, compressor);
      });

      def_may_throw(AST_Array, function(compressor) {
          return any(this.elements, compressor);
      });
      def_may_throw(AST_Assign, function(compressor) {
          if (this.right.may_throw(compressor)) return true;
          if (!compressor.has_directive("use strict")
              && this.operator == "="
              && this.left instanceof AST_SymbolRef) {
              return false;
          }
          return this.left.may_throw(compressor);
      });
      def_may_throw(AST_Binary, function(compressor) {
          return this.left.may_throw(compressor)
              || this.right.may_throw(compressor);
      });
      def_may_throw(AST_Block, function(compressor) {
          return any(this.body, compressor);
      });
      def_may_throw(AST_Call, function(compressor) {
          if (is_nullish(this, compressor)) return false;
          if (any(this.args, compressor)) return true;
          if (this.is_callee_pure(compressor)) return false;
          if (this.expression.may_throw(compressor)) return true;
          return !(this.expression instanceof AST_Lambda)
              || any(this.expression.body, compressor);
      });
      def_may_throw(AST_Case, function(compressor) {
          return this.expression.may_throw(compressor)
              || any(this.body, compressor);
      });
      def_may_throw(AST_Conditional, function(compressor) {
          return this.condition.may_throw(compressor)
              || this.consequent.may_throw(compressor)
              || this.alternative.may_throw(compressor);
      });
      def_may_throw(AST_Definitions, function(compressor) {
          return any(this.definitions, compressor);
      });
      def_may_throw(AST_If, function(compressor) {
          return this.condition.may_throw(compressor)
              || this.body && this.body.may_throw(compressor)
              || this.alternative && this.alternative.may_throw(compressor);
      });
      def_may_throw(AST_LabeledStatement, function(compressor) {
          return this.body.may_throw(compressor);
      });
      def_may_throw(AST_Object, function(compressor) {
          return any(this.properties, compressor);
      });
      def_may_throw(AST_ObjectProperty, function(compressor) {
          // TODO key may throw too
          return this.value ? this.value.may_throw(compressor) : false;
      });
      def_may_throw(AST_ClassProperty, function(compressor) {
          return (
              this.computed_key() && this.key.may_throw(compressor)
              || this.static && this.value && this.value.may_throw(compressor)
          );
      });
      def_may_throw(AST_ConciseMethod, function(compressor) {
          return this.computed_key() && this.key.may_throw(compressor);
      });
      def_may_throw(AST_ObjectGetter, function(compressor) {
          return this.computed_key() && this.key.may_throw(compressor);
      });
      def_may_throw(AST_ObjectSetter, function(compressor) {
          return this.computed_key() && this.key.may_throw(compressor);
      });
      def_may_throw(AST_Return, function(compressor) {
          return this.value && this.value.may_throw(compressor);
      });
      def_may_throw(AST_Sequence, function(compressor) {
          return any(this.expressions, compressor);
      });
      def_may_throw(AST_SimpleStatement, function(compressor) {
          return this.body.may_throw(compressor);
      });
      def_may_throw(AST_Dot, function(compressor) {
          if (is_nullish(this, compressor)) return false;
          return !this.optional && this.expression.may_throw_on_access(compressor)
              || this.expression.may_throw(compressor);
      });
      def_may_throw(AST_Sub, function(compressor) {
          if (is_nullish(this, compressor)) return false;
          return !this.optional && this.expression.may_throw_on_access(compressor)
              || this.expression.may_throw(compressor)
              || this.property.may_throw(compressor);
      });
      def_may_throw(AST_Chain, function(compressor) {
          return this.expression.may_throw(compressor);
      });
      def_may_throw(AST_Switch, function(compressor) {
          return this.expression.may_throw(compressor)
              || any(this.body, compressor);
      });
      def_may_throw(AST_SymbolRef, function(compressor) {
          return !this.is_declared(compressor) && !pure_prop_access_globals.has(this.name);
      });
      def_may_throw(AST_SymbolClassProperty, return_false);
      def_may_throw(AST_Try, function(compressor) {
          return this.bcatch ? this.bcatch.may_throw(compressor) : any(this.body, compressor)
              || this.bfinally && this.bfinally.may_throw(compressor);
      });
      def_may_throw(AST_Unary, function(compressor) {
          if (this.operator == "typeof" && this.expression instanceof AST_SymbolRef)
              return false;
          return this.expression.may_throw(compressor);
      });
      def_may_throw(AST_VarDef, function(compressor) {
          if (!this.value) return false;
          return this.value.may_throw(compressor);
      });
  })(function(node, func) {
      node.DEFMETHOD("may_throw", func);
  });

  // determine if expression is constant
  (function(def_is_constant_expression) {
      function all_refs_local(scope) {
          let result = true;
          walk(this, node => {
              if (node instanceof AST_SymbolRef) {
                  if (has_flag(this, INLINED)) {
                      result = false;
                      return walk_abort;
                  }
                  var def = node.definition();
                  if (
                      member(def, this.enclosed)
                      && !this.variables.has(def.name)
                  ) {
                      if (scope) {
                          var scope_def = scope.find_variable(node);
                          if (def.undeclared ? !scope_def : scope_def === def) {
                              result = "f";
                              return true;
                          }
                      }
                      result = false;
                      return walk_abort;
                  }
                  return true;
              }
              if (node instanceof AST_This && this instanceof AST_Arrow) {
                  // TODO check arguments too!
                  result = false;
                  return walk_abort;
              }
          });
          return result;
      }

      def_is_constant_expression(AST_Node, return_false);
      def_is_constant_expression(AST_Constant, return_true);
      def_is_constant_expression(AST_Class, function(scope) {
          if (this.extends && !this.extends.is_constant_expression(scope)) {
              return false;
          }

          for (const prop of this.properties) {
              if (prop.computed_key() && !prop.key.is_constant_expression(scope)) {
                  return false;
              }
              if (prop.static && prop.value && !prop.value.is_constant_expression(scope)) {
                  return false;
              }
          }

          return all_refs_local.call(this, scope);
      });
      def_is_constant_expression(AST_Lambda, all_refs_local);
      def_is_constant_expression(AST_Unary, function() {
          return this.expression.is_constant_expression();
      });
      def_is_constant_expression(AST_Binary, function() {
          return this.left.is_constant_expression()
              && this.right.is_constant_expression();
      });
      def_is_constant_expression(AST_Array, function() {
          return this.elements.every((l) => l.is_constant_expression());
      });
      def_is_constant_expression(AST_Object, function() {
          return this.properties.every((l) => l.is_constant_expression());
      });
      def_is_constant_expression(AST_ObjectProperty, function() {
          return !!(!(this.key instanceof AST_Node) && this.value && this.value.is_constant_expression());
      });
  })(function(node, func) {
      node.DEFMETHOD("is_constant_expression", func);
  });


  // may_throw_on_access()
  // returns true if this node may be null, undefined or contain `AST_Accessor`
  (function(def_may_throw_on_access) {
      AST_Node.DEFMETHOD("may_throw_on_access", function(compressor) {
          return !compressor.option("pure_getters")
              || this._dot_throw(compressor);
      });

      function is_strict(compressor) {
          return /strict/.test(compressor.option("pure_getters"));
      }

      def_may_throw_on_access(AST_Node, is_strict);
      def_may_throw_on_access(AST_Null, return_true);
      def_may_throw_on_access(AST_Undefined, return_true);
      def_may_throw_on_access(AST_Constant, return_false);
      def_may_throw_on_access(AST_Array, return_false);
      def_may_throw_on_access(AST_Object, function(compressor) {
          if (!is_strict(compressor)) return false;
          for (var i = this.properties.length; --i >=0;)
              if (this.properties[i]._dot_throw(compressor)) return true;
          return false;
      });
      // Do not be as strict with classes as we are with objects.
      // Hopefully the community is not going to abuse static getters and setters.
      // https://github.com/terser/terser/issues/724#issuecomment-643655656
      def_may_throw_on_access(AST_Class, return_false);
      def_may_throw_on_access(AST_ObjectProperty, return_false);
      def_may_throw_on_access(AST_ObjectGetter, return_true);
      def_may_throw_on_access(AST_Expansion, function(compressor) {
          return this.expression._dot_throw(compressor);
      });
      def_may_throw_on_access(AST_Function, return_false);
      def_may_throw_on_access(AST_Arrow, return_false);
      def_may_throw_on_access(AST_UnaryPostfix, return_false);
      def_may_throw_on_access(AST_UnaryPrefix, function() {
          return this.operator == "void";
      });
      def_may_throw_on_access(AST_Binary, function(compressor) {
          return (this.operator == "&&" || this.operator == "||" || this.operator == "??")
              && (this.left._dot_throw(compressor) || this.right._dot_throw(compressor));
      });
      def_may_throw_on_access(AST_Assign, function(compressor) {
          if (this.logical) return true;

          return this.operator == "="
              && this.right._dot_throw(compressor);
      });
      def_may_throw_on_access(AST_Conditional, function(compressor) {
          return this.consequent._dot_throw(compressor)
              || this.alternative._dot_throw(compressor);
      });
      def_may_throw_on_access(AST_Dot, function(compressor) {
          if (!is_strict(compressor)) return false;

          if (this.property == "prototype") {
              return !(
                  this.expression instanceof AST_Function
                  || this.expression instanceof AST_Class
              );
          }
          return true;
      });
      def_may_throw_on_access(AST_Chain, function(compressor) {
          return this.expression._dot_throw(compressor);
      });
      def_may_throw_on_access(AST_Sequence, function(compressor) {
          return this.tail_node()._dot_throw(compressor);
      });
      def_may_throw_on_access(AST_SymbolRef, function(compressor) {
          if (this.name === "arguments") return false;
          if (has_flag(this, UNDEFINED)) return true;
          if (!is_strict(compressor)) return false;
          if (is_undeclared_ref(this) && this.is_declared(compressor)) return false;
          if (this.is_immutable()) return false;
          var fixed = this.fixed_value();
          return !fixed || fixed._dot_throw(compressor);
      });
  })(function(node, func) {
      node.DEFMETHOD("_dot_throw", func);
  });

  function is_lhs(node, parent) {
      if (parent instanceof AST_Unary && unary_side_effects.has(parent.operator)) return parent.expression;
      if (parent instanceof AST_Assign && parent.left === node) return node;
  }

  (function(def_find_defs) {
      function to_node(value, orig) {
          if (value instanceof AST_Node) {
              if (!(value instanceof AST_Constant)) {
                  // Value may be a function, an array including functions and even a complex assign / block expression,
                  // so it should never be shared in different places.
                  // Otherwise wrong information may be used in the compression phase
                  value = value.clone(true);
              }
              return make_node(value.CTOR, orig, value);
          }
          if (Array.isArray(value)) return make_node(AST_Array, orig, {
              elements: value.map(function(value) {
                  return to_node(value, orig);
              })
          });
          if (value && typeof value == "object") {
              var props = [];
              for (var key in value) if (HOP(value, key)) {
                  props.push(make_node(AST_ObjectKeyVal, orig, {
                      key: key,
                      value: to_node(value[key], orig)
                  }));
              }
              return make_node(AST_Object, orig, {
                  properties: props
              });
          }
          return make_node_from_constant(value, orig);
      }

      AST_Toplevel.DEFMETHOD("resolve_defines", function(compressor) {
          if (!compressor.option("global_defs")) return this;
          this.figure_out_scope({ ie8: compressor.option("ie8") });
          return this.transform(new TreeTransformer(function(node) {
              var def = node._find_defs(compressor, "");
              if (!def) return;
              var level = 0, child = node, parent;
              while (parent = this.parent(level++)) {
                  if (!(parent instanceof AST_PropAccess)) break;
                  if (parent.expression !== child) break;
                  child = parent;
              }
              if (is_lhs(child, parent)) {
                  return;
              }
              return def;
          }));
      });
      def_find_defs(AST_Node, noop);
      def_find_defs(AST_Chain, function(compressor, suffix) {
          return this.expression._find_defs(compressor, suffix);
      });
      def_find_defs(AST_Dot, function(compressor, suffix) {
          return this.expression._find_defs(compressor, "." + this.property + suffix);
      });
      def_find_defs(AST_SymbolDeclaration, function() {
          if (!this.global()) return;
      });
      def_find_defs(AST_SymbolRef, function(compressor, suffix) {
          if (!this.global()) return;
          var defines = compressor.option("global_defs");
          var name = this.name + suffix;
          if (HOP(defines, name)) return to_node(defines[name], this);
      });
  })(function(node, func) {
      node.DEFMETHOD("_find_defs", func);
  });

  // method to negate an expression
  (function(def_negate) {
      function basic_negation(exp) {
          return make_node(AST_UnaryPrefix, exp, {
              operator: "!",
              expression: exp
          });
      }
      function best(orig, alt, first_in_statement) {
          var negated = basic_negation(orig);
          if (first_in_statement) {
              var stat = make_node(AST_SimpleStatement, alt, {
                  body: alt
              });
              return best_of_expression(negated, stat) === stat ? alt : negated;
          }
          return best_of_expression(negated, alt);
      }
      def_negate(AST_Node, function() {
          return basic_negation(this);
      });
      def_negate(AST_Statement, function() {
          throw new Error("Cannot negate a statement");
      });
      def_negate(AST_Function, function() {
          return basic_negation(this);
      });
      def_negate(AST_Arrow, function() {
          return basic_negation(this);
      });
      def_negate(AST_UnaryPrefix, function() {
          if (this.operator == "!")
              return this.expression;
          return basic_negation(this);
      });
      def_negate(AST_Sequence, function(compressor) {
          var expressions = this.expressions.slice();
          expressions.push(expressions.pop().negate(compressor));
          return make_sequence(this, expressions);
      });
      def_negate(AST_Conditional, function(compressor, first_in_statement) {
          var self = this.clone();
          self.consequent = self.consequent.negate(compressor);
          self.alternative = self.alternative.negate(compressor);
          return best(this, self, first_in_statement);
      });
      def_negate(AST_Binary, function(compressor, first_in_statement) {
          var self = this.clone(), op = this.operator;
          if (compressor.option("unsafe_comps")) {
              switch (op) {
                case "<=" : self.operator = ">"  ; return self;
                case "<"  : self.operator = ">=" ; return self;
                case ">=" : self.operator = "<"  ; return self;
                case ">"  : self.operator = "<=" ; return self;
              }
          }
          switch (op) {
            case "==" : self.operator = "!="; return self;
            case "!=" : self.operator = "=="; return self;
            case "===": self.operator = "!=="; return self;
            case "!==": self.operator = "==="; return self;
            case "&&":
              self.operator = "||";
              self.left = self.left.negate(compressor, first_in_statement);
              self.right = self.right.negate(compressor);
              return best(this, self, first_in_statement);
            case "||":
              self.operator = "&&";
              self.left = self.left.negate(compressor, first_in_statement);
              self.right = self.right.negate(compressor);
              return best(this, self, first_in_statement);
          }
          return basic_negation(this);
      });
  })(function(node, func) {
      node.DEFMETHOD("negate", function(compressor, first_in_statement) {
          return func.call(this, compressor, first_in_statement);
      });
  });

  // Is the callee of this function pure?
  var global_pure_fns = makePredicate("Boolean decodeURI decodeURIComponent Date encodeURI encodeURIComponent Error escape EvalError isFinite isNaN Number Object parseFloat parseInt RangeError ReferenceError String SyntaxError TypeError unescape URIError");
  AST_Call.DEFMETHOD("is_callee_pure", function(compressor) {
      if (compressor.option("unsafe")) {
          var expr = this.expression;
          var first_arg = (this.args && this.args[0] && this.args[0].evaluate(compressor));
          if (
              expr.expression && expr.expression.name === "hasOwnProperty" &&
              (first_arg == null || first_arg.thedef && first_arg.thedef.undeclared)
          ) {
              return false;
          }
          if (is_undeclared_ref(expr) && global_pure_fns.has(expr.name)) return true;
          if (
              expr instanceof AST_Dot
              && is_undeclared_ref(expr.expression)
              && is_pure_native_fn(expr.expression.name, expr.property)
          ) {
              return true;
          }
      }
      return !!has_annotation(this, _PURE) || !compressor.pure_funcs(this);
  });

  // If I call this, is it a pure function?
  AST_Node.DEFMETHOD("is_call_pure", return_false);
  AST_Dot.DEFMETHOD("is_call_pure", function(compressor) {
      if (!compressor.option("unsafe")) return;
      const expr = this.expression;

      let native_obj;
      if (expr instanceof AST_Array) {
          native_obj = "Array";
      } else if (expr.is_boolean()) {
          native_obj = "Boolean";
      } else if (expr.is_number(compressor)) {
          native_obj = "Number";
      } else if (expr instanceof AST_RegExp) {
          native_obj = "RegExp";
      } else if (expr.is_string(compressor)) {
          native_obj = "String";
      } else if (!this.may_throw_on_access(compressor)) {
          native_obj = "Object";
      }
      return native_obj != null && is_pure_native_method(native_obj, this.property);
  });

  // tell me if a statement aborts
  const aborts = (thing) => thing && thing.aborts();

  (function(def_aborts) {
      def_aborts(AST_Statement, return_null);
      def_aborts(AST_Jump, return_this);
      function block_aborts() {
          for (var i = 0; i < this.body.length; i++) {
              if (aborts(this.body[i])) {
                  return this.body[i];
              }
          }
          return null;
      }
      def_aborts(AST_Import, function() { return null; });
      def_aborts(AST_BlockStatement, block_aborts);
      def_aborts(AST_SwitchBranch, block_aborts);
      def_aborts(AST_If, function() {
          return this.alternative && aborts(this.body) && aborts(this.alternative) && this;
      });
  })(function(node, func) {
      node.DEFMETHOD("aborts", func);
  });

  function is_modified(compressor, tw, node, value, level, immutable) {
      var parent = tw.parent(level);
      var lhs = is_lhs(node, parent);
      if (lhs) return lhs;
      if (!immutable
          && parent instanceof AST_Call
          && parent.expression === node
          && !(value instanceof AST_Arrow)
          && !(value instanceof AST_Class)
          && !parent.is_callee_pure(compressor)
          && (!(value instanceof AST_Function)
              || !(parent instanceof AST_New) && value.contains_this())) {
          return true;
      }
      if (parent instanceof AST_Array) {
          return is_modified(compressor, tw, parent, parent, level + 1);
      }
      if (parent instanceof AST_ObjectKeyVal && node === parent.value) {
          var obj = tw.parent(level + 1);
          return is_modified(compressor, tw, obj, obj, level + 2);
      }
      if (parent instanceof AST_PropAccess && parent.expression === node) {
          var prop = read_property(value, parent.property);
          return !immutable && is_modified(compressor, tw, parent, prop, level + 1);
      }
  }

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  // methods to evaluate a constant expression

  function def_eval(node, func) {
      node.DEFMETHOD("_eval", func);
  }

  // Used to propagate a nullish short-circuit signal upwards through the chain.
  const nullish = Symbol("This AST_Chain is nullish");

  // If the node has been successfully reduced to a constant,
  // then its value is returned; otherwise the element itself
  // is returned.
  // They can be distinguished as constant value is never a
  // descendant of AST_Node.
  AST_Node.DEFMETHOD("evaluate", function (compressor) {
      if (!compressor.option("evaluate"))
          return this;
      var val = this._eval(compressor, 1);
      if (!val || val instanceof RegExp)
          return val;
      if (typeof val == "function" || typeof val == "object" || val == nullish)
          return this;
      return val;
  });

  var unaryPrefix = makePredicate("! ~ - + void");
  AST_Node.DEFMETHOD("is_constant", function () {
      // Accomodate when compress option evaluate=false
      // as well as the common constant expressions !0 and -1
      if (this instanceof AST_Constant) {
          return !(this instanceof AST_RegExp);
      } else {
          return this instanceof AST_UnaryPrefix
              && this.expression instanceof AST_Constant
              && unaryPrefix.has(this.operator);
      }
  });

  def_eval(AST_Statement, function () {
      throw new Error(string_template("Cannot evaluate a statement [{file}:{line},{col}]", this.start));
  });

  def_eval(AST_Lambda, return_this);
  def_eval(AST_Class, return_this);
  def_eval(AST_Node, return_this);
  def_eval(AST_Constant, function () {
      return this.getValue();
  });

  def_eval(AST_BigInt, return_this);

  def_eval(AST_RegExp, function (compressor) {
      let evaluated = compressor.evaluated_regexps.get(this.value);
      if (evaluated === undefined && regexp_is_safe(this.value.source)) {
          try {
              const { source, flags } = this.value;
              evaluated = new RegExp(source, flags);
          } catch (e) {
              evaluated = null;
          }
          compressor.evaluated_regexps.set(this.value, evaluated);
      }
      return evaluated || this;
  });

  def_eval(AST_TemplateString, function () {
      if (this.segments.length !== 1) return this;
      return this.segments[0].value;
  });

  def_eval(AST_Function, function (compressor) {
      if (compressor.option("unsafe")) {
          var fn = function () { };
          fn.node = this;
          fn.toString = () => this.print_to_string();
          return fn;
      }
      return this;
  });

  def_eval(AST_Array, function (compressor, depth) {
      if (compressor.option("unsafe")) {
          var elements = [];
          for (var i = 0, len = this.elements.length; i < len; i++) {
              var element = this.elements[i];
              var value = element._eval(compressor, depth);
              if (element === value)
                  return this;
              elements.push(value);
          }
          return elements;
      }
      return this;
  });

  def_eval(AST_Object, function (compressor, depth) {
      if (compressor.option("unsafe")) {
          var val = {};
          for (var i = 0, len = this.properties.length; i < len; i++) {
              var prop = this.properties[i];
              if (prop instanceof AST_Expansion)
                  return this;
              var key = prop.key;
              if (key instanceof AST_Symbol) {
                  key = key.name;
              } else if (key instanceof AST_Node) {
                  key = key._eval(compressor, depth);
                  if (key === prop.key)
                      return this;
              }
              if (typeof Object.prototype[key] === "function") {
                  return this;
              }
              if (prop.value instanceof AST_Function)
                  continue;
              val[key] = prop.value._eval(compressor, depth);
              if (val[key] === prop.value)
                  return this;
          }
          return val;
      }
      return this;
  });

  var non_converting_unary = makePredicate("! typeof void");
  def_eval(AST_UnaryPrefix, function (compressor, depth) {
      var e = this.expression;
      // Function would be evaluated to an array and so typeof would
      // incorrectly return 'object'. Hence making is a special case.
      if (compressor.option("typeofs")
          && this.operator == "typeof"
          && (e instanceof AST_Lambda
              || e instanceof AST_SymbolRef
              && e.fixed_value() instanceof AST_Lambda)) {
          return typeof function () { };
      }
      if (!non_converting_unary.has(this.operator))
          depth++;
      e = e._eval(compressor, depth);
      if (e === this.expression)
          return this;
      switch (this.operator) {
          case "!": return !e;
          case "typeof":
              // typeof <RegExp> returns "object" or "function" on different platforms
              // so cannot evaluate reliably
              if (e instanceof RegExp)
                  return this;
              return typeof e;
          case "void": return void e;
          case "~": return ~e;
          case "-": return -e;
          case "+": return +e;
      }
      return this;
  });

  var non_converting_binary = makePredicate("&& || ?? === !==");
  const identity_comparison = makePredicate("== != === !==");
  const has_identity = value => typeof value === "object"
      || typeof value === "function"
      || typeof value === "symbol";

  def_eval(AST_Binary, function (compressor, depth) {
      if (!non_converting_binary.has(this.operator))
          depth++;

      var left = this.left._eval(compressor, depth);
      if (left === this.left)
          return this;
      var right = this.right._eval(compressor, depth);
      if (right === this.right)
          return this;
      var result;

      if (left != null
          && right != null
          && identity_comparison.has(this.operator)
          && has_identity(left)
          && has_identity(right)
          && typeof left === typeof right) {
          // Do not compare by reference
          return this;
      }

      switch (this.operator) {
          case "&&": result = left && right; break;
          case "||": result = left || right; break;
          case "??": result = left != null ? left : right; break;
          case "|": result = left | right; break;
          case "&": result = left & right; break;
          case "^": result = left ^ right; break;
          case "+": result = left + right; break;
          case "*": result = left * right; break;
          case "**": result = Math.pow(left, right); break;
          case "/": result = left / right; break;
          case "%": result = left % right; break;
          case "-": result = left - right; break;
          case "<<": result = left << right; break;
          case ">>": result = left >> right; break;
          case ">>>": result = left >>> right; break;
          case "==": result = left == right; break;
          case "===": result = left === right; break;
          case "!=": result = left != right; break;
          case "!==": result = left !== right; break;
          case "<": result = left < right; break;
          case "<=": result = left <= right; break;
          case ">": result = left > right; break;
          case ">=": result = left >= right; break;
          default:
              return this;
      }
      if (isNaN(result) && compressor.find_parent(AST_With)) {
          // leave original expression as is
          return this;
      }
      return result;
  });

  def_eval(AST_Conditional, function (compressor, depth) {
      var condition = this.condition._eval(compressor, depth);
      if (condition === this.condition)
          return this;
      var node = condition ? this.consequent : this.alternative;
      var value = node._eval(compressor, depth);
      return value === node ? this : value;
  });

  // Set of AST_SymbolRef which are currently being evaluated.
  // Avoids infinite recursion of ._eval()
  const reentrant_ref_eval = new Set();
  def_eval(AST_SymbolRef, function (compressor, depth) {
      if (reentrant_ref_eval.has(this))
          return this;

      var fixed = this.fixed_value();
      if (!fixed)
          return this;

      reentrant_ref_eval.add(this);
      const value = fixed._eval(compressor, depth);
      reentrant_ref_eval.delete(this);

      if (value === fixed)
          return this;

      if (value && typeof value == "object") {
          var escaped = this.definition().escaped;
          if (escaped && depth > escaped)
              return this;
      }
      return value;
  });

  const global_objs = { Array, Math, Number, Object, String };

  const regexp_flags = new Set([
      "dotAll",
      "global",
      "ignoreCase",
      "multiline",
      "sticky",
      "unicode",
  ]);

  def_eval(AST_PropAccess, function (compressor, depth) {
      let obj = this.expression._eval(compressor, depth + 1);
      if (obj === nullish || (this.optional && obj == null)) return nullish;
      if (compressor.option("unsafe")) {
          var key = this.property;
          if (key instanceof AST_Node) {
              key = key._eval(compressor, depth);
              if (key === this.property)
                  return this;
          }
          var exp = this.expression;
          if (is_undeclared_ref(exp)) {

              var aa;
              var first_arg = exp.name === "hasOwnProperty"
                  && key === "call"
                  && (aa = compressor.parent() && compressor.parent().args)
                  && (aa && aa[0]
                      && aa[0].evaluate(compressor));

              first_arg = first_arg instanceof AST_Dot ? first_arg.expression : first_arg;

              if (first_arg == null || first_arg.thedef && first_arg.thedef.undeclared) {
                  return this.clone();
              }
              if (!is_pure_native_value(exp.name, key))
                  return this;
              obj = global_objs[exp.name];
          } else {
              if (obj instanceof RegExp) {
                  if (key == "source") {
                      return regexp_source_fix(obj.source);
                  } else if (key == "flags" || regexp_flags.has(key)) {
                      return obj[key];
                  }
              }
              if (!obj || obj === exp || !HOP(obj, key))
                  return this;

              if (typeof obj == "function")
                  switch (key) {
                      case "name":
                          return obj.node.name ? obj.node.name.name : "";
                      case "length":
                          return obj.node.length_property();
                      default:
                          return this;
                  }
          }
          return obj[key];
      }
      return this;
  });

  def_eval(AST_Chain, function (compressor, depth) {
      const evaluated = this.expression._eval(compressor, depth);
      return evaluated === nullish
          ? undefined
          : evaluated === this.expression
            ? this
            : evaluated;
  });

  def_eval(AST_Call, function (compressor, depth) {
      var exp = this.expression;

      const callee = exp._eval(compressor, depth);
      if (callee === nullish || (this.optional && callee == null)) return nullish;

      if (compressor.option("unsafe") && exp instanceof AST_PropAccess) {
          var key = exp.property;
          if (key instanceof AST_Node) {
              key = key._eval(compressor, depth);
              if (key === exp.property)
                  return this;
          }
          var val;
          var e = exp.expression;
          if (is_undeclared_ref(e)) {
              var first_arg = e.name === "hasOwnProperty" &&
                  key === "call" &&
                  (this.args[0] && this.args[0].evaluate(compressor));

              first_arg = first_arg instanceof AST_Dot ? first_arg.expression : first_arg;

              if ((first_arg == null || first_arg.thedef && first_arg.thedef.undeclared)) {
                  return this.clone();
              }
              if (!is_pure_native_fn(e.name, key)) return this;
              val = global_objs[e.name];
          } else {
              val = e._eval(compressor, depth + 1);
              if (val === e || !val)
                  return this;
              if (!is_pure_native_method(val.constructor.name, key))
                  return this;
          }
          var args = [];
          for (var i = 0, len = this.args.length; i < len; i++) {
              var arg = this.args[i];
              var value = arg._eval(compressor, depth);
              if (arg === value)
                  return this;
              if (arg instanceof AST_Lambda)
                  return this;
              args.push(value);
          }
          try {
              return val[key].apply(val, args);
          } catch (ex) {
              // We don't really care
          }
      }
      return this;
  });

  // Also a subclass of AST_Call
  def_eval(AST_New, return_this);

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  // AST_Node#drop_side_effect_free() gets called when we don't care about the value,
  // only about side effects. We'll be defining this method for each node type in this module
  //
  // Examples:
  // foo++ -> foo++
  // 1 + func() -> func()
  // 10 -> (nothing)
  // knownPureFunc(foo++) -> foo++

  function def_drop_side_effect_free(node, func) {
      node.DEFMETHOD("drop_side_effect_free", func);
  }

  // Drop side-effect-free elements from an array of expressions.
  // Returns an array of expressions with side-effects or null
  // if all elements were dropped. Note: original array may be
  // returned if nothing changed.
  function trim(nodes, compressor, first_in_statement) {
      var len = nodes.length;
      if (!len)  return null;

      var ret = [], changed = false;
      for (var i = 0; i < len; i++) {
          var node = nodes[i].drop_side_effect_free(compressor, first_in_statement);
          changed |= node !== nodes[i];
          if (node) {
              ret.push(node);
              first_in_statement = false;
          }
      }
      return changed ? ret.length ? ret : null : nodes;
  }

  def_drop_side_effect_free(AST_Node, return_this);
  def_drop_side_effect_free(AST_Constant, return_null);
  def_drop_side_effect_free(AST_This, return_null);

  def_drop_side_effect_free(AST_Call, function (compressor, first_in_statement) {
      if (is_nullish_shortcircuited(this, compressor)) {
          return this.expression.drop_side_effect_free(compressor, first_in_statement);
      }

      if (!this.is_callee_pure(compressor)) {
          if (this.expression.is_call_pure(compressor)) {
              var exprs = this.args.slice();
              exprs.unshift(this.expression.expression);
              exprs = trim(exprs, compressor, first_in_statement);
              return exprs && make_sequence(this, exprs);
          }
          if (is_func_expr(this.expression)
              && (!this.expression.name || !this.expression.name.definition().references.length)) {
              var node = this.clone();
              node.expression.process_expression(false, compressor);
              return node;
          }
          return this;
      }

      var args = trim(this.args, compressor, first_in_statement);
      return args && make_sequence(this, args);
  });

  def_drop_side_effect_free(AST_Accessor, return_null);

  def_drop_side_effect_free(AST_Function, return_null);

  def_drop_side_effect_free(AST_Arrow, return_null);

  def_drop_side_effect_free(AST_Class, function (compressor) {
      const with_effects = [];
      const trimmed_extends = this.extends && this.extends.drop_side_effect_free(compressor);
      if (trimmed_extends)
          with_effects.push(trimmed_extends);
      for (const prop of this.properties) {
          const trimmed_prop = prop.drop_side_effect_free(compressor);
          if (trimmed_prop)
              with_effects.push(trimmed_prop);
      }
      if (!with_effects.length)
          return null;
      return make_sequence(this, with_effects);
  });

  def_drop_side_effect_free(AST_Binary, function (compressor, first_in_statement) {
      var right = this.right.drop_side_effect_free(compressor);
      if (!right)
          return this.left.drop_side_effect_free(compressor, first_in_statement);
      if (lazy_op.has(this.operator)) {
          if (right === this.right)
              return this;
          var node = this.clone();
          node.right = right;
          return node;
      } else {
          var left = this.left.drop_side_effect_free(compressor, first_in_statement);
          if (!left)
              return this.right.drop_side_effect_free(compressor, first_in_statement);
          return make_sequence(this, [left, right]);
      }
  });

  def_drop_side_effect_free(AST_Assign, function (compressor) {
      if (this.logical)
          return this;

      var left = this.left;
      if (left.has_side_effects(compressor)
          || compressor.has_directive("use strict")
          && left instanceof AST_PropAccess
          && left.expression.is_constant()) {
          return this;
      }
      set_flag(this, WRITE_ONLY);
      while (left instanceof AST_PropAccess) {
          left = left.expression;
      }
      if (left.is_constant_expression(compressor.find_parent(AST_Scope))) {
          return this.right.drop_side_effect_free(compressor);
      }
      return this;
  });

  def_drop_side_effect_free(AST_Conditional, function (compressor) {
      var consequent = this.consequent.drop_side_effect_free(compressor);
      var alternative = this.alternative.drop_side_effect_free(compressor);
      if (consequent === this.consequent && alternative === this.alternative)
          return this;
      if (!consequent)
          return alternative ? make_node(AST_Binary, this, {
              operator: "||",
              left: this.condition,
              right: alternative
          }) : this.condition.drop_side_effect_free(compressor);
      if (!alternative)
          return make_node(AST_Binary, this, {
              operator: "&&",
              left: this.condition,
              right: consequent
          });
      var node = this.clone();
      node.consequent = consequent;
      node.alternative = alternative;
      return node;
  });

  def_drop_side_effect_free(AST_Unary, function (compressor, first_in_statement) {
      if (unary_side_effects.has(this.operator)) {
          if (!this.expression.has_side_effects(compressor)) {
              set_flag(this, WRITE_ONLY);
          } else {
              clear_flag(this, WRITE_ONLY);
          }
          return this;
      }
      if (this.operator == "typeof" && this.expression instanceof AST_SymbolRef)
          return null;
      var expression = this.expression.drop_side_effect_free(compressor, first_in_statement);
      if (first_in_statement && expression && is_iife_call(expression)) {
          if (expression === this.expression && this.operator == "!")
              return this;
          return expression.negate(compressor, first_in_statement);
      }
      return expression;
  });

  def_drop_side_effect_free(AST_SymbolRef, function (compressor) {
      const safe_access = this.is_declared(compressor)
          || pure_prop_access_globals.has(this.name);
      return safe_access ? null : this;
  });

  def_drop_side_effect_free(AST_Object, function (compressor, first_in_statement) {
      var values = trim(this.properties, compressor, first_in_statement);
      return values && make_sequence(this, values);
  });

  def_drop_side_effect_free(AST_ObjectProperty, function (compressor, first_in_statement) {
      const computed_key = this instanceof AST_ObjectKeyVal && this.key instanceof AST_Node;
      const key = computed_key && this.key.drop_side_effect_free(compressor, first_in_statement);
      const value = this.value && this.value.drop_side_effect_free(compressor, first_in_statement);
      if (key && value) {
          return make_sequence(this, [key, value]);
      }
      return key || value;
  });

  def_drop_side_effect_free(AST_ClassProperty, function (compressor) {
      const key = this.computed_key() && this.key.drop_side_effect_free(compressor);

      const value = this.static && this.value
          && this.value.drop_side_effect_free(compressor);

      if (key && value)
          return make_sequence(this, [key, value]);
      return key || value || null;
  });

  def_drop_side_effect_free(AST_ConciseMethod, function () {
      return this.computed_key() ? this.key : null;
  });

  def_drop_side_effect_free(AST_ObjectGetter, function () {
      return this.computed_key() ? this.key : null;
  });

  def_drop_side_effect_free(AST_ObjectSetter, function () {
      return this.computed_key() ? this.key : null;
  });

  def_drop_side_effect_free(AST_Array, function (compressor, first_in_statement) {
      var values = trim(this.elements, compressor, first_in_statement);
      return values && make_sequence(this, values);
  });

  def_drop_side_effect_free(AST_Dot, function (compressor, first_in_statement) {
      if (is_nullish_shortcircuited(this, compressor)) {
          return this.expression.drop_side_effect_free(compressor, first_in_statement);
      }
      if (this.expression.may_throw_on_access(compressor)) return this;

      return this.expression.drop_side_effect_free(compressor, first_in_statement);
  });

  def_drop_side_effect_free(AST_Sub, function (compressor, first_in_statement) {
      if (is_nullish_shortcircuited(this, compressor)) {
          return this.expression.drop_side_effect_free(compressor, first_in_statement);
      }
      if (this.expression.may_throw_on_access(compressor)) return this;

      var expression = this.expression.drop_side_effect_free(compressor, first_in_statement);
      if (!expression)
          return this.property.drop_side_effect_free(compressor, first_in_statement);
      var property = this.property.drop_side_effect_free(compressor);
      if (!property)
          return expression;
      return make_sequence(this, [expression, property]);
  });

  def_drop_side_effect_free(AST_Chain, function (compressor, first_in_statement) {
      return this.expression.drop_side_effect_free(compressor, first_in_statement);
  });

  def_drop_side_effect_free(AST_Sequence, function (compressor) {
      var last = this.tail_node();
      var expr = last.drop_side_effect_free(compressor);
      if (expr === last)
          return this;
      var expressions = this.expressions.slice(0, -1);
      if (expr)
          expressions.push(expr);
      if (!expressions.length) {
          return make_node(AST_Number, this, { value: 0 });
      }
      return make_sequence(this, expressions);
  });

  def_drop_side_effect_free(AST_Expansion, function (compressor, first_in_statement) {
      return this.expression.drop_side_effect_free(compressor, first_in_statement);
  });

  def_drop_side_effect_free(AST_TemplateSegment, return_null);

  def_drop_side_effect_free(AST_TemplateString, function (compressor) {
      var values = trim(this.segments, compressor, first_in_statement);
      return values && make_sequence(this, values);
  });

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  // Define the method AST_Node#reduce_vars, which goes through the AST in
  // execution order to perform basic flow analysis

  function def_reduce_vars(node, func) {
      node.DEFMETHOD("reduce_vars", func);
  }

  def_reduce_vars(AST_Node, noop);

  function reset_def(compressor, def) {
      def.assignments = 0;
      def.chained = false;
      def.direct_access = false;
      def.escaped = 0;
      def.recursive_refs = 0;
      def.references = [];
      def.single_use = undefined;
      if (def.scope.pinned()) {
          def.fixed = false;
      } else if (def.orig[0] instanceof AST_SymbolConst || !compressor.exposed(def)) {
          def.fixed = def.init;
      } else {
          def.fixed = false;
      }
  }

  function reset_variables(tw, compressor, node) {
      node.variables.forEach(function(def) {
          reset_def(compressor, def);
          if (def.fixed === null) {
              tw.defs_to_safe_ids.set(def.id, tw.safe_ids);
              mark(tw, def, true);
          } else if (def.fixed) {
              tw.loop_ids.set(def.id, tw.in_loop);
              mark(tw, def, true);
          }
      });
  }

  function reset_block_variables(compressor, node) {
      if (node.block_scope) node.block_scope.variables.forEach((def) => {
          reset_def(compressor, def);
      });
  }

  function push(tw) {
      tw.safe_ids = Object.create(tw.safe_ids);
  }

  function pop(tw) {
      tw.safe_ids = Object.getPrototypeOf(tw.safe_ids);
  }

  function mark(tw, def, safe) {
      tw.safe_ids[def.id] = safe;
  }

  function safe_to_read(tw, def) {
      if (def.single_use == "m") return false;
      if (tw.safe_ids[def.id]) {
          if (def.fixed == null) {
              var orig = def.orig[0];
              if (orig instanceof AST_SymbolFunarg || orig.name == "arguments") return false;
              def.fixed = make_node(AST_Undefined, orig);
          }
          return true;
      }
      return def.fixed instanceof AST_Defun;
  }

  function safe_to_assign(tw, def, scope, value) {
      if (def.fixed === undefined) return true;
      let def_safe_ids;
      if (def.fixed === null
          && (def_safe_ids = tw.defs_to_safe_ids.get(def.id))
      ) {
          def_safe_ids[def.id] = false;
          tw.defs_to_safe_ids.delete(def.id);
          return true;
      }
      if (!HOP(tw.safe_ids, def.id)) return false;
      if (!safe_to_read(tw, def)) return false;
      if (def.fixed === false) return false;
      if (def.fixed != null && (!value || def.references.length > def.assignments)) return false;
      if (def.fixed instanceof AST_Defun) {
          return value instanceof AST_Node && def.fixed.parent_scope === scope;
      }
      return def.orig.every((sym) => {
          return !(sym instanceof AST_SymbolConst
              || sym instanceof AST_SymbolDefun
              || sym instanceof AST_SymbolLambda);
      });
  }

  function ref_once(tw, compressor, def) {
      return compressor.option("unused")
          && !def.scope.pinned()
          && def.references.length - def.recursive_refs == 1
          && tw.loop_ids.get(def.id) === tw.in_loop;
  }

  function is_immutable(value) {
      if (!value) return false;
      return value.is_constant()
          || value instanceof AST_Lambda
          || value instanceof AST_This;
  }

  // A definition "escapes" when its value can leave the point of use.
  // Example: `a = b || c`
  // In this example, "b" and "c" are escaping, because they're going into "a"
  //
  // def.escaped is != 0 when it escapes.
  //
  // When greater than 1, it means that N chained properties will be read off
  // of that def before an escape occurs. This is useful for evaluating
  // property accesses, where you need to know when to stop.
  function mark_escaped(tw, d, scope, node, value, level = 0, depth = 1) {
      var parent = tw.parent(level);
      if (value) {
          if (value.is_constant()) return;
          if (value instanceof AST_ClassExpression) return;
      }

      if (
          parent instanceof AST_Assign && (parent.operator === "=" || parent.logical) && node === parent.right
          || parent instanceof AST_Call && (node !== parent.expression || parent instanceof AST_New)
          || parent instanceof AST_Exit && node === parent.value && node.scope !== d.scope
          || parent instanceof AST_VarDef && node === parent.value
          || parent instanceof AST_Yield && node === parent.value && node.scope !== d.scope
      ) {
          if (depth > 1 && !(value && value.is_constant_expression(scope))) depth = 1;
          if (!d.escaped || d.escaped > depth) d.escaped = depth;
          return;
      } else if (
          parent instanceof AST_Array
          || parent instanceof AST_Await
          || parent instanceof AST_Binary && lazy_op.has(parent.operator)
          || parent instanceof AST_Conditional && node !== parent.condition
          || parent instanceof AST_Expansion
          || parent instanceof AST_Sequence && node === parent.tail_node()
      ) {
          mark_escaped(tw, d, scope, parent, parent, level + 1, depth);
      } else if (parent instanceof AST_ObjectKeyVal && node === parent.value) {
          var obj = tw.parent(level + 1);

          mark_escaped(tw, d, scope, obj, obj, level + 2, depth);
      } else if (parent instanceof AST_PropAccess && node === parent.expression) {
          value = read_property(value, parent.property);

          mark_escaped(tw, d, scope, parent, value, level + 1, depth + 1);
          if (value) return;
      }

      if (level > 0) return;
      if (parent instanceof AST_Sequence && node !== parent.tail_node()) return;
      if (parent instanceof AST_SimpleStatement) return;

      d.direct_access = true;
  }

  const suppress = node => walk(node, node => {
      if (!(node instanceof AST_Symbol)) return;
      var d = node.definition();
      if (!d) return;
      if (node instanceof AST_SymbolRef) d.references.push(node);
      d.fixed = false;
  });

  def_reduce_vars(AST_Accessor, function(tw, descend, compressor) {
      push(tw);
      reset_variables(tw, compressor, this);
      descend();
      pop(tw);
      return true;
  });

  def_reduce_vars(AST_Assign, function(tw, descend, compressor) {
      var node = this;
      if (node.left instanceof AST_Destructuring) {
          suppress(node.left);
          return;
      }

      const finish_walk = () => {
          if (node.logical) {
              node.left.walk(tw);

              push(tw);
              node.right.walk(tw);
              pop(tw);

              return true;
          }
      };

      var sym = node.left;
      if (!(sym instanceof AST_SymbolRef)) return finish_walk();

      var def = sym.definition();
      var safe = safe_to_assign(tw, def, sym.scope, node.right);
      def.assignments++;
      if (!safe) return finish_walk();

      var fixed = def.fixed;
      if (!fixed && node.operator != "=" && !node.logical) return finish_walk();

      var eq = node.operator == "=";
      var value = eq ? node.right : node;
      if (is_modified(compressor, tw, node, value, 0)) return finish_walk();

      def.references.push(sym);

      if (!node.logical) {
          if (!eq) def.chained = true;

          def.fixed = eq ? function() {
              return node.right;
          } : function() {
              return make_node(AST_Binary, node, {
                  operator: node.operator.slice(0, -1),
                  left: fixed instanceof AST_Node ? fixed : fixed(),
                  right: node.right
              });
          };
      }

      if (node.logical) {
          mark(tw, def, false);
          push(tw);
          node.right.walk(tw);
          pop(tw);
          return true;
      }

      mark(tw, def, false);
      node.right.walk(tw);
      mark(tw, def, true);

      mark_escaped(tw, def, sym.scope, node, value, 0, 1);

      return true;
  });

  def_reduce_vars(AST_Binary, function(tw) {
      if (!lazy_op.has(this.operator)) return;
      this.left.walk(tw);
      push(tw);
      this.right.walk(tw);
      pop(tw);
      return true;
  });

  def_reduce_vars(AST_Block, function(tw, descend, compressor) {
      reset_block_variables(compressor, this);
  });

  def_reduce_vars(AST_Case, function(tw) {
      push(tw);
      this.expression.walk(tw);
      pop(tw);
      push(tw);
      walk_body(this, tw);
      pop(tw);
      return true;
  });

  def_reduce_vars(AST_Class, function(tw, descend) {
      clear_flag(this, INLINED);
      push(tw);
      descend();
      pop(tw);
      return true;
  });

  def_reduce_vars(AST_Conditional, function(tw) {
      this.condition.walk(tw);
      push(tw);
      this.consequent.walk(tw);
      pop(tw);
      push(tw);
      this.alternative.walk(tw);
      pop(tw);
      return true;
  });

  def_reduce_vars(AST_Chain, function(tw, descend) {
      // Chains' conditions apply left-to-right, cumulatively.
      // If we walk normally we don't go in that order because we would pop before pushing again
      // Solution: AST_PropAccess and AST_Call push when they are optional, and never pop.
      // Then we pop everything when they are done being walked.
      const safe_ids = tw.safe_ids;

      descend();

      // Unroll back to start
      tw.safe_ids = safe_ids;
      return true;
  });

  def_reduce_vars(AST_Call, function (tw) {
      this.expression.walk(tw);

      if (this.optional) {
          // Never pop -- it's popped at AST_Chain above
          push(tw);
      }

      for (const arg of this.args) arg.walk(tw);

      return true;
  });

  def_reduce_vars(AST_PropAccess, function (tw) {
      if (!this.optional) return;

      this.expression.walk(tw);

      // Never pop -- it's popped at AST_Chain above
      push(tw);

      if (this.property instanceof AST_Node) this.property.walk(tw);

      return true;
  });

  def_reduce_vars(AST_Default, function(tw, descend) {
      push(tw);
      descend();
      pop(tw);
      return true;
  });

  function mark_lambda(tw, descend, compressor) {
      clear_flag(this, INLINED);
      push(tw);
      reset_variables(tw, compressor, this);
      if (this.uses_arguments) {
          descend();
          pop(tw);
          return;
      }
      var iife;
      if (!this.name
          && (iife = tw.parent()) instanceof AST_Call
          && iife.expression === this
          && !iife.args.some(arg => arg instanceof AST_Expansion)
          && this.argnames.every(arg_name => arg_name instanceof AST_Symbol)
      ) {
          // Virtually turn IIFE parameters into variable definitions:
          //   (function(a,b) {...})(c,d) => (function() {var a=c,b=d; ...})()
          // So existing transformation rules can work on them.
          this.argnames.forEach((arg, i) => {
              if (!arg.definition) return;
              var d = arg.definition();
              // Avoid setting fixed when there's more than one origin for a variable value
              if (d.orig.length > 1) return;
              if (d.fixed === undefined && (!this.uses_arguments || tw.has_directive("use strict"))) {
                  d.fixed = function() {
                      return iife.args[i] || make_node(AST_Undefined, iife);
                  };
                  tw.loop_ids.set(d.id, tw.in_loop);
                  mark(tw, d, true);
              } else {
                  d.fixed = false;
              }
          });
      }
      descend();
      pop(tw);
      return true;
  }

  def_reduce_vars(AST_Lambda, mark_lambda);

  def_reduce_vars(AST_Do, function(tw, descend, compressor) {
      reset_block_variables(compressor, this);
      const saved_loop = tw.in_loop;
      tw.in_loop = this;
      push(tw);
      this.body.walk(tw);
      if (has_break_or_continue(this)) {
          pop(tw);
          push(tw);
      }
      this.condition.walk(tw);
      pop(tw);
      tw.in_loop = saved_loop;
      return true;
  });

  def_reduce_vars(AST_For, function(tw, descend, compressor) {
      reset_block_variables(compressor, this);
      if (this.init) this.init.walk(tw);
      const saved_loop = tw.in_loop;
      tw.in_loop = this;
      push(tw);
      if (this.condition) this.condition.walk(tw);
      this.body.walk(tw);
      if (this.step) {
          if (has_break_or_continue(this)) {
              pop(tw);
              push(tw);
          }
          this.step.walk(tw);
      }
      pop(tw);
      tw.in_loop = saved_loop;
      return true;
  });

  def_reduce_vars(AST_ForIn, function(tw, descend, compressor) {
      reset_block_variables(compressor, this);
      suppress(this.init);
      this.object.walk(tw);
      const saved_loop = tw.in_loop;
      tw.in_loop = this;
      push(tw);
      this.body.walk(tw);
      pop(tw);
      tw.in_loop = saved_loop;
      return true;
  });

  def_reduce_vars(AST_If, function(tw) {
      this.condition.walk(tw);
      push(tw);
      this.body.walk(tw);
      pop(tw);
      if (this.alternative) {
          push(tw);
          this.alternative.walk(tw);
          pop(tw);
      }
      return true;
  });

  def_reduce_vars(AST_LabeledStatement, function(tw) {
      push(tw);
      this.body.walk(tw);
      pop(tw);
      return true;
  });

  def_reduce_vars(AST_SymbolCatch, function() {
      this.definition().fixed = false;
  });

  def_reduce_vars(AST_SymbolRef, function(tw, descend, compressor) {
      var d = this.definition();
      d.references.push(this);
      if (d.references.length == 1
          && !d.fixed
          && d.orig[0] instanceof AST_SymbolDefun) {
          tw.loop_ids.set(d.id, tw.in_loop);
      }
      var fixed_value;
      if (d.fixed === undefined || !safe_to_read(tw, d)) {
          d.fixed = false;
      } else if (d.fixed) {
          fixed_value = this.fixed_value();
          if (
              fixed_value instanceof AST_Lambda
              && is_recursive_ref(tw, d)
          ) {
              d.recursive_refs++;
          } else if (fixed_value
              && !compressor.exposed(d)
              && ref_once(tw, compressor, d)
          ) {
              d.single_use =
                  fixed_value instanceof AST_Lambda && !fixed_value.pinned()
                  || fixed_value instanceof AST_Class
                  || d.scope === this.scope && fixed_value.is_constant_expression();
          } else {
              d.single_use = false;
          }
          if (is_modified(compressor, tw, this, fixed_value, 0, is_immutable(fixed_value))) {
              if (d.single_use) {
                  d.single_use = "m";
              } else {
                  d.fixed = false;
              }
          }
      }
      mark_escaped(tw, d, this.scope, this, fixed_value, 0, 1);
  });

  def_reduce_vars(AST_Toplevel, function(tw, descend, compressor) {
      this.globals.forEach(function(def) {
          reset_def(compressor, def);
      });
      reset_variables(tw, compressor, this);
  });

  def_reduce_vars(AST_Try, function(tw, descend, compressor) {
      reset_block_variables(compressor, this);
      push(tw);
      walk_body(this, tw);
      pop(tw);
      if (this.bcatch) {
          push(tw);
          this.bcatch.walk(tw);
          pop(tw);
      }
      if (this.bfinally) this.bfinally.walk(tw);
      return true;
  });

  def_reduce_vars(AST_Unary, function(tw) {
      var node = this;
      if (node.operator !== "++" && node.operator !== "--") return;
      var exp = node.expression;
      if (!(exp instanceof AST_SymbolRef)) return;
      var def = exp.definition();
      var safe = safe_to_assign(tw, def, exp.scope, true);
      def.assignments++;
      if (!safe) return;
      var fixed = def.fixed;
      if (!fixed) return;
      def.references.push(exp);
      def.chained = true;
      def.fixed = function() {
          return make_node(AST_Binary, node, {
              operator: node.operator.slice(0, -1),
              left: make_node(AST_UnaryPrefix, node, {
                  operator: "+",
                  expression: fixed instanceof AST_Node ? fixed : fixed()
              }),
              right: make_node(AST_Number, node, {
                  value: 1
              })
          });
      };
      mark(tw, def, true);
      return true;
  });

  def_reduce_vars(AST_VarDef, function(tw, descend) {
      var node = this;
      if (node.name instanceof AST_Destructuring) {
          suppress(node.name);
          return;
      }
      var d = node.name.definition();
      if (node.value) {
          if (safe_to_assign(tw, d, node.name.scope, node.value)) {
              d.fixed = function() {
                  return node.value;
              };
              tw.loop_ids.set(d.id, tw.in_loop);
              mark(tw, d, false);
              descend();
              mark(tw, d, true);
              return true;
          } else {
              d.fixed = false;
          }
      }
  });

  def_reduce_vars(AST_While, function(tw, descend, compressor) {
      reset_block_variables(compressor, this);
      const saved_loop = tw.in_loop;
      tw.in_loop = this;
      push(tw);
      descend();
      pop(tw);
      tw.in_loop = saved_loop;
      return true;
  });

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  function loop_body(x) {
      if (x instanceof AST_IterationStatement) {
          return x.body instanceof AST_BlockStatement ? x.body : x;
      }
      return x;
  }

  function is_lhs_read_only(lhs) {
      if (lhs instanceof AST_This) return true;
      if (lhs instanceof AST_SymbolRef) return lhs.definition().orig[0] instanceof AST_SymbolLambda;
      if (lhs instanceof AST_PropAccess) {
          lhs = lhs.expression;
          if (lhs instanceof AST_SymbolRef) {
              if (lhs.is_immutable()) return false;
              lhs = lhs.fixed_value();
          }
          if (!lhs) return true;
          if (lhs instanceof AST_RegExp) return false;
          if (lhs instanceof AST_Constant) return true;
          return is_lhs_read_only(lhs);
      }
      return false;
  }

  // Remove code which we know is unreachable.
  function trim_unreachable_code(compressor, stat, target) {
      walk(stat, node => {
          if (node instanceof AST_Var) {
              node.remove_initializers();
              target.push(node);
              return true;
          }
          if (
              node instanceof AST_Defun
              && (node === stat || !compressor.has_directive("use strict"))
          ) {
              target.push(node === stat ? node : make_node(AST_Var, node, {
                  definitions: [
                      make_node(AST_VarDef, node, {
                          name: make_node(AST_SymbolVar, node.name, node.name),
                          value: null
                      })
                  ]
              }));
              return true;
          }
          if (node instanceof AST_Export || node instanceof AST_Import) {
              target.push(node);
              return true;
          }
          if (node instanceof AST_Scope) {
              return true;
          }
      });
  }

  /** Tighten a bunch of statements together, and perform statement-level optimization. */
  function tighten_body(statements, compressor) {
      var in_loop, in_try;
      var scope = compressor.find_parent(AST_Scope).get_defun_scope();
      find_loop_scope_try();
      var CHANGED, max_iter = 10;
      do {
          CHANGED = false;
          eliminate_spurious_blocks(statements);
          if (compressor.option("dead_code")) {
              eliminate_dead_code(statements, compressor);
          }
          if (compressor.option("if_return")) {
              handle_if_return(statements, compressor);
          }
          if (compressor.sequences_limit > 0) {
              sequencesize(statements, compressor);
              sequencesize_2(statements, compressor);
          }
          if (compressor.option("join_vars")) {
              join_consecutive_vars(statements);
          }
          if (compressor.option("collapse_vars")) {
              collapse(statements, compressor);
          }
      } while (CHANGED && max_iter-- > 0);

      function find_loop_scope_try() {
          var node = compressor.self(), level = 0;
          do {
              if (node instanceof AST_Catch || node instanceof AST_Finally) {
                  level++;
              } else if (node instanceof AST_IterationStatement) {
                  in_loop = true;
              } else if (node instanceof AST_Scope) {
                  scope = node;
                  break;
              } else if (node instanceof AST_Try) {
                  in_try = true;
              }
          } while (node = compressor.parent(level++));
      }

      // Search from right to left for assignment-like expressions:
      // - `var a = x;`
      // - `a = x;`
      // - `++a`
      // For each candidate, scan from left to right for first usage, then try
      // to fold assignment into the site for compression.
      // Will not attempt to collapse assignments into or past code blocks
      // which are not sequentially executed, e.g. loops and conditionals.
      function collapse(statements, compressor) {
          if (scope.pinned())
              return statements;
          var args;
          var candidates = [];
          var stat_index = statements.length;
          var scanner = new TreeTransformer(function (node) {
              if (abort)
                  return node;
              // Skip nodes before `candidate` as quickly as possible
              if (!hit) {
                  if (node !== hit_stack[hit_index])
                      return node;
                  hit_index++;
                  if (hit_index < hit_stack.length)
                      return handle_custom_scan_order(node);
                  hit = true;
                  stop_after = find_stop(node, 0);
                  if (stop_after === node)
                      abort = true;
                  return node;
              }
              // Stop immediately if these node types are encountered
              var parent = scanner.parent();
              if (node instanceof AST_Assign
                      && (node.logical || node.operator != "=" && lhs.equivalent_to(node.left))
                  || node instanceof AST_Await
                  || node instanceof AST_Call && lhs instanceof AST_PropAccess && lhs.equivalent_to(node.expression)
                  || node instanceof AST_Debugger
                  || node instanceof AST_Destructuring
                  || node instanceof AST_Expansion
                      && node.expression instanceof AST_Symbol
                      && (
                          node.expression instanceof AST_This
                          || node.expression.definition().references.length > 1
                      )
                  || node instanceof AST_IterationStatement && !(node instanceof AST_For)
                  || node instanceof AST_LoopControl
                  || node instanceof AST_Try
                  || node instanceof AST_With
                  || node instanceof AST_Yield
                  || node instanceof AST_Export
                  || node instanceof AST_Class
                  || parent instanceof AST_For && node !== parent.init
                  || !replace_all
                      && (
                          node instanceof AST_SymbolRef
                          && !node.is_declared(compressor)
                          && !pure_prop_access_globals.has(node)
                      )
                  || node instanceof AST_SymbolRef
                      && parent instanceof AST_Call
                      && has_annotation(parent, _NOINLINE)
              ) {
                  abort = true;
                  return node;
              }
              // Stop only if candidate is found within conditional branches
              if (!stop_if_hit && (!lhs_local || !replace_all)
                  && (parent instanceof AST_Binary && lazy_op.has(parent.operator) && parent.left !== node
                      || parent instanceof AST_Conditional && parent.condition !== node
                      || parent instanceof AST_If && parent.condition !== node)) {
                  stop_if_hit = parent;
              }
              // Replace variable with assignment when found
              if (can_replace
                  && !(node instanceof AST_SymbolDeclaration)
                  && lhs.equivalent_to(node)
                  && !shadows(node.scope, lvalues)
              ) {
                  if (stop_if_hit) {
                      abort = true;
                      return node;
                  }
                  if (is_lhs(node, parent)) {
                      if (value_def)
                          replaced++;
                      return node;
                  } else {
                      replaced++;
                      if (value_def && candidate instanceof AST_VarDef)
                          return node;
                  }
                  CHANGED = abort = true;
                  if (candidate instanceof AST_UnaryPostfix) {
                      return make_node(AST_UnaryPrefix, candidate, candidate);
                  }
                  if (candidate instanceof AST_VarDef) {
                      var def = candidate.name.definition();
                      var value = candidate.value;
                      if (def.references.length - def.replaced == 1 && !compressor.exposed(def)) {
                          def.replaced++;
                          if (funarg && is_identifier_atom(value)) {
                              return value.transform(compressor);
                          } else {
                              return maintain_this_binding(parent, node, value);
                          }
                      }
                      return make_node(AST_Assign, candidate, {
                          operator: "=",
                          logical: false,
                          left: make_node(AST_SymbolRef, candidate.name, candidate.name),
                          right: value
                      });
                  }
                  clear_flag(candidate, WRITE_ONLY);
                  return candidate;
              }
              // These node types have child nodes that execute sequentially,
              // but are otherwise not safe to scan into or beyond them.
              var sym;
              if (node instanceof AST_Call
                  || node instanceof AST_Exit
                  && (side_effects || lhs instanceof AST_PropAccess || may_modify(lhs))
                  || node instanceof AST_PropAccess
                  && (side_effects || node.expression.may_throw_on_access(compressor))
                  || node instanceof AST_SymbolRef
                  && ((lvalues.has(node.name) && lvalues.get(node.name).modified) || side_effects && may_modify(node))
                  || node instanceof AST_VarDef && node.value
                  && (lvalues.has(node.name.name) || side_effects && may_modify(node.name))
                  || (sym = is_lhs(node.left, node))
                  && (sym instanceof AST_PropAccess || lvalues.has(sym.name))
                  || may_throw
                  && (in_try ? node.has_side_effects(compressor) : side_effects_external(node))) {
                  stop_after = node;
                  if (node instanceof AST_Scope)
                      abort = true;
              }
              return handle_custom_scan_order(node);
          }, function (node) {
              if (abort)
                  return;
              if (stop_after === node)
                  abort = true;
              if (stop_if_hit === node)
                  stop_if_hit = null;
          });

          var multi_replacer = new TreeTransformer(function (node) {
              if (abort)
                  return node;
              // Skip nodes before `candidate` as quickly as possible
              if (!hit) {
                  if (node !== hit_stack[hit_index])
                      return node;
                  hit_index++;
                  if (hit_index < hit_stack.length)
                      return;
                  hit = true;
                  return node;
              }
              // Replace variable when found
              if (node instanceof AST_SymbolRef
                  && node.name == def.name) {
                  if (!--replaced)
                      abort = true;
                  if (is_lhs(node, multi_replacer.parent()))
                      return node;
                  def.replaced++;
                  value_def.replaced--;
                  return candidate.value;
              }
              // Skip (non-executed) functions and (leading) default case in switch statements
              if (node instanceof AST_Default || node instanceof AST_Scope)
                  return node;
          });

          while (--stat_index >= 0) {
              // Treat parameters as collapsible in IIFE, i.e.
              //   function(a, b){ ... }(x());
              // would be translated into equivalent assignments:
              //   var a = x(), b = undefined;
              if (stat_index == 0 && compressor.option("unused"))
                  extract_args();
              // Find collapsible assignments
              var hit_stack = [];
              extract_candidates(statements[stat_index]);
              while (candidates.length > 0) {
                  hit_stack = candidates.pop();
                  var hit_index = 0;
                  var candidate = hit_stack[hit_stack.length - 1];
                  var value_def = null;
                  var stop_after = null;
                  var stop_if_hit = null;
                  var lhs = get_lhs(candidate);
                  if (!lhs || is_lhs_read_only(lhs) || lhs.has_side_effects(compressor))
                      continue;
                  // Locate symbols which may execute code outside of scanning range
                  var lvalues = get_lvalues(candidate);
                  var lhs_local = is_lhs_local(lhs);
                  if (lhs instanceof AST_SymbolRef) {
                      lvalues.set(lhs.name, { def: lhs.definition(), modified: false });
                  }
                  var side_effects = value_has_side_effects(candidate);
                  var replace_all = replace_all_symbols();
                  var may_throw = candidate.may_throw(compressor);
                  var funarg = candidate.name instanceof AST_SymbolFunarg;
                  var hit = funarg;
                  var abort = false, replaced = 0, can_replace = !args || !hit;
                  if (!can_replace) {
                      for (var j = compressor.self().argnames.lastIndexOf(candidate.name) + 1; !abort && j < args.length; j++) {
                          args[j].transform(scanner);
                      }
                      can_replace = true;
                  }
                  for (var i = stat_index; !abort && i < statements.length; i++) {
                      statements[i].transform(scanner);
                  }
                  if (value_def) {
                      var def = candidate.name.definition();
                      if (abort && def.references.length - def.replaced > replaced)
                          replaced = false;
                      else {
                          abort = false;
                          hit_index = 0;
                          hit = funarg;
                          for (var i = stat_index; !abort && i < statements.length; i++) {
                              statements[i].transform(multi_replacer);
                          }
                          value_def.single_use = false;
                      }
                  }
                  if (replaced && !remove_candidate(candidate))
                      statements.splice(stat_index, 1);
              }
          }

          function handle_custom_scan_order(node) {
              // Skip (non-executed) functions
              if (node instanceof AST_Scope)
                  return node;

              // Scan case expressions first in a switch statement
              if (node instanceof AST_Switch) {
                  node.expression = node.expression.transform(scanner);
                  for (var i = 0, len = node.body.length; !abort && i < len; i++) {
                      var branch = node.body[i];
                      if (branch instanceof AST_Case) {
                          if (!hit) {
                              if (branch !== hit_stack[hit_index])
                                  continue;
                              hit_index++;
                          }
                          branch.expression = branch.expression.transform(scanner);
                          if (!replace_all)
                              break;
                      }
                  }
                  abort = true;
                  return node;
              }
          }

          function redefined_within_scope(def, scope) {
              if (def.global)
                  return false;
              let cur_scope = def.scope;
              while (cur_scope && cur_scope !== scope) {
                  if (cur_scope.variables.has(def.name)) {
                      return true;
                  }
                  cur_scope = cur_scope.parent_scope;
              }
              return false;
          }

          function has_overlapping_symbol(fn, arg, fn_strict) {
              var found = false, scan_this = !(fn instanceof AST_Arrow);
              arg.walk(new TreeWalker(function (node, descend) {
                  if (found)
                      return true;
                  if (node instanceof AST_SymbolRef && (fn.variables.has(node.name) || redefined_within_scope(node.definition(), fn))) {
                      var s = node.definition().scope;
                      if (s !== scope)
                          while (s = s.parent_scope) {
                              if (s === scope)
                                  return true;
                          }
                      return found = true;
                  }
                  if ((fn_strict || scan_this) && node instanceof AST_This) {
                      return found = true;
                  }
                  if (node instanceof AST_Scope && !(node instanceof AST_Arrow)) {
                      var prev = scan_this;
                      scan_this = false;
                      descend();
                      scan_this = prev;
                      return true;
                  }
              }));
              return found;
          }

          function extract_args() {
              var iife, fn = compressor.self();
              if (is_func_expr(fn)
                  && !fn.name
                  && !fn.uses_arguments
                  && !fn.pinned()
                  && (iife = compressor.parent()) instanceof AST_Call
                  && iife.expression === fn
                  && iife.args.every((arg) => !(arg instanceof AST_Expansion))) {
                  var fn_strict = compressor.has_directive("use strict");
                  if (fn_strict && !member(fn_strict, fn.body))
                      fn_strict = false;
                  var len = fn.argnames.length;
                  args = iife.args.slice(len);
                  var names = new Set();
                  for (var i = len; --i >= 0;) {
                      var sym = fn.argnames[i];
                      var arg = iife.args[i];
                      // The following two line fix is a duplicate of the fix at
                      // https://github.com/terser/terser/commit/011d3eb08cefe6922c7d1bdfa113fc4aeaca1b75
                      // This might mean that these two pieces of code (one here in collapse_vars and another in reduce_vars
                      // Might be doing the exact same thing.
                      const def = sym.definition && sym.definition();
                      const is_reassigned = def && def.orig.length > 1;
                      if (is_reassigned)
                          continue;
                      args.unshift(make_node(AST_VarDef, sym, {
                          name: sym,
                          value: arg
                      }));
                      if (names.has(sym.name))
                          continue;
                      names.add(sym.name);
                      if (sym instanceof AST_Expansion) {
                          var elements = iife.args.slice(i);
                          if (elements.every((arg) => !has_overlapping_symbol(fn, arg, fn_strict)
                          )) {
                              candidates.unshift([make_node(AST_VarDef, sym, {
                                  name: sym.expression,
                                  value: make_node(AST_Array, iife, {
                                      elements: elements
                                  })
                              })]);
                          }
                      } else {
                          if (!arg) {
                              arg = make_node(AST_Undefined, sym).transform(compressor);
                          } else if (arg instanceof AST_Lambda && arg.pinned()
                              || has_overlapping_symbol(fn, arg, fn_strict)) {
                              arg = null;
                          }
                          if (arg)
                              candidates.unshift([make_node(AST_VarDef, sym, {
                                  name: sym,
                                  value: arg
                              })]);
                      }
                  }
              }
          }

          function extract_candidates(expr) {
              hit_stack.push(expr);
              if (expr instanceof AST_Assign) {
                  if (!expr.left.has_side_effects(compressor)
                      && !(expr.right instanceof AST_Chain)) {
                      candidates.push(hit_stack.slice());
                  }
                  extract_candidates(expr.right);
              } else if (expr instanceof AST_Binary) {
                  extract_candidates(expr.left);
                  extract_candidates(expr.right);
              } else if (expr instanceof AST_Call && !has_annotation(expr, _NOINLINE)) {
                  extract_candidates(expr.expression);
                  expr.args.forEach(extract_candidates);
              } else if (expr instanceof AST_Case) {
                  extract_candidates(expr.expression);
              } else if (expr instanceof AST_Conditional) {
                  extract_candidates(expr.condition);
                  extract_candidates(expr.consequent);
                  extract_candidates(expr.alternative);
              } else if (expr instanceof AST_Definitions) {
                  var len = expr.definitions.length;
                  // limit number of trailing variable definitions for consideration
                  var i = len - 200;
                  if (i < 0)
                      i = 0;
                  for (; i < len; i++) {
                      extract_candidates(expr.definitions[i]);
                  }
              } else if (expr instanceof AST_DWLoop) {
                  extract_candidates(expr.condition);
                  if (!(expr.body instanceof AST_Block)) {
                      extract_candidates(expr.body);
                  }
              } else if (expr instanceof AST_Exit) {
                  if (expr.value)
                      extract_candidates(expr.value);
              } else if (expr instanceof AST_For) {
                  if (expr.init)
                      extract_candidates(expr.init);
                  if (expr.condition)
                      extract_candidates(expr.condition);
                  if (expr.step)
                      extract_candidates(expr.step);
                  if (!(expr.body instanceof AST_Block)) {
                      extract_candidates(expr.body);
                  }
              } else if (expr instanceof AST_ForIn) {
                  extract_candidates(expr.object);
                  if (!(expr.body instanceof AST_Block)) {
                      extract_candidates(expr.body);
                  }
              } else if (expr instanceof AST_If) {
                  extract_candidates(expr.condition);
                  if (!(expr.body instanceof AST_Block)) {
                      extract_candidates(expr.body);
                  }
                  if (expr.alternative && !(expr.alternative instanceof AST_Block)) {
                      extract_candidates(expr.alternative);
                  }
              } else if (expr instanceof AST_Sequence) {
                  expr.expressions.forEach(extract_candidates);
              } else if (expr instanceof AST_SimpleStatement) {
                  extract_candidates(expr.body);
              } else if (expr instanceof AST_Switch) {
                  extract_candidates(expr.expression);
                  expr.body.forEach(extract_candidates);
              } else if (expr instanceof AST_Unary) {
                  if (expr.operator == "++" || expr.operator == "--") {
                      candidates.push(hit_stack.slice());
                  }
              } else if (expr instanceof AST_VarDef) {
                  if (expr.value && !(expr.value instanceof AST_Chain)) {
                      candidates.push(hit_stack.slice());
                      extract_candidates(expr.value);
                  }
              }
              hit_stack.pop();
          }

          function find_stop(node, level, write_only) {
              var parent = scanner.parent(level);
              if (parent instanceof AST_Assign) {
                  if (write_only
                      && !parent.logical
                      && !(parent.left instanceof AST_PropAccess
                          || lvalues.has(parent.left.name))) {
                      return find_stop(parent, level + 1, write_only);
                  }
                  return node;
              }
              if (parent instanceof AST_Binary) {
                  if (write_only && (!lazy_op.has(parent.operator) || parent.left === node)) {
                      return find_stop(parent, level + 1, write_only);
                  }
                  return node;
              }
              if (parent instanceof AST_Call)
                  return node;
              if (parent instanceof AST_Case)
                  return node;
              if (parent instanceof AST_Conditional) {
                  if (write_only && parent.condition === node) {
                      return find_stop(parent, level + 1, write_only);
                  }
                  return node;
              }
              if (parent instanceof AST_Definitions) {
                  return find_stop(parent, level + 1, true);
              }
              if (parent instanceof AST_Exit) {
                  return write_only ? find_stop(parent, level + 1, write_only) : node;
              }
              if (parent instanceof AST_If) {
                  if (write_only && parent.condition === node) {
                      return find_stop(parent, level + 1, write_only);
                  }
                  return node;
              }
              if (parent instanceof AST_IterationStatement)
                  return node;
              if (parent instanceof AST_Sequence) {
                  return find_stop(parent, level + 1, parent.tail_node() !== node);
              }
              if (parent instanceof AST_SimpleStatement) {
                  return find_stop(parent, level + 1, true);
              }
              if (parent instanceof AST_Switch)
                  return node;
              if (parent instanceof AST_VarDef)
                  return node;
              return null;
          }

          function mangleable_var(var_def) {
              var value = var_def.value;
              if (!(value instanceof AST_SymbolRef))
                  return;
              if (value.name == "arguments")
                  return;
              var def = value.definition();
              if (def.undeclared)
                  return;
              return value_def = def;
          }

          function get_lhs(expr) {
              if (expr instanceof AST_Assign && expr.logical) {
                  return false;
              } else if (expr instanceof AST_VarDef && expr.name instanceof AST_SymbolDeclaration) {
                  var def = expr.name.definition();
                  if (!member(expr.name, def.orig))
                      return;
                  var referenced = def.references.length - def.replaced;
                  if (!referenced)
                      return;
                  var declared = def.orig.length - def.eliminated;
                  if (declared > 1 && !(expr.name instanceof AST_SymbolFunarg)
                      || (referenced > 1 ? mangleable_var(expr) : !compressor.exposed(def))) {
                      return make_node(AST_SymbolRef, expr.name, expr.name);
                  }
              } else {
                  const lhs = expr instanceof AST_Assign
                      ? expr.left
                      : expr.expression;
                  return !is_ref_of(lhs, AST_SymbolConst)
                      && !is_ref_of(lhs, AST_SymbolLet) && lhs;
              }
          }

          function get_rvalue(expr) {
              if (expr instanceof AST_Assign) {
                  return expr.right;
              } else {
                  return expr.value;
              }
          }

          function get_lvalues(expr) {
              var lvalues = new Map();
              if (expr instanceof AST_Unary)
                  return lvalues;
              var tw = new TreeWalker(function (node) {
                  var sym = node;
                  while (sym instanceof AST_PropAccess)
                      sym = sym.expression;
                  if (sym instanceof AST_SymbolRef) {
                      const prev = lvalues.get(sym.name);
                      if (!prev || !prev.modified) {
                          lvalues.set(sym.name, {
                              def: sym.definition(),
                              modified: is_modified(compressor, tw, node, node, 0)
                          });
                      }
                  }
              });
              get_rvalue(expr).walk(tw);
              return lvalues;
          }

          function remove_candidate(expr) {
              if (expr.name instanceof AST_SymbolFunarg) {
                  var iife = compressor.parent(), argnames = compressor.self().argnames;
                  var index = argnames.indexOf(expr.name);
                  if (index < 0) {
                      iife.args.length = Math.min(iife.args.length, argnames.length - 1);
                  } else {
                      var args = iife.args;
                      if (args[index])
                          args[index] = make_node(AST_Number, args[index], {
                              value: 0
                          });
                  }
                  return true;
              }
              var found = false;
              return statements[stat_index].transform(new TreeTransformer(function (node, descend, in_list) {
                  if (found)
                      return node;
                  if (node === expr || node.body === expr) {
                      found = true;
                      if (node instanceof AST_VarDef) {
                          node.value = node.name instanceof AST_SymbolConst
                              ? make_node(AST_Undefined, node.value) // `const` always needs value.
                              : null;
                          return node;
                      }
                      return in_list ? MAP.skip : null;
                  }
              }, function (node) {
                  if (node instanceof AST_Sequence)
                      switch (node.expressions.length) {
                          case 0: return null;
                          case 1: return node.expressions[0];
                      }
              }));
          }

          function is_lhs_local(lhs) {
              while (lhs instanceof AST_PropAccess)
                  lhs = lhs.expression;
              return lhs instanceof AST_SymbolRef
                  && lhs.definition().scope === scope
                  && !(in_loop
                      && (lvalues.has(lhs.name)
                          || candidate instanceof AST_Unary
                          || (candidate instanceof AST_Assign
                              && !candidate.logical
                              && candidate.operator != "=")));
          }

          function value_has_side_effects(expr) {
              if (expr instanceof AST_Unary)
                  return unary_side_effects.has(expr.operator);
              return get_rvalue(expr).has_side_effects(compressor);
          }

          function replace_all_symbols() {
              if (side_effects)
                  return false;
              if (value_def)
                  return true;
              if (lhs instanceof AST_SymbolRef) {
                  var def = lhs.definition();
                  if (def.references.length - def.replaced == (candidate instanceof AST_VarDef ? 1 : 2)) {
                      return true;
                  }
              }
              return false;
          }

          function may_modify(sym) {
              if (!sym.definition)
                  return true; // AST_Destructuring
              var def = sym.definition();
              if (def.orig.length == 1 && def.orig[0] instanceof AST_SymbolDefun)
                  return false;
              if (def.scope.get_defun_scope() !== scope)
                  return true;
              return !def.references.every((ref) => {
                  var s = ref.scope.get_defun_scope();
                  // "block" scope within AST_Catch
                  if (s.TYPE == "Scope")
                      s = s.parent_scope;
                  return s === scope;
              });
          }

          function side_effects_external(node, lhs) {
              if (node instanceof AST_Assign)
                  return side_effects_external(node.left, true);
              if (node instanceof AST_Unary)
                  return side_effects_external(node.expression, true);
              if (node instanceof AST_VarDef)
                  return node.value && side_effects_external(node.value);
              if (lhs) {
                  if (node instanceof AST_Dot)
                      return side_effects_external(node.expression, true);
                  if (node instanceof AST_Sub)
                      return side_effects_external(node.expression, true);
                  if (node instanceof AST_SymbolRef)
                      return node.definition().scope !== scope;
              }
              return false;
          }

          function shadows(newScope, lvalues) {
              for (const {def} of lvalues.values()) {
                  let current = newScope;
                  while (current && current !== def.scope) {
                      let nested_def = current.variables.get(def.name);
                      if (nested_def && nested_def !== def) return true;
                      current = current.parent_scope;
                  }
              }
              return false;
          }
      }

      function eliminate_spurious_blocks(statements) {
          var seen_dirs = [];
          for (var i = 0; i < statements.length;) {
              var stat = statements[i];
              if (stat instanceof AST_BlockStatement && stat.body.every(can_be_evicted_from_block)) {
                  CHANGED = true;
                  eliminate_spurious_blocks(stat.body);
                  statements.splice(i, 1, ...stat.body);
                  i += stat.body.length;
              } else if (stat instanceof AST_EmptyStatement) {
                  CHANGED = true;
                  statements.splice(i, 1);
              } else if (stat instanceof AST_Directive) {
                  if (seen_dirs.indexOf(stat.value) < 0) {
                      i++;
                      seen_dirs.push(stat.value);
                  } else {
                      CHANGED = true;
                      statements.splice(i, 1);
                  }
              } else
                  i++;
          }
      }

      function handle_if_return(statements, compressor) {
          var self = compressor.self();
          var multiple_if_returns = has_multiple_if_returns(statements);
          var in_lambda = self instanceof AST_Lambda;
          for (var i = statements.length; --i >= 0;) {
              var stat = statements[i];
              var j = next_index(i);
              var next = statements[j];

              if (in_lambda && !next && stat instanceof AST_Return) {
                  if (!stat.value) {
                      CHANGED = true;
                      statements.splice(i, 1);
                      continue;
                  }
                  if (stat.value instanceof AST_UnaryPrefix && stat.value.operator == "void") {
                      CHANGED = true;
                      statements[i] = make_node(AST_SimpleStatement, stat, {
                          body: stat.value.expression
                      });
                      continue;
                  }
              }

              if (stat instanceof AST_If) {
                  var ab = aborts(stat.body);
                  if (can_merge_flow(ab)) {
                      if (ab.label) {
                          remove(ab.label.thedef.references, ab);
                      }
                      CHANGED = true;
                      stat = stat.clone();
                      stat.condition = stat.condition.negate(compressor);
                      var body = as_statement_array_with_return(stat.body, ab);
                      stat.body = make_node(AST_BlockStatement, stat, {
                          body: as_statement_array(stat.alternative).concat(extract_functions())
                      });
                      stat.alternative = make_node(AST_BlockStatement, stat, {
                          body: body
                      });
                      statements[i] = stat.transform(compressor);
                      continue;
                  }

                  var ab = aborts(stat.alternative);
                  if (can_merge_flow(ab)) {
                      if (ab.label) {
                          remove(ab.label.thedef.references, ab);
                      }
                      CHANGED = true;
                      stat = stat.clone();
                      stat.body = make_node(AST_BlockStatement, stat.body, {
                          body: as_statement_array(stat.body).concat(extract_functions())
                      });
                      var body = as_statement_array_with_return(stat.alternative, ab);
                      stat.alternative = make_node(AST_BlockStatement, stat.alternative, {
                          body: body
                      });
                      statements[i] = stat.transform(compressor);
                      continue;
                  }
              }

              if (stat instanceof AST_If && stat.body instanceof AST_Return) {
                  var value = stat.body.value;
                  //---
                  // pretty silly case, but:
                  // if (foo()) return; return; ==> foo(); return;
                  if (!value && !stat.alternative
                      && (in_lambda && !next || next instanceof AST_Return && !next.value)) {
                      CHANGED = true;
                      statements[i] = make_node(AST_SimpleStatement, stat.condition, {
                          body: stat.condition
                      });
                      continue;
                  }
                  //---
                  // if (foo()) return x; return y; ==> return foo() ? x : y;
                  if (value && !stat.alternative && next instanceof AST_Return && next.value) {
                      CHANGED = true;
                      stat = stat.clone();
                      stat.alternative = next;
                      statements[i] = stat.transform(compressor);
                      statements.splice(j, 1);
                      continue;
                  }
                  //---
                  // if (foo()) return x; [ return ; ] ==> return foo() ? x : undefined;
                  if (value && !stat.alternative
                      && (!next && in_lambda && multiple_if_returns
                          || next instanceof AST_Return)) {
                      CHANGED = true;
                      stat = stat.clone();
                      stat.alternative = next || make_node(AST_Return, stat, {
                          value: null
                      });
                      statements[i] = stat.transform(compressor);
                      if (next)
                          statements.splice(j, 1);
                      continue;
                  }
                  //---
                  // if (a) return b; if (c) return d; e; ==> return a ? b : c ? d : void e;
                  //
                  // if sequences is not enabled, this can lead to an endless loop (issue #866).
                  // however, with sequences on this helps producing slightly better output for
                  // the example code.
                  var prev = statements[prev_index(i)];
                  if (compressor.option("sequences") && in_lambda && !stat.alternative
                      && prev instanceof AST_If && prev.body instanceof AST_Return
                      && next_index(j) == statements.length && next instanceof AST_SimpleStatement) {
                      CHANGED = true;
                      stat = stat.clone();
                      stat.alternative = make_node(AST_BlockStatement, next, {
                          body: [
                              next,
                              make_node(AST_Return, next, {
                                  value: null
                              })
                          ]
                      });
                      statements[i] = stat.transform(compressor);
                      statements.splice(j, 1);
                      continue;
                  }
              }
          }

          function has_multiple_if_returns(statements) {
              var n = 0;
              for (var i = statements.length; --i >= 0;) {
                  var stat = statements[i];
                  if (stat instanceof AST_If && stat.body instanceof AST_Return) {
                      if (++n > 1)
                          return true;
                  }
              }
              return false;
          }

          function is_return_void(value) {
              return !value || value instanceof AST_UnaryPrefix && value.operator == "void";
          }

          function can_merge_flow(ab) {
              if (!ab)
                  return false;
              for (var j = i + 1, len = statements.length; j < len; j++) {
                  var stat = statements[j];
                  if (stat instanceof AST_Const || stat instanceof AST_Let)
                      return false;
              }
              var lct = ab instanceof AST_LoopControl ? compressor.loopcontrol_target(ab) : null;
              return ab instanceof AST_Return && in_lambda && is_return_void(ab.value)
                  || ab instanceof AST_Continue && self === loop_body(lct)
                  || ab instanceof AST_Break && lct instanceof AST_BlockStatement && self === lct;
          }

          function extract_functions() {
              var tail = statements.slice(i + 1);
              statements.length = i + 1;
              return tail.filter(function (stat) {
                  if (stat instanceof AST_Defun) {
                      statements.push(stat);
                      return false;
                  }
                  return true;
              });
          }

          function as_statement_array_with_return(node, ab) {
              var body = as_statement_array(node).slice(0, -1);
              if (ab.value) {
                  body.push(make_node(AST_SimpleStatement, ab.value, {
                      body: ab.value.expression
                  }));
              }
              return body;
          }

          function next_index(i) {
              for (var j = i + 1, len = statements.length; j < len; j++) {
                  var stat = statements[j];
                  if (!(stat instanceof AST_Var && declarations_only(stat))) {
                      break;
                  }
              }
              return j;
          }

          function prev_index(i) {
              for (var j = i; --j >= 0;) {
                  var stat = statements[j];
                  if (!(stat instanceof AST_Var && declarations_only(stat))) {
                      break;
                  }
              }
              return j;
          }
      }

      function eliminate_dead_code(statements, compressor) {
          var has_quit;
          var self = compressor.self();
          for (var i = 0, n = 0, len = statements.length; i < len; i++) {
              var stat = statements[i];
              if (stat instanceof AST_LoopControl) {
                  var lct = compressor.loopcontrol_target(stat);
                  if (stat instanceof AST_Break
                      && !(lct instanceof AST_IterationStatement)
                      && loop_body(lct) === self
                      || stat instanceof AST_Continue
                      && loop_body(lct) === self) {
                      if (stat.label) {
                          remove(stat.label.thedef.references, stat);
                      }
                  } else {
                      statements[n++] = stat;
                  }
              } else {
                  statements[n++] = stat;
              }
              if (aborts(stat)) {
                  has_quit = statements.slice(i + 1);
                  break;
              }
          }
          statements.length = n;
          CHANGED = n != len;
          if (has_quit)
              has_quit.forEach(function (stat) {
                  trim_unreachable_code(compressor, stat, statements);
              });
      }

      function declarations_only(node) {
          return node.definitions.every((var_def) => !var_def.value
          );
      }

      function sequencesize(statements, compressor) {
          if (statements.length < 2)
              return;
          var seq = [], n = 0;
          function push_seq() {
              if (!seq.length)
                  return;
              var body = make_sequence(seq[0], seq);
              statements[n++] = make_node(AST_SimpleStatement, body, { body: body });
              seq = [];
          }
          for (var i = 0, len = statements.length; i < len; i++) {
              var stat = statements[i];
              if (stat instanceof AST_SimpleStatement) {
                  if (seq.length >= compressor.sequences_limit)
                      push_seq();
                  var body = stat.body;
                  if (seq.length > 0)
                      body = body.drop_side_effect_free(compressor);
                  if (body)
                      merge_sequence(seq, body);
              } else if (stat instanceof AST_Definitions && declarations_only(stat)
                  || stat instanceof AST_Defun) {
                  statements[n++] = stat;
              } else {
                  push_seq();
                  statements[n++] = stat;
              }
          }
          push_seq();
          statements.length = n;
          if (n != len)
              CHANGED = true;
      }

      function to_simple_statement(block, decls) {
          if (!(block instanceof AST_BlockStatement))
              return block;
          var stat = null;
          for (var i = 0, len = block.body.length; i < len; i++) {
              var line = block.body[i];
              if (line instanceof AST_Var && declarations_only(line)) {
                  decls.push(line);
              } else if (stat) {
                  return false;
              } else {
                  stat = line;
              }
          }
          return stat;
      }

      function sequencesize_2(statements, compressor) {
          function cons_seq(right) {
              n--;
              CHANGED = true;
              var left = prev.body;
              return make_sequence(left, [left, right]).transform(compressor);
          }
          var n = 0, prev;
          for (var i = 0; i < statements.length; i++) {
              var stat = statements[i];
              if (prev) {
                  if (stat instanceof AST_Exit) {
                      stat.value = cons_seq(stat.value || make_node(AST_Undefined, stat).transform(compressor));
                  } else if (stat instanceof AST_For) {
                      if (!(stat.init instanceof AST_Definitions)) {
                          const abort = walk(prev.body, node => {
                              if (node instanceof AST_Scope)
                                  return true;
                              if (node instanceof AST_Binary
                                  && node.operator === "in") {
                                  return walk_abort;
                              }
                          });
                          if (!abort) {
                              if (stat.init)
                                  stat.init = cons_seq(stat.init);
                              else {
                                  stat.init = prev.body;
                                  n--;
                                  CHANGED = true;
                              }
                          }
                      }
                  } else if (stat instanceof AST_ForIn) {
                      if (!(stat.init instanceof AST_Const) && !(stat.init instanceof AST_Let)) {
                          stat.object = cons_seq(stat.object);
                      }
                  } else if (stat instanceof AST_If) {
                      stat.condition = cons_seq(stat.condition);
                  } else if (stat instanceof AST_Switch) {
                      stat.expression = cons_seq(stat.expression);
                  } else if (stat instanceof AST_With) {
                      stat.expression = cons_seq(stat.expression);
                  }
              }
              if (compressor.option("conditionals") && stat instanceof AST_If) {
                  var decls = [];
                  var body = to_simple_statement(stat.body, decls);
                  var alt = to_simple_statement(stat.alternative, decls);
                  if (body !== false && alt !== false && decls.length > 0) {
                      var len = decls.length;
                      decls.push(make_node(AST_If, stat, {
                          condition: stat.condition,
                          body: body || make_node(AST_EmptyStatement, stat.body),
                          alternative: alt
                      }));
                      decls.unshift(n, 1);
                      [].splice.apply(statements, decls);
                      i += len;
                      n += len + 1;
                      prev = null;
                      CHANGED = true;
                      continue;
                  }
              }
              statements[n++] = stat;
              prev = stat instanceof AST_SimpleStatement ? stat : null;
          }
          statements.length = n;
      }

      function join_object_assignments(defn, body) {
          if (!(defn instanceof AST_Definitions))
              return;
          var def = defn.definitions[defn.definitions.length - 1];
          if (!(def.value instanceof AST_Object))
              return;
          var exprs;
          if (body instanceof AST_Assign && !body.logical) {
              exprs = [body];
          } else if (body instanceof AST_Sequence) {
              exprs = body.expressions.slice();
          }
          if (!exprs)
              return;
          var trimmed = false;
          do {
              var node = exprs[0];
              if (!(node instanceof AST_Assign))
                  break;
              if (node.operator != "=")
                  break;
              if (!(node.left instanceof AST_PropAccess))
                  break;
              var sym = node.left.expression;
              if (!(sym instanceof AST_SymbolRef))
                  break;
              if (def.name.name != sym.name)
                  break;
              if (!node.right.is_constant_expression(scope))
                  break;
              var prop = node.left.property;
              if (prop instanceof AST_Node) {
                  prop = prop.evaluate(compressor);
              }
              if (prop instanceof AST_Node)
                  break;
              prop = "" + prop;
              var diff = compressor.option("ecma") < 2015
                  && compressor.has_directive("use strict") ? function (node) {
                      return node.key != prop && (node.key && node.key.name != prop);
                  } : function (node) {
                      return node.key && node.key.name != prop;
                  };
              if (!def.value.properties.every(diff))
                  break;
              var p = def.value.properties.filter(function (p) { return p.key === prop; })[0];
              if (!p) {
                  def.value.properties.push(make_node(AST_ObjectKeyVal, node, {
                      key: prop,
                      value: node.right
                  }));
              } else {
                  p.value = new AST_Sequence({
                      start: p.start,
                      expressions: [p.value.clone(), node.right.clone()],
                      end: p.end
                  });
              }
              exprs.shift();
              trimmed = true;
          } while (exprs.length);
          return trimmed && exprs;
      }

      function join_consecutive_vars(statements) {
          var defs;
          for (var i = 0, j = -1, len = statements.length; i < len; i++) {
              var stat = statements[i];
              var prev = statements[j];
              if (stat instanceof AST_Definitions) {
                  if (prev && prev.TYPE == stat.TYPE) {
                      prev.definitions = prev.definitions.concat(stat.definitions);
                      CHANGED = true;
                  } else if (defs && defs.TYPE == stat.TYPE && declarations_only(stat)) {
                      defs.definitions = defs.definitions.concat(stat.definitions);
                      CHANGED = true;
                  } else {
                      statements[++j] = stat;
                      defs = stat;
                  }
              } else if (stat instanceof AST_Exit) {
                  stat.value = extract_object_assignments(stat.value);
              } else if (stat instanceof AST_For) {
                  var exprs = join_object_assignments(prev, stat.init);
                  if (exprs) {
                      CHANGED = true;
                      stat.init = exprs.length ? make_sequence(stat.init, exprs) : null;
                      statements[++j] = stat;
                  } else if (prev instanceof AST_Var && (!stat.init || stat.init.TYPE == prev.TYPE)) {
                      if (stat.init) {
                          prev.definitions = prev.definitions.concat(stat.init.definitions);
                      }
                      stat.init = prev;
                      statements[j] = stat;
                      CHANGED = true;
                  } else if (defs && stat.init && defs.TYPE == stat.init.TYPE && declarations_only(stat.init)) {
                      defs.definitions = defs.definitions.concat(stat.init.definitions);
                      stat.init = null;
                      statements[++j] = stat;
                      CHANGED = true;
                  } else {
                      statements[++j] = stat;
                  }
              } else if (stat instanceof AST_ForIn) {
                  stat.object = extract_object_assignments(stat.object);
              } else if (stat instanceof AST_If) {
                  stat.condition = extract_object_assignments(stat.condition);
              } else if (stat instanceof AST_SimpleStatement) {
                  var exprs = join_object_assignments(prev, stat.body);
                  if (exprs) {
                      CHANGED = true;
                      if (!exprs.length)
                          continue;
                      stat.body = make_sequence(stat.body, exprs);
                  }
                  statements[++j] = stat;
              } else if (stat instanceof AST_Switch) {
                  stat.expression = extract_object_assignments(stat.expression);
              } else if (stat instanceof AST_With) {
                  stat.expression = extract_object_assignments(stat.expression);
              } else {
                  statements[++j] = stat;
              }
          }
          statements.length = j + 1;

          function extract_object_assignments(value) {
              statements[++j] = stat;
              var exprs = join_object_assignments(prev, value);
              if (exprs) {
                  CHANGED = true;
                  if (exprs.length) {
                      return make_sequence(value, exprs);
                  } else if (value instanceof AST_Sequence) {
                      return value.tail_node().left;
                  } else {
                      return value.left;
                  }
              }
              return value;
          }
      }
  }

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/


  function within_array_or_object_literal(compressor) {
      var node, level = 0;
      while (node = compressor.parent(level++)) {
          if (node instanceof AST_Statement) return false;
          if (node instanceof AST_Array
              || node instanceof AST_ObjectKeyVal
              || node instanceof AST_Object) {
              return true;
          }
      }
      return false;
  }

  function scope_encloses_variables_in_this_scope(scope, pulled_scope) {
      for (const enclosed of pulled_scope.enclosed) {
          if (pulled_scope.variables.has(enclosed.name)) {
              continue;
          }
          const looked_up = scope.find_variable(enclosed.name);
          if (looked_up) {
              if (looked_up === enclosed) continue;
              return true;
          }
      }
      return false;
  }

  function inline_into_symbolref(self, compressor) {
      if (
          !compressor.option("ie8")
          && is_undeclared_ref(self)
          && !compressor.find_parent(AST_With)
      ) {
          switch (self.name) {
            case "undefined":
              return make_node(AST_Undefined, self).optimize(compressor);
            case "NaN":
              return make_node(AST_NaN, self).optimize(compressor);
            case "Infinity":
              return make_node(AST_Infinity, self).optimize(compressor);
          }
      }

      const parent = compressor.parent();
      if (compressor.option("reduce_vars") && is_lhs(self, parent) !== self) {
          const def = self.definition();
          const nearest_scope = compressor.find_scope();
          if (compressor.top_retain && def.global && compressor.top_retain(def)) {
              def.fixed = false;
              def.single_use = false;
              return self;
          }

          let fixed = self.fixed_value();
          let single_use = def.single_use
              && !(parent instanceof AST_Call
                  && (parent.is_callee_pure(compressor))
                      || has_annotation(parent, _NOINLINE))
              && !(parent instanceof AST_Export
                  && fixed instanceof AST_Lambda
                  && fixed.name);

          if (single_use && fixed instanceof AST_Node) {
              single_use =
                  !fixed.has_side_effects(compressor)
                  && !fixed.may_throw(compressor);
          }

          if (single_use && (fixed instanceof AST_Lambda || fixed instanceof AST_Class)) {
              if (retain_top_func(fixed, compressor)) {
                  single_use = false;
              } else if (def.scope !== self.scope
                  && (def.escaped == 1
                      || has_flag(fixed, INLINED)
                      || within_array_or_object_literal(compressor)
                      || !compressor.option("reduce_funcs"))) {
                  single_use = false;
              } else if (is_recursive_ref(compressor, def)) {
                  single_use = false;
              } else if (def.scope !== self.scope || def.orig[0] instanceof AST_SymbolFunarg) {
                  single_use = fixed.is_constant_expression(self.scope);
                  if (single_use == "f") {
                      var scope = self.scope;
                      do {
                          if (scope instanceof AST_Defun || is_func_expr(scope)) {
                              set_flag(scope, INLINED);
                          }
                      } while (scope = scope.parent_scope);
                  }
              }
          }

          if (single_use && fixed instanceof AST_Lambda) {
              single_use =
                  def.scope === self.scope
                      && !scope_encloses_variables_in_this_scope(nearest_scope, fixed)
                  || parent instanceof AST_Call
                      && parent.expression === self
                      && !scope_encloses_variables_in_this_scope(nearest_scope, fixed)
                      && !(fixed.name && fixed.name.definition().recursive_refs > 0);
          }

          if (single_use && fixed) {
              if (fixed instanceof AST_DefClass) {
                  set_flag(fixed, SQUEEZED);
                  fixed = make_node(AST_ClassExpression, fixed, fixed);
              }
              if (fixed instanceof AST_Defun) {
                  set_flag(fixed, SQUEEZED);
                  fixed = make_node(AST_Function, fixed, fixed);
              }
              if (def.recursive_refs > 0 && fixed.name instanceof AST_SymbolDefun) {
                  const defun_def = fixed.name.definition();
                  let lambda_def = fixed.variables.get(fixed.name.name);
                  let name = lambda_def && lambda_def.orig[0];
                  if (!(name instanceof AST_SymbolLambda)) {
                      name = make_node(AST_SymbolLambda, fixed.name, fixed.name);
                      name.scope = fixed;
                      fixed.name = name;
                      lambda_def = fixed.def_function(name);
                  }
                  walk(fixed, node => {
                      if (node instanceof AST_SymbolRef && node.definition() === defun_def) {
                          node.thedef = lambda_def;
                          lambda_def.references.push(node);
                      }
                  });
              }
              if (
                  (fixed instanceof AST_Lambda || fixed instanceof AST_Class)
                  && fixed.parent_scope !== nearest_scope
              ) {
                  fixed = fixed.clone(true, compressor.get_toplevel());

                  nearest_scope.add_child_scope(fixed);
              }
              return fixed.optimize(compressor);
          }

          // multiple uses
          if (fixed) {
              let replace;

              if (fixed instanceof AST_This) {
                  if (!(def.orig[0] instanceof AST_SymbolFunarg)
                      && def.references.every((ref) =>
                          def.scope === ref.scope
                      )) {
                      replace = fixed;
                  }
              } else {
                  var ev = fixed.evaluate(compressor);
                  if (
                      ev !== fixed
                      && (compressor.option("unsafe_regexp") || !(ev instanceof RegExp))
                  ) {
                      replace = make_node_from_constant(ev, fixed);
                  }
              }

              if (replace) {
                  const name_length = self.size(compressor);
                  const replace_size = replace.size(compressor);

                  let overhead = 0;
                  if (compressor.option("unused") && !compressor.exposed(def)) {
                      overhead =
                          (name_length + 2 + replace_size) /
                          (def.references.length - def.assignments);
                  }

                  if (replace_size <= name_length + overhead) {
                      return replace;
                  }
              }
          }
      }

      return self;
  }

  function inline_into_call(self, fn, compressor) {
      var exp = self.expression;
      var simple_args = self.args.every((arg) => !(arg instanceof AST_Expansion));

      if (compressor.option("reduce_vars")
          && fn instanceof AST_SymbolRef
          && !has_annotation(self, _NOINLINE)
      ) {
          const fixed = fn.fixed_value();
          if (!retain_top_func(fixed, compressor)) {
              fn = fixed;
          }
      }

      var is_func = fn instanceof AST_Lambda;

      var stat = is_func && fn.body[0];
      var is_regular_func = is_func && !fn.is_generator && !fn.async;
      var can_inline = is_regular_func && compressor.option("inline") && !self.is_callee_pure(compressor);
      if (can_inline && stat instanceof AST_Return) {
          let returned = stat.value;
          if (!returned || returned.is_constant_expression()) {
              if (returned) {
                  returned = returned.clone(true);
              } else {
                  returned = make_node(AST_Undefined, self);
              }
              const args = self.args.concat(returned);
              return make_sequence(self, args).optimize(compressor);
          }

          // optimize identity function
          if (
              fn.argnames.length === 1
              && (fn.argnames[0] instanceof AST_SymbolFunarg)
              && self.args.length < 2
              && returned instanceof AST_SymbolRef
              && returned.name === fn.argnames[0].name
          ) {
              const replacement =
                  (self.args[0] || make_node(AST_Undefined)).optimize(compressor);

              let parent;
              if (
                  replacement instanceof AST_PropAccess
                  && (parent = compressor.parent()) instanceof AST_Call
                  && parent.expression === self
              ) {
                  // identity function was being used to remove `this`, like in
                  //
                  // id(bag.no_this)(...)
                  //
                  // Replace with a larger but more effish (0, bag.no_this) wrapper.

                  return make_sequence(self, [
                      make_node(AST_Number, self, { value: 0 }),
                      replacement
                  ]);
              }
              // replace call with first argument or undefined if none passed
              return replacement;
          }
      }

      if (can_inline) {
          var scope, in_loop, level = -1;
          let def;
          let returned_value;
          let nearest_scope;
          if (simple_args
              && !fn.uses_arguments
              && !(compressor.parent() instanceof AST_Class)
              && !(fn.name && fn instanceof AST_Function)
              && (returned_value = can_flatten_body(stat))
              && (exp === fn
                  || has_annotation(self, _INLINE)
                  || compressor.option("unused")
                      && (def = exp.definition()).references.length == 1
                      && !is_recursive_ref(compressor, def)
                      && fn.is_constant_expression(exp.scope))
              && !has_annotation(self, _PURE | _NOINLINE)
              && !fn.contains_this()
              && can_inject_symbols()
              && (nearest_scope = compressor.find_scope())
              && !scope_encloses_variables_in_this_scope(nearest_scope, fn)
              && !(function in_default_assign() {
                      // Due to the fact function parameters have their own scope
                      // which can't use `var something` in the function body within,
                      // we simply don't inline into DefaultAssign.
                      let i = 0;
                      let p;
                      while ((p = compressor.parent(i++))) {
                          if (p instanceof AST_DefaultAssign) return true;
                          if (p instanceof AST_Block) break;
                      }
                      return false;
                  })()
              && !(scope instanceof AST_Class)
          ) {
              set_flag(fn, SQUEEZED);
              nearest_scope.add_child_scope(fn);
              return make_sequence(self, flatten_fn(returned_value)).optimize(compressor);
          }
      }

      if (can_inline && has_annotation(self, _INLINE)) {
          set_flag(fn, SQUEEZED);
          fn = make_node(fn.CTOR === AST_Defun ? AST_Function : fn.CTOR, fn, fn);
          fn = fn.clone(true);
          fn.figure_out_scope({}, {
              parent_scope: compressor.find_scope(),
              toplevel: compressor.get_toplevel()
          });

          return make_node(AST_Call, self, {
              expression: fn,
              args: self.args,
          }).optimize(compressor);
      }

      const can_drop_this_call = is_regular_func && compressor.option("side_effects") && fn.body.every(is_empty);
      if (can_drop_this_call) {
          var args = self.args.concat(make_node(AST_Undefined, self));
          return make_sequence(self, args).optimize(compressor);
      }

      if (compressor.option("negate_iife")
          && compressor.parent() instanceof AST_SimpleStatement
          && is_iife_call(self)) {
          return self.negate(compressor, true);
      }

      var ev = self.evaluate(compressor);
      if (ev !== self) {
          ev = make_node_from_constant(ev, self).optimize(compressor);
          return best_of(compressor, ev, self);
      }

      return self;

      function return_value(stat) {
          if (!stat) return make_node(AST_Undefined, self);
          if (stat instanceof AST_Return) {
              if (!stat.value) return make_node(AST_Undefined, self);
              return stat.value.clone(true);
          }
          if (stat instanceof AST_SimpleStatement) {
              return make_node(AST_UnaryPrefix, stat, {
                  operator: "void",
                  expression: stat.body.clone(true)
              });
          }
      }

      function can_flatten_body(stat) {
          var body = fn.body;
          var len = body.length;
          if (compressor.option("inline") < 3) {
              return len == 1 && return_value(stat);
          }
          stat = null;
          for (var i = 0; i < len; i++) {
              var line = body[i];
              if (line instanceof AST_Var) {
                  if (stat && !line.definitions.every((var_def) =>
                      !var_def.value
                  )) {
                      return false;
                  }
              } else if (stat) {
                  return false;
              } else if (!(line instanceof AST_EmptyStatement)) {
                  stat = line;
              }
          }
          return return_value(stat);
      }

      function can_inject_args(block_scoped, safe_to_inject) {
          for (var i = 0, len = fn.argnames.length; i < len; i++) {
              var arg = fn.argnames[i];
              if (arg instanceof AST_DefaultAssign) {
                  if (has_flag(arg.left, UNUSED)) continue;
                  return false;
              }
              if (arg instanceof AST_Destructuring) return false;
              if (arg instanceof AST_Expansion) {
                  if (has_flag(arg.expression, UNUSED)) continue;
                  return false;
              }
              if (has_flag(arg, UNUSED)) continue;
              if (!safe_to_inject
                  || block_scoped.has(arg.name)
                  || identifier_atom.has(arg.name)
                  || scope.conflicting_def(arg.name)) {
                  return false;
              }
              if (in_loop) in_loop.push(arg.definition());
          }
          return true;
      }

      function can_inject_vars(block_scoped, safe_to_inject) {
          var len = fn.body.length;
          for (var i = 0; i < len; i++) {
              var stat = fn.body[i];
              if (!(stat instanceof AST_Var)) continue;
              if (!safe_to_inject) return false;
              for (var j = stat.definitions.length; --j >= 0;) {
                  var name = stat.definitions[j].name;
                  if (name instanceof AST_Destructuring
                      || block_scoped.has(name.name)
                      || identifier_atom.has(name.name)
                      || scope.conflicting_def(name.name)) {
                      return false;
                  }
                  if (in_loop) in_loop.push(name.definition());
              }
          }
          return true;
      }

      function can_inject_symbols() {
          var block_scoped = new Set();
          do {
              scope = compressor.parent(++level);
              if (scope.is_block_scope() && scope.block_scope) {
                  // TODO this is sometimes undefined during compression.
                  // But it should always have a value!
                  scope.block_scope.variables.forEach(function (variable) {
                      block_scoped.add(variable.name);
                  });
              }
              if (scope instanceof AST_Catch) {
                  // TODO can we delete? AST_Catch is a block scope.
                  if (scope.argname) {
                      block_scoped.add(scope.argname.name);
                  }
              } else if (scope instanceof AST_IterationStatement) {
                  in_loop = [];
              } else if (scope instanceof AST_SymbolRef) {
                  if (scope.fixed_value() instanceof AST_Scope) return false;
              }
          } while (!(scope instanceof AST_Scope));

          var safe_to_inject = !(scope instanceof AST_Toplevel) || compressor.toplevel.vars;
          var inline = compressor.option("inline");
          if (!can_inject_vars(block_scoped, inline >= 3 && safe_to_inject)) return false;
          if (!can_inject_args(block_scoped, inline >= 2 && safe_to_inject)) return false;
          return !in_loop || in_loop.length == 0 || !is_reachable(fn, in_loop);
      }

      function append_var(decls, expressions, name, value) {
          var def = name.definition();

          // Name already exists, only when a function argument had the same name
          const already_appended = scope.variables.has(name.name);
          if (!already_appended) {
              scope.variables.set(name.name, def);
              scope.enclosed.push(def);
              decls.push(make_node(AST_VarDef, name, {
                  name: name,
                  value: null
              }));
          }

          var sym = make_node(AST_SymbolRef, name, name);
          def.references.push(sym);
          if (value) expressions.push(make_node(AST_Assign, self, {
              operator: "=",
              logical: false,
              left: sym,
              right: value.clone()
          }));
      }

      function flatten_args(decls, expressions) {
          var len = fn.argnames.length;
          for (var i = self.args.length; --i >= len;) {
              expressions.push(self.args[i]);
          }
          for (i = len; --i >= 0;) {
              var name = fn.argnames[i];
              var value = self.args[i];
              if (has_flag(name, UNUSED) || !name.name || scope.conflicting_def(name.name)) {
                  if (value) expressions.push(value);
              } else {
                  var symbol = make_node(AST_SymbolVar, name, name);
                  name.definition().orig.push(symbol);
                  if (!value && in_loop) value = make_node(AST_Undefined, self);
                  append_var(decls, expressions, symbol, value);
              }
          }
          decls.reverse();
          expressions.reverse();
      }

      function flatten_vars(decls, expressions) {
          var pos = expressions.length;
          for (var i = 0, lines = fn.body.length; i < lines; i++) {
              var stat = fn.body[i];
              if (!(stat instanceof AST_Var)) continue;
              for (var j = 0, defs = stat.definitions.length; j < defs; j++) {
                  var var_def = stat.definitions[j];
                  var name = var_def.name;
                  append_var(decls, expressions, name, var_def.value);
                  if (in_loop && fn.argnames.every((argname) =>
                      argname.name != name.name
                  )) {
                      var def = fn.variables.get(name.name);
                      var sym = make_node(AST_SymbolRef, name, name);
                      def.references.push(sym);
                      expressions.splice(pos++, 0, make_node(AST_Assign, var_def, {
                          operator: "=",
                          logical: false,
                          left: sym,
                          right: make_node(AST_Undefined, name)
                      }));
                  }
              }
          }
      }

      function flatten_fn(returned_value) {
          var decls = [];
          var expressions = [];
          flatten_args(decls, expressions);
          flatten_vars(decls, expressions);
          expressions.push(returned_value);

          if (decls.length) {
              const i = scope.body.indexOf(compressor.parent(level - 1)) + 1;
              scope.body.splice(i, 0, make_node(AST_Var, fn, {
                  definitions: decls
              }));
          }

          return expressions.map(exp => exp.clone(true));
      }
  }

  /***********************************************************************

    A JavaScript tokenizer / parser / beautifier / compressor.
    https://github.com/mishoo/UglifyJS2

    -------------------------------- (C) ---------------------------------

                             Author: Mihai Bazon
                           <mihai.bazon@gmail.com>
                         http://mihai.bazon.net/blog

    Distributed under the BSD license:

      Copyright 2012 (c) Mihai Bazon <mihai.bazon@gmail.com>

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions
      are met:

          * Redistributions of source code must retain the above
            copyright notice, this list of conditions and the following
            disclaimer.

          * Redistributions in binary form must reproduce the above
            copyright notice, this list of conditions and the following
            disclaimer in the documentation and/or other materials
            provided with the distribution.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
      IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
      PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
      LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
      OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
      PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
      PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
      TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
      THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
      SUCH DAMAGE.

   ***********************************************************************/

  class Compressor extends TreeWalker {
      constructor(options, { false_by_default = false, mangle_options = false }) {
          super();
          if (options.defaults !== undefined && !options.defaults) false_by_default = true;
          this.options = defaults(options, {
              arguments     : false,
              arrows        : !false_by_default,
              booleans      : !false_by_default,
              booleans_as_integers : false,
              collapse_vars : !false_by_default,
              comparisons   : !false_by_default,
              computed_props: !false_by_default,
              conditionals  : !false_by_default,
              dead_code     : !false_by_default,
              defaults      : true,
              directives    : !false_by_default,
              drop_console  : false,
              drop_debugger : !false_by_default,
              ecma          : 5,
              evaluate      : !false_by_default,
              expression    : false,
              global_defs   : false,
              hoist_funs    : false,
              hoist_props   : !false_by_default,
              hoist_vars    : false,
              ie8           : false,
              if_return     : !false_by_default,
              inline        : !false_by_default,
              join_vars     : !false_by_default,
              keep_classnames: false,
              keep_fargs    : true,
              keep_fnames   : false,
              keep_infinity : false,
              loops         : !false_by_default,
              module        : false,
              negate_iife   : !false_by_default,
              passes        : 1,
              properties    : !false_by_default,
              pure_getters  : !false_by_default && "strict",
              pure_funcs    : null,
              reduce_funcs  : !false_by_default,
              reduce_vars   : !false_by_default,
              sequences     : !false_by_default,
              side_effects  : !false_by_default,
              switches      : !false_by_default,
              top_retain    : null,
              toplevel      : !!(options && options["top_retain"]),
              typeofs       : !false_by_default,
              unsafe        : false,
              unsafe_arrows : false,
              unsafe_comps  : false,
              unsafe_Function: false,
              unsafe_math   : false,
              unsafe_symbols: false,
              unsafe_methods: false,
              unsafe_proto  : false,
              unsafe_regexp : false,
              unsafe_undefined: false,
              unused        : !false_by_default,
              warnings      : false  // legacy
          }, true);
          var global_defs = this.options["global_defs"];
          if (typeof global_defs == "object") for (var key in global_defs) {
              if (key[0] === "@" && HOP(global_defs, key)) {
                  global_defs[key.slice(1)] = parse(global_defs[key], {
                      expression: true
                  });
              }
          }
          if (this.options["inline"] === true) this.options["inline"] = 3;
          var pure_funcs = this.options["pure_funcs"];
          if (typeof pure_funcs == "function") {
              this.pure_funcs = pure_funcs;
          } else {
              this.pure_funcs = pure_funcs ? function(node) {
                  return !pure_funcs.includes(node.expression.print_to_string());
              } : return_true;
          }
          var top_retain = this.options["top_retain"];
          if (top_retain instanceof RegExp) {
              this.top_retain = function(def) {
                  return top_retain.test(def.name);
              };
          } else if (typeof top_retain == "function") {
              this.top_retain = top_retain;
          } else if (top_retain) {
              if (typeof top_retain == "string") {
                  top_retain = top_retain.split(/,/);
              }
              this.top_retain = function(def) {
                  return top_retain.includes(def.name);
              };
          }
          if (this.options["module"]) {
              this.directives["use strict"] = true;
              this.options["toplevel"] = true;
          }
          var toplevel = this.options["toplevel"];
          this.toplevel = typeof toplevel == "string" ? {
              funcs: /funcs/.test(toplevel),
              vars: /vars/.test(toplevel)
          } : {
              funcs: toplevel,
              vars: toplevel
          };
          var sequences = this.options["sequences"];
          this.sequences_limit = sequences == 1 ? 800 : sequences | 0;
          this.evaluated_regexps = new Map();
          this._toplevel = undefined;
          this.mangle_options = mangle_options;
      }

      option(key) {
          return this.options[key];
      }

      exposed(def) {
          if (def.export) return true;
          if (def.global) for (var i = 0, len = def.orig.length; i < len; i++)
              if (!this.toplevel[def.orig[i] instanceof AST_SymbolDefun ? "funcs" : "vars"])
                  return true;
          return false;
      }

      in_boolean_context() {
          if (!this.option("booleans")) return false;
          var self = this.self();
          for (var i = 0, p; p = this.parent(i); i++) {
              if (p instanceof AST_SimpleStatement
                  || p instanceof AST_Conditional && p.condition === self
                  || p instanceof AST_DWLoop && p.condition === self
                  || p instanceof AST_For && p.condition === self
                  || p instanceof AST_If && p.condition === self
                  || p instanceof AST_UnaryPrefix && p.operator == "!" && p.expression === self) {
                  return true;
              }
              if (
                  p instanceof AST_Binary
                      && (
                          p.operator == "&&"
                          || p.operator == "||"
                          || p.operator == "??"
                      )
                  || p instanceof AST_Conditional
                  || p.tail_node() === self
              ) {
                  self = p;
              } else {
                  return false;
              }
          }
      }

      get_toplevel() {
          return this._toplevel;
      }

      compress(toplevel) {
          toplevel = toplevel.resolve_defines(this);
          this._toplevel = toplevel;
          if (this.option("expression")) {
              this._toplevel.process_expression(true);
          }
          var passes = +this.options.passes || 1;
          var min_count = 1 / 0;
          var stopping = false;
          var nth_identifier = this.mangle_options && this.mangle_options.nth_identifier || base54;
          var mangle = { ie8: this.option("ie8"), nth_identifier: nth_identifier };
          for (var pass = 0; pass < passes; pass++) {
              this._toplevel.figure_out_scope(mangle);
              if (pass === 0 && this.option("drop_console")) {
                  // must be run before reduce_vars and compress pass
                  this._toplevel = this._toplevel.drop_console();
              }
              if (pass > 0 || this.option("reduce_vars")) {
                  this._toplevel.reset_opt_flags(this);
              }
              this._toplevel = this._toplevel.transform(this);
              if (passes > 1) {
                  let count = 0;
                  walk(this._toplevel, () => { count++; });
                  if (count < min_count) {
                      min_count = count;
                      stopping = false;
                  } else if (stopping) {
                      break;
                  } else {
                      stopping = true;
                  }
              }
          }
          if (this.option("expression")) {
              this._toplevel.process_expression(false);
          }
          toplevel = this._toplevel;
          this._toplevel = undefined;
          return toplevel;
      }

      before(node, descend) {
          if (has_flag(node, SQUEEZED)) return node;
          var was_scope = false;
          if (node instanceof AST_Scope) {
              node = node.hoist_properties(this);
              node = node.hoist_declarations(this);
              was_scope = true;
          }
          // Before https://github.com/mishoo/UglifyJS2/pull/1602 AST_Node.optimize()
          // would call AST_Node.transform() if a different instance of AST_Node is
          // produced after def_optimize().
          // This corrupts TreeWalker.stack, which cause AST look-ups to malfunction.
          // Migrate and defer all children's AST_Node.transform() to below, which
          // will now happen after this parent AST_Node has been properly substituted
          // thus gives a consistent AST snapshot.
          descend(node, this);
          // Existing code relies on how AST_Node.optimize() worked, and omitting the
          // following replacement call would result in degraded efficiency of both
          // output and performance.
          descend(node, this);
          var opt = node.optimize(this);
          if (was_scope && opt instanceof AST_Scope) {
              opt.drop_unused(this);
              descend(opt, this);
          }
          if (opt === node) set_flag(opt, SQUEEZED);
          return opt;
      }
  }

  function def_optimize(node, optimizer) {
      node.DEFMETHOD("optimize", function(compressor) {
          var self = this;
          if (has_flag(self, OPTIMIZED)) return self;
          if (compressor.has_directive("use asm")) return self;
          var opt = optimizer(self, compressor);
          set_flag(opt, OPTIMIZED);
          return opt;
      });
  }

  def_optimize(AST_Node, function(self) {
      return self;
  });

  AST_Toplevel.DEFMETHOD("drop_console", function() {
      return this.transform(new TreeTransformer(function(self) {
          if (self.TYPE == "Call") {
              var exp = self.expression;
              if (exp instanceof AST_PropAccess) {
                  var name = exp.expression;
                  while (name.expression) {
                      name = name.expression;
                  }
                  if (is_undeclared_ref(name) && name.name == "console") {
                      return make_node(AST_Undefined, self);
                  }
              }
          }
      }));
  });

  AST_Node.DEFMETHOD("equivalent_to", function(node) {
      return equivalent_to(this, node);
  });

  AST_Scope.DEFMETHOD("process_expression", function(insert, compressor) {
      var self = this;
      var tt = new TreeTransformer(function(node) {
          if (insert && node instanceof AST_SimpleStatement) {
              return make_node(AST_Return, node, {
                  value: node.body
              });
          }
          if (!insert && node instanceof AST_Return) {
              if (compressor) {
                  var value = node.value && node.value.drop_side_effect_free(compressor, true);
                  return value
                      ? make_node(AST_SimpleStatement, node, { body: value })
                      : make_node(AST_EmptyStatement, node);
              }
              return make_node(AST_SimpleStatement, node, {
                  body: node.value || make_node(AST_UnaryPrefix, node, {
                      operator: "void",
                      expression: make_node(AST_Number, node, {
                          value: 0
                      })
                  })
              });
          }
          if (node instanceof AST_Class || node instanceof AST_Lambda && node !== self) {
              return node;
          }
          if (node instanceof AST_Block) {
              var index = node.body.length - 1;
              if (index >= 0) {
                  node.body[index] = node.body[index].transform(tt);
              }
          } else if (node instanceof AST_If) {
              node.body = node.body.transform(tt);
              if (node.alternative) {
                  node.alternative = node.alternative.transform(tt);
              }
          } else if (node instanceof AST_With) {
              node.body = node.body.transform(tt);
          }
          return node;
      });
      self.transform(tt);
  });

  AST_Toplevel.DEFMETHOD("reset_opt_flags", function(compressor) {
      const self = this;
      const reduce_vars = compressor.option("reduce_vars");

      const preparation = new TreeWalker(function(node, descend) {
          clear_flag(node, CLEAR_BETWEEN_PASSES);
          if (reduce_vars) {
              if (compressor.top_retain
                  && node instanceof AST_Defun  // Only functions are retained
                  && preparation.parent() === self
              ) {
                  set_flag(node, TOP);
              }
              return node.reduce_vars(preparation, descend, compressor);
          }
      });
      // Stack of look-up tables to keep track of whether a `SymbolDef` has been
      // properly assigned before use:
      // - `push()` & `pop()` when visiting conditional branches
      preparation.safe_ids = Object.create(null);
      preparation.in_loop = null;
      preparation.loop_ids = new Map();
      preparation.defs_to_safe_ids = new Map();
      self.walk(preparation);
  });

  AST_Symbol.DEFMETHOD("fixed_value", function() {
      var fixed = this.thedef.fixed;
      if (!fixed || fixed instanceof AST_Node) return fixed;
      return fixed();
  });

  AST_SymbolRef.DEFMETHOD("is_immutable", function() {
      var orig = this.definition().orig;
      return orig.length == 1 && orig[0] instanceof AST_SymbolLambda;
  });

  function find_variable(compressor, name) {
      var scope, i = 0;
      while (scope = compressor.parent(i++)) {
          if (scope instanceof AST_Scope) break;
          if (scope instanceof AST_Catch && scope.argname) {
              scope = scope.argname.definition().scope;
              break;
          }
      }
      return scope.find_variable(name);
  }

  var global_names = makePredicate("Array Boolean clearInterval clearTimeout console Date decodeURI decodeURIComponent encodeURI encodeURIComponent Error escape eval EvalError Function isFinite isNaN JSON Math Number parseFloat parseInt RangeError ReferenceError RegExp Object setInterval setTimeout String SyntaxError TypeError unescape URIError");
  AST_SymbolRef.DEFMETHOD("is_declared", function(compressor) {
      return !this.definition().undeclared
          || compressor.option("unsafe") && global_names.has(this.name);
  });

  /* -----[ optimizers ]----- */

  var directives = new Set(["use asm", "use strict"]);
  def_optimize(AST_Directive, function(self, compressor) {
      if (compressor.option("directives")
          && (!directives.has(self.value) || compressor.has_directive(self.value) !== self)) {
          return make_node(AST_EmptyStatement, self);
      }
      return self;
  });

  def_optimize(AST_Debugger, function(self, compressor) {
      if (compressor.option("drop_debugger"))
          return make_node(AST_EmptyStatement, self);
      return self;
  });

  def_optimize(AST_LabeledStatement, function(self, compressor) {
      if (self.body instanceof AST_Break
          && compressor.loopcontrol_target(self.body) === self.body) {
          return make_node(AST_EmptyStatement, self);
      }
      return self.label.references.length == 0 ? self.body : self;
  });

  def_optimize(AST_Block, function(self, compressor) {
      tighten_body(self.body, compressor);
      return self;
  });

  function can_be_extracted_from_if_block(node) {
      return !(
          node instanceof AST_Const
          || node instanceof AST_Let
          || node instanceof AST_Class
      );
  }

  def_optimize(AST_BlockStatement, function(self, compressor) {
      tighten_body(self.body, compressor);
      switch (self.body.length) {
        case 1:
          if (!compressor.has_directive("use strict")
              && compressor.parent() instanceof AST_If
              && can_be_extracted_from_if_block(self.body[0])
              || can_be_evicted_from_block(self.body[0])) {
              return self.body[0];
          }
          break;
        case 0: return make_node(AST_EmptyStatement, self);
      }
      return self;
  });

  function opt_AST_Lambda(self, compressor) {
      tighten_body(self.body, compressor);
      if (compressor.option("side_effects")
          && self.body.length == 1
          && self.body[0] === compressor.has_directive("use strict")) {
          self.body.length = 0;
      }
      return self;
  }
  def_optimize(AST_Lambda, opt_AST_Lambda);

  const r_keep_assign = /keep_assign/;
  AST_Scope.DEFMETHOD("drop_unused", function(compressor) {
      if (!compressor.option("unused")) return;
      if (compressor.has_directive("use asm")) return;
      var self = this;
      if (self.pinned()) return;
      var drop_funcs = !(self instanceof AST_Toplevel) || compressor.toplevel.funcs;
      var drop_vars = !(self instanceof AST_Toplevel) || compressor.toplevel.vars;
      const assign_as_unused = r_keep_assign.test(compressor.option("unused")) ? return_false : function(node) {
          if (node instanceof AST_Assign
              && !node.logical
              && (has_flag(node, WRITE_ONLY) || node.operator == "=")
          ) {
              return node.left;
          }
          if (node instanceof AST_Unary && has_flag(node, WRITE_ONLY)) {
              return node.expression;
          }
      };
      var in_use_ids = new Map();
      var fixed_ids = new Map();
      if (self instanceof AST_Toplevel && compressor.top_retain) {
          self.variables.forEach(function(def) {
              if (compressor.top_retain(def) && !in_use_ids.has(def.id)) {
                  in_use_ids.set(def.id, def);
              }
          });
      }
      var var_defs_by_id = new Map();
      var initializations = new Map();
      // pass 1: find out which symbols are directly used in
      // this scope (not in nested scopes).
      var scope = this;
      var tw = new TreeWalker(function(node, descend) {
          if (node instanceof AST_Lambda && node.uses_arguments && !tw.has_directive("use strict")) {
              node.argnames.forEach(function(argname) {
                  if (!(argname instanceof AST_SymbolDeclaration)) return;
                  var def = argname.definition();
                  if (!in_use_ids.has(def.id)) {
                      in_use_ids.set(def.id, def);
                  }
              });
          }
          if (node === self) return;
          if (node instanceof AST_Defun || node instanceof AST_DefClass) {
              var node_def = node.name.definition();
              const in_export = tw.parent() instanceof AST_Export;
              if (in_export || !drop_funcs && scope === self) {
                  if (node_def.global && !in_use_ids.has(node_def.id)) {
                      in_use_ids.set(node_def.id, node_def);
                  }
              }
              if (node instanceof AST_DefClass) {
                  if (
                      node.extends
                      && (node.extends.has_side_effects(compressor)
                      || node.extends.may_throw(compressor))
                  ) {
                      node.extends.walk(tw);
                  }
                  for (const prop of node.properties) {
                      if (
                          prop.has_side_effects(compressor) ||
                          prop.may_throw(compressor)
                      ) {
                          prop.walk(tw);
                      }
                  }
              }
              map_add(initializations, node_def.id, node);
              return true; // don't go in nested scopes
          }
          if (node instanceof AST_SymbolFunarg && scope === self) {
              map_add(var_defs_by_id, node.definition().id, node);
          }
          if (node instanceof AST_Definitions && scope === self) {
              const in_export = tw.parent() instanceof AST_Export;
              node.definitions.forEach(function(def) {
                  if (def.name instanceof AST_SymbolVar) {
                      map_add(var_defs_by_id, def.name.definition().id, def);
                  }
                  if (in_export || !drop_vars) {
                      walk(def.name, node => {
                          if (node instanceof AST_SymbolDeclaration) {
                              const def = node.definition();
                              if (
                                  (in_export || def.global)
                                  && !in_use_ids.has(def.id)
                              ) {
                                  in_use_ids.set(def.id, def);
                              }
                          }
                      });
                  }
                  if (def.value) {
                      if (def.name instanceof AST_Destructuring) {
                          def.walk(tw);
                      } else {
                          var node_def = def.name.definition();
                          map_add(initializations, node_def.id, def.value);
                          if (!node_def.chained && def.name.fixed_value() === def.value) {
                              fixed_ids.set(node_def.id, def);
                          }
                      }
                      if (def.value.has_side_effects(compressor)) {
                          def.value.walk(tw);
                      }
                  }
              });
              return true;
          }
          return scan_ref_scoped(node, descend);
      });
      self.walk(tw);
      // pass 2: for every used symbol we need to walk its
      // initialization code to figure out if it uses other
      // symbols (that may not be in_use).
      tw = new TreeWalker(scan_ref_scoped);
      in_use_ids.forEach(function (def) {
          var init = initializations.get(def.id);
          if (init) init.forEach(function(init) {
              init.walk(tw);
          });
      });
      // pass 3: we should drop declarations not in_use
      var tt = new TreeTransformer(
          function before(node, descend, in_list) {
              var parent = tt.parent();
              if (drop_vars) {
                  const sym = assign_as_unused(node);
                  if (sym instanceof AST_SymbolRef) {
                      var def = sym.definition();
                      var in_use = in_use_ids.has(def.id);
                      if (node instanceof AST_Assign) {
                          if (!in_use || fixed_ids.has(def.id) && fixed_ids.get(def.id) !== node) {
                              return maintain_this_binding(parent, node, node.right.transform(tt));
                          }
                      } else if (!in_use) return in_list ? MAP.skip : make_node(AST_Number, node, {
                          value: 0
                      });
                  }
              }
              if (scope !== self) return;
              var def;
              if (node.name
                  && (node instanceof AST_ClassExpression
                      && !keep_name(compressor.option("keep_classnames"), (def = node.name.definition()).name)
                  || node instanceof AST_Function
                      && !keep_name(compressor.option("keep_fnames"), (def = node.name.definition()).name))) {
                  // any declarations with same name will overshadow
                  // name of this anonymous function and can therefore
                  // never be used anywhere
                  if (!in_use_ids.has(def.id) || def.orig.length > 1) node.name = null;
              }
              if (node instanceof AST_Lambda && !(node instanceof AST_Accessor)) {
                  var trim = !compressor.option("keep_fargs");
                  for (var a = node.argnames, i = a.length; --i >= 0;) {
                      var sym = a[i];
                      if (sym instanceof AST_Expansion) {
                          sym = sym.expression;
                      }
                      if (sym instanceof AST_DefaultAssign) {
                          sym = sym.left;
                      }
                      // Do not drop destructuring arguments.
                      // They constitute a type assertion, so dropping
                      // them would stop that TypeError which would happen
                      // if someone called it with an incorrectly formatted
                      // parameter.
                      if (!(sym instanceof AST_Destructuring) && !in_use_ids.has(sym.definition().id)) {
                          set_flag(sym, UNUSED);
                          if (trim) {
                              a.pop();
                          }
                      } else {
                          trim = false;
                      }
                  }
              }
              if ((node instanceof AST_Defun || node instanceof AST_DefClass) && node !== self) {
                  const def = node.name.definition();
                  let keep = def.global && !drop_funcs || in_use_ids.has(def.id);
                  if (!keep) {
                      def.eliminated++;
                      if (node instanceof AST_DefClass) {
                          // Classes might have extends with side effects
                          const side_effects = node.drop_side_effect_free(compressor);
                          if (side_effects) {
                              return make_node(AST_SimpleStatement, node, {
                                  body: side_effects
                              });
                          }
                      }
                      return in_list ? MAP.skip : make_node(AST_EmptyStatement, node);
                  }
              }
              if (node instanceof AST_Definitions && !(parent instanceof AST_ForIn && parent.init === node)) {
                  var drop_block = !(parent instanceof AST_Toplevel) && !(node instanceof AST_Var);
                  // place uninitialized names at the start
                  var body = [], head = [], tail = [];
                  // for unused names whose initialization has
                  // side effects, we can cascade the init. code
                  // into the next one, or next statement.
                  var side_effects = [];
                  node.definitions.forEach(function(def) {
                      if (def.value) def.value = def.value.transform(tt);
                      var is_destructure = def.name instanceof AST_Destructuring;
                      var sym = is_destructure
                          ? new SymbolDef(null, { name: "<destructure>" }) /* fake SymbolDef */
                          : def.name.definition();
                      if (drop_block && sym.global) return tail.push(def);
                      if (!(drop_vars || drop_block)
                          || is_destructure
                              && (def.name.names.length
                                  || def.name.is_array
                                  || compressor.option("pure_getters") != true)
                          || in_use_ids.has(sym.id)
                      ) {
                          if (def.value && fixed_ids.has(sym.id) && fixed_ids.get(sym.id) !== def) {
                              def.value = def.value.drop_side_effect_free(compressor);
                          }
                          if (def.name instanceof AST_SymbolVar) {
                              var var_defs = var_defs_by_id.get(sym.id);
                              if (var_defs.length > 1 && (!def.value || sym.orig.indexOf(def.name) > sym.eliminated)) {
                                  if (def.value) {
                                      var ref = make_node(AST_SymbolRef, def.name, def.name);
                                      sym.references.push(ref);
                                      var assign = make_node(AST_Assign, def, {
                                          operator: "=",
                                          logical: false,
                                          left: ref,
                                          right: def.value
                                      });
                                      if (fixed_ids.get(sym.id) === def) {
                                          fixed_ids.set(sym.id, assign);
                                      }
                                      side_effects.push(assign.transform(tt));
                                  }
                                  remove(var_defs, def);
                                  sym.eliminated++;
                                  return;
                              }
                          }
                          if (def.value) {
                              if (side_effects.length > 0) {
                                  if (tail.length > 0) {
                                      side_effects.push(def.value);
                                      def.value = make_sequence(def.value, side_effects);
                                  } else {
                                      body.push(make_node(AST_SimpleStatement, node, {
                                          body: make_sequence(node, side_effects)
                                      }));
                                  }
                                  side_effects = [];
                              }
                              tail.push(def);
                          } else {
                              head.push(def);
                          }
                      } else if (sym.orig[0] instanceof AST_SymbolCatch) {
                          var value = def.value && def.value.drop_side_effect_free(compressor);
                          if (value) side_effects.push(value);
                          def.value = null;
                          head.push(def);
                      } else {
                          var value = def.value && def.value.drop_side_effect_free(compressor);
                          if (value) {
                              side_effects.push(value);
                          }
                          sym.eliminated++;
                      }
                  });
                  if (head.length > 0 || tail.length > 0) {
                      node.definitions = head.concat(tail);
                      body.push(node);
                  }
                  if (side_effects.length > 0) {
                      body.push(make_node(AST_SimpleStatement, node, {
                          body: make_sequence(node, side_effects)
                      }));
                  }
                  switch (body.length) {
                    case 0:
                      return in_list ? MAP.skip : make_node(AST_EmptyStatement, node);
                    case 1:
                      return body[0];
                    default:
                      return in_list ? MAP.splice(body) : make_node(AST_BlockStatement, node, {
                          body: body
                      });
                  }
              }
              // certain combination of unused name + side effect leads to:
              //    https://github.com/mishoo/UglifyJS2/issues/44
              //    https://github.com/mishoo/UglifyJS2/issues/1830
              //    https://github.com/mishoo/UglifyJS2/issues/1838
              // that's an invalid AST.
              // We fix it at this stage by moving the `var` outside the `for`.
              if (node instanceof AST_For) {
                  descend(node, this);
                  var block;
                  if (node.init instanceof AST_BlockStatement) {
                      block = node.init;
                      node.init = block.body.pop();
                      block.body.push(node);
                  }
                  if (node.init instanceof AST_SimpleStatement) {
                      node.init = node.init.body;
                  } else if (is_empty(node.init)) {
                      node.init = null;
                  }
                  return !block ? node : in_list ? MAP.splice(block.body) : block;
              }
              if (node instanceof AST_LabeledStatement
                  && node.body instanceof AST_For
              ) {
                  descend(node, this);
                  if (node.body instanceof AST_BlockStatement) {
                      var block = node.body;
                      node.body = block.body.pop();
                      block.body.push(node);
                      return in_list ? MAP.splice(block.body) : block;
                  }
                  return node;
              }
              if (node instanceof AST_BlockStatement) {
                  descend(node, this);
                  if (in_list && node.body.every(can_be_evicted_from_block)) {
                      return MAP.splice(node.body);
                  }
                  return node;
              }
              if (node instanceof AST_Scope) {
                  const save_scope = scope;
                  scope = node;
                  descend(node, this);
                  scope = save_scope;
                  return node;
              }
          }
      );

      self.transform(tt);

      function scan_ref_scoped(node, descend) {
          var node_def;
          const sym = assign_as_unused(node);
          if (sym instanceof AST_SymbolRef
              && !is_ref_of(node.left, AST_SymbolBlockDeclaration)
              && self.variables.get(sym.name) === (node_def = sym.definition())
          ) {
              if (node instanceof AST_Assign) {
                  node.right.walk(tw);
                  if (!node_def.chained && node.left.fixed_value() === node.right) {
                      fixed_ids.set(node_def.id, node);
                  }
              }
              return true;
          }
          if (node instanceof AST_SymbolRef) {
              node_def = node.definition();
              if (!in_use_ids.has(node_def.id)) {
                  in_use_ids.set(node_def.id, node_def);
                  if (node_def.orig[0] instanceof AST_SymbolCatch) {
                      const redef = node_def.scope.is_block_scope()
                          && node_def.scope.get_defun_scope().variables.get(node_def.name);
                      if (redef) in_use_ids.set(redef.id, redef);
                  }
              }
              return true;
          }
          if (node instanceof AST_Scope) {
              var save_scope = scope;
              scope = node;
              descend();
              scope = save_scope;
              return true;
          }
      }
  });

  AST_Scope.DEFMETHOD("hoist_declarations", function(compressor) {
      var self = this;
      if (compressor.has_directive("use asm")) return self;
      // Hoisting makes no sense in an arrow func
      if (!Array.isArray(self.body)) return self;

      var hoist_funs = compressor.option("hoist_funs");
      var hoist_vars = compressor.option("hoist_vars");

      if (hoist_funs || hoist_vars) {
          var dirs = [];
          var hoisted = [];
          var vars = new Map(), vars_found = 0, var_decl = 0;
          // let's count var_decl first, we seem to waste a lot of
          // space if we hoist `var` when there's only one.
          walk(self, node => {
              if (node instanceof AST_Scope && node !== self)
                  return true;
              if (node instanceof AST_Var) {
                  ++var_decl;
                  return true;
              }
          });
          hoist_vars = hoist_vars && var_decl > 1;
          var tt = new TreeTransformer(
              function before(node) {
                  if (node !== self) {
                      if (node instanceof AST_Directive) {
                          dirs.push(node);
                          return make_node(AST_EmptyStatement, node);
                      }
                      if (hoist_funs && node instanceof AST_Defun
                          && !(tt.parent() instanceof AST_Export)
                          && tt.parent() === self) {
                          hoisted.push(node);
                          return make_node(AST_EmptyStatement, node);
                      }
                      if (
                          hoist_vars
                          && node instanceof AST_Var
                          && !node.definitions.some(def => def.name instanceof AST_Destructuring)
                      ) {
                          node.definitions.forEach(function(def) {
                              vars.set(def.name.name, def);
                              ++vars_found;
                          });
                          var seq = node.to_assignments(compressor);
                          var p = tt.parent();
                          if (p instanceof AST_ForIn && p.init === node) {
                              if (seq == null) {
                                  var def = node.definitions[0].name;
                                  return make_node(AST_SymbolRef, def, def);
                              }
                              return seq;
                          }
                          if (p instanceof AST_For && p.init === node) {
                              return seq;
                          }
                          if (!seq) return make_node(AST_EmptyStatement, node);
                          return make_node(AST_SimpleStatement, node, {
                              body: seq
                          });
                      }
                      if (node instanceof AST_Scope)
                          return node; // to avoid descending in nested scopes
                  }
              }
          );
          self = self.transform(tt);
          if (vars_found > 0) {
              // collect only vars which don't show up in self's arguments list
              var defs = [];
              const is_lambda = self instanceof AST_Lambda;
              const args_as_names = is_lambda ? self.args_as_names() : null;
              vars.forEach((def, name) => {
                  if (is_lambda && args_as_names.some((x) => x.name === def.name.name)) {
                      vars.delete(name);
                  } else {
                      def = def.clone();
                      def.value = null;
                      defs.push(def);
                      vars.set(name, def);
                  }
              });
              if (defs.length > 0) {
                  // try to merge in assignments
                  for (var i = 0; i < self.body.length;) {
                      if (self.body[i] instanceof AST_SimpleStatement) {
                          var expr = self.body[i].body, sym, assign;
                          if (expr instanceof AST_Assign
                              && expr.operator == "="
                              && (sym = expr.left) instanceof AST_Symbol
                              && vars.has(sym.name)
                          ) {
                              var def = vars.get(sym.name);
                              if (def.value) break;
                              def.value = expr.right;
                              remove(defs, def);
                              defs.push(def);
                              self.body.splice(i, 1);
                              continue;
                          }
                          if (expr instanceof AST_Sequence
                              && (assign = expr.expressions[0]) instanceof AST_Assign
                              && assign.operator == "="
                              && (sym = assign.left) instanceof AST_Symbol
                              && vars.has(sym.name)
                          ) {
                              var def = vars.get(sym.name);
                              if (def.value) break;
                              def.value = assign.right;
                              remove(defs, def);
                              defs.push(def);
                              self.body[i].body = make_sequence(expr, expr.expressions.slice(1));
                              continue;
                          }
                      }
                      if (self.body[i] instanceof AST_EmptyStatement) {
                          self.body.splice(i, 1);
                          continue;
                      }
                      if (self.body[i] instanceof AST_BlockStatement) {
                          self.body.splice(i, 1, ...self.body[i].body);
                          continue;
                      }
                      break;
                  }
                  defs = make_node(AST_Var, self, {
                      definitions: defs
                  });
                  hoisted.push(defs);
              }
          }
          self.body = dirs.concat(hoisted, self.body);
      }
      return self;
  });

  AST_Scope.DEFMETHOD("hoist_properties", function(compressor) {
      var self = this;
      if (!compressor.option("hoist_props") || compressor.has_directive("use asm")) return self;
      var top_retain = self instanceof AST_Toplevel && compressor.top_retain || return_false;
      var defs_by_id = new Map();
      var hoister = new TreeTransformer(function(node, descend) {
          if (node instanceof AST_Definitions
              && hoister.parent() instanceof AST_Export) return node;
          if (node instanceof AST_VarDef) {
              const sym = node.name;
              let def;
              let value;
              if (sym.scope === self
                  && (def = sym.definition()).escaped != 1
                  && !def.assignments
                  && !def.direct_access
                  && !def.single_use
                  && !compressor.exposed(def)
                  && !top_retain(def)
                  && (value = sym.fixed_value()) === node.value
                  && value instanceof AST_Object
                  && !value.properties.some(prop =>
                      prop instanceof AST_Expansion || prop.computed_key()
                  )
              ) {
                  descend(node, this);
                  const defs = new Map();
                  const assignments = [];
                  value.properties.forEach(({ key, value }) => {
                      const scope = hoister.find_scope();
                      const symbol = self.create_symbol(sym.CTOR, {
                          source: sym,
                          scope,
                          conflict_scopes: new Set([
                              scope,
                              ...sym.definition().references.map(ref => ref.scope)
                          ]),
                          tentative_name: sym.name + "_" + key
                      });

                      defs.set(String(key), symbol.definition());

                      assignments.push(make_node(AST_VarDef, node, {
                          name: symbol,
                          value
                      }));
                  });
                  defs_by_id.set(def.id, defs);
                  return MAP.splice(assignments);
              }
          } else if (node instanceof AST_PropAccess
              && node.expression instanceof AST_SymbolRef
          ) {
              const defs = defs_by_id.get(node.expression.definition().id);
              if (defs) {
                  const def = defs.get(String(get_simple_key(node.property)));
                  const sym = make_node(AST_SymbolRef, node, {
                      name: def.name,
                      scope: node.expression.scope,
                      thedef: def
                  });
                  sym.reference({});
                  return sym;
              }
          }
      });
      return self.transform(hoister);
  });

  def_optimize(AST_SimpleStatement, function(self, compressor) {
      if (compressor.option("side_effects")) {
          var body = self.body;
          var node = body.drop_side_effect_free(compressor, true);
          if (!node) {
              return make_node(AST_EmptyStatement, self);
          }
          if (node !== body) {
              return make_node(AST_SimpleStatement, self, { body: node });
          }
      }
      return self;
  });

  def_optimize(AST_While, function(self, compressor) {
      return compressor.option("loops") ? make_node(AST_For, self, self).optimize(compressor) : self;
  });

  def_optimize(AST_Do, function(self, compressor) {
      if (!compressor.option("loops")) return self;
      var cond = self.condition.tail_node().evaluate(compressor);
      if (!(cond instanceof AST_Node)) {
          if (cond) return make_node(AST_For, self, {
              body: make_node(AST_BlockStatement, self.body, {
                  body: [
                      self.body,
                      make_node(AST_SimpleStatement, self.condition, {
                          body: self.condition
                      })
                  ]
              })
          }).optimize(compressor);
          if (!has_break_or_continue(self, compressor.parent())) {
              return make_node(AST_BlockStatement, self.body, {
                  body: [
                      self.body,
                      make_node(AST_SimpleStatement, self.condition, {
                          body: self.condition
                      })
                  ]
              }).optimize(compressor);
          }
      }
      return self;
  });

  function if_break_in_loop(self, compressor) {
      var first = self.body instanceof AST_BlockStatement ? self.body.body[0] : self.body;
      if (compressor.option("dead_code") && is_break(first)) {
          var body = [];
          if (self.init instanceof AST_Statement) {
              body.push(self.init);
          } else if (self.init) {
              body.push(make_node(AST_SimpleStatement, self.init, {
                  body: self.init
              }));
          }
          if (self.condition) {
              body.push(make_node(AST_SimpleStatement, self.condition, {
                  body: self.condition
              }));
          }
          trim_unreachable_code(compressor, self.body, body);
          return make_node(AST_BlockStatement, self, {
              body: body
          });
      }
      if (first instanceof AST_If) {
          if (is_break(first.body)) {
              if (self.condition) {
                  self.condition = make_node(AST_Binary, self.condition, {
                      left: self.condition,
                      operator: "&&",
                      right: first.condition.negate(compressor),
                  });
              } else {
                  self.condition = first.condition.negate(compressor);
              }
              drop_it(first.alternative);
          } else if (is_break(first.alternative)) {
              if (self.condition) {
                  self.condition = make_node(AST_Binary, self.condition, {
                      left: self.condition,
                      operator: "&&",
                      right: first.condition,
                  });
              } else {
                  self.condition = first.condition;
              }
              drop_it(first.body);
          }
      }
      return self;

      function is_break(node) {
          return node instanceof AST_Break
              && compressor.loopcontrol_target(node) === compressor.self();
      }

      function drop_it(rest) {
          rest = as_statement_array(rest);
          if (self.body instanceof AST_BlockStatement) {
              self.body = self.body.clone();
              self.body.body = rest.concat(self.body.body.slice(1));
              self.body = self.body.transform(compressor);
          } else {
              self.body = make_node(AST_BlockStatement, self.body, {
                  body: rest
              }).transform(compressor);
          }
          self = if_break_in_loop(self, compressor);
      }
  }

  def_optimize(AST_For, function(self, compressor) {
      if (!compressor.option("loops")) return self;
      if (compressor.option("side_effects") && self.init) {
          self.init = self.init.drop_side_effect_free(compressor);
      }
      if (self.condition) {
          var cond = self.condition.evaluate(compressor);
          if (!(cond instanceof AST_Node)) {
              if (cond) self.condition = null;
              else if (!compressor.option("dead_code")) {
                  var orig = self.condition;
                  self.condition = make_node_from_constant(cond, self.condition);
                  self.condition = best_of_expression(self.condition.transform(compressor), orig);
              }
          }
          if (compressor.option("dead_code")) {
              if (cond instanceof AST_Node) cond = self.condition.tail_node().evaluate(compressor);
              if (!cond) {
                  var body = [];
                  trim_unreachable_code(compressor, self.body, body);
                  if (self.init instanceof AST_Statement) {
                      body.push(self.init);
                  } else if (self.init) {
                      body.push(make_node(AST_SimpleStatement, self.init, {
                          body: self.init
                      }));
                  }
                  body.push(make_node(AST_SimpleStatement, self.condition, {
                      body: self.condition
                  }));
                  return make_node(AST_BlockStatement, self, { body: body }).optimize(compressor);
              }
          }
      }
      return if_break_in_loop(self, compressor);
  });

  def_optimize(AST_If, function(self, compressor) {
      if (is_empty(self.alternative)) self.alternative = null;

      if (!compressor.option("conditionals")) return self;
      // if condition can be statically determined, drop
      // one of the blocks.  note, statically determined implies
      // “has no side effects”; also it doesn't work for cases like
      // `x && true`, though it probably should.
      var cond = self.condition.evaluate(compressor);
      if (!compressor.option("dead_code") && !(cond instanceof AST_Node)) {
          var orig = self.condition;
          self.condition = make_node_from_constant(cond, orig);
          self.condition = best_of_expression(self.condition.transform(compressor), orig);
      }
      if (compressor.option("dead_code")) {
          if (cond instanceof AST_Node) cond = self.condition.tail_node().evaluate(compressor);
          if (!cond) {
              var body = [];
              trim_unreachable_code(compressor, self.body, body);
              body.push(make_node(AST_SimpleStatement, self.condition, {
                  body: self.condition
              }));
              if (self.alternative) body.push(self.alternative);
              return make_node(AST_BlockStatement, self, { body: body }).optimize(compressor);
          } else if (!(cond instanceof AST_Node)) {
              var body = [];
              body.push(make_node(AST_SimpleStatement, self.condition, {
                  body: self.condition
              }));
              body.push(self.body);
              if (self.alternative) {
                  trim_unreachable_code(compressor, self.alternative, body);
              }
              return make_node(AST_BlockStatement, self, { body: body }).optimize(compressor);
          }
      }
      var negated = self.condition.negate(compressor);
      var self_condition_length = self.condition.size();
      var negated_length = negated.size();
      var negated_is_best = negated_length < self_condition_length;
      if (self.alternative && negated_is_best) {
          negated_is_best = false; // because we already do the switch here.
          // no need to swap values of self_condition_length and negated_length
          // here because they are only used in an equality comparison later on.
          self.condition = negated;
          var tmp = self.body;
          self.body = self.alternative || make_node(AST_EmptyStatement, self);
          self.alternative = tmp;
      }
      if (is_empty(self.body) && is_empty(self.alternative)) {
          return make_node(AST_SimpleStatement, self.condition, {
              body: self.condition.clone()
          }).optimize(compressor);
      }
      if (self.body instanceof AST_SimpleStatement
          && self.alternative instanceof AST_SimpleStatement) {
          return make_node(AST_SimpleStatement, self, {
              body: make_node(AST_Conditional, self, {
                  condition   : self.condition,
                  consequent  : self.body.body,
                  alternative : self.alternative.body
              })
          }).optimize(compressor);
      }
      if (is_empty(self.alternative) && self.body instanceof AST_SimpleStatement) {
          if (self_condition_length === negated_length && !negated_is_best
              && self.condition instanceof AST_Binary && self.condition.operator == "||") {
              // although the code length of self.condition and negated are the same,
              // negated does not require additional surrounding parentheses.
              // see https://github.com/mishoo/UglifyJS2/issues/979
              negated_is_best = true;
          }
          if (negated_is_best) return make_node(AST_SimpleStatement, self, {
              body: make_node(AST_Binary, self, {
                  operator : "||",
                  left     : negated,
                  right    : self.body.body
              })
          }).optimize(compressor);
          return make_node(AST_SimpleStatement, self, {
              body: make_node(AST_Binary, self, {
                  operator : "&&",
                  left     : self.condition,
                  right    : self.body.body
              })
          }).optimize(compressor);
      }
      if (self.body instanceof AST_EmptyStatement
          && self.alternative instanceof AST_SimpleStatement) {
          return make_node(AST_SimpleStatement, self, {
              body: make_node(AST_Binary, self, {
                  operator : "||",
                  left     : self.condition,
                  right    : self.alternative.body
              })
          }).optimize(compressor);
      }
      if (self.body instanceof AST_Exit
          && self.alternative instanceof AST_Exit
          && self.body.TYPE == self.alternative.TYPE) {
          return make_node(self.body.CTOR, self, {
              value: make_node(AST_Conditional, self, {
                  condition   : self.condition,
                  consequent  : self.body.value || make_node(AST_Undefined, self.body),
                  alternative : self.alternative.value || make_node(AST_Undefined, self.alternative)
              }).transform(compressor)
          }).optimize(compressor);
      }
      if (self.body instanceof AST_If
          && !self.body.alternative
          && !self.alternative) {
          self = make_node(AST_If, self, {
              condition: make_node(AST_Binary, self.condition, {
                  operator: "&&",
                  left: self.condition,
                  right: self.body.condition
              }),
              body: self.body.body,
              alternative: null
          });
      }
      if (aborts(self.body)) {
          if (self.alternative) {
              var alt = self.alternative;
              self.alternative = null;
              return make_node(AST_BlockStatement, self, {
                  body: [ self, alt ]
              }).optimize(compressor);
          }
      }
      if (aborts(self.alternative)) {
          var body = self.body;
          self.body = self.alternative;
          self.condition = negated_is_best ? negated : self.condition.negate(compressor);
          self.alternative = null;
          return make_node(AST_BlockStatement, self, {
              body: [ self, body ]
          }).optimize(compressor);
      }
      return self;
  });

  def_optimize(AST_Switch, function(self, compressor) {
      if (!compressor.option("switches")) return self;
      var branch;
      var value = self.expression.evaluate(compressor);
      if (!(value instanceof AST_Node)) {
          var orig = self.expression;
          self.expression = make_node_from_constant(value, orig);
          self.expression = best_of_expression(self.expression.transform(compressor), orig);
      }
      if (!compressor.option("dead_code")) return self;
      if (value instanceof AST_Node) {
          value = self.expression.tail_node().evaluate(compressor);
      }
      var decl = [];
      var body = [];
      var default_branch;
      var exact_match;
      for (var i = 0, len = self.body.length; i < len && !exact_match; i++) {
          branch = self.body[i];
          if (branch instanceof AST_Default) {
              if (!default_branch) {
                  default_branch = branch;
              } else {
                  eliminate_branch(branch, body[body.length - 1]);
              }
          } else if (!(value instanceof AST_Node)) {
              var exp = branch.expression.evaluate(compressor);
              if (!(exp instanceof AST_Node) && exp !== value) {
                  eliminate_branch(branch, body[body.length - 1]);
                  continue;
              }
              if (exp instanceof AST_Node) exp = branch.expression.tail_node().evaluate(compressor);
              if (exp === value) {
                  exact_match = branch;
                  if (default_branch) {
                      var default_index = body.indexOf(default_branch);
                      body.splice(default_index, 1);
                      eliminate_branch(default_branch, body[default_index - 1]);
                      default_branch = null;
                  }
              }
          }
          body.push(branch);
      }
      while (i < len) eliminate_branch(self.body[i++], body[body.length - 1]);
      self.body = body;

      let default_or_exact = default_branch || exact_match;
      default_branch = null;
      exact_match = null;

      // group equivalent branches so they will be located next to each other,
      // that way the next micro-optimization will merge them.
      // ** bail micro-optimization if not a simple switch case with breaks
      if (body.every((branch, i) =>
          (branch === default_or_exact || branch.expression instanceof AST_Constant)
          && (branch.body.length === 0 || aborts(branch) || body.length - 1 === i))
      ) {
          for (let i = 0; i < body.length; i++) {
              const branch = body[i];
              for (let j = i + 1; j < body.length; j++) {
                  const next = body[j];
                  if (next.body.length === 0) continue;
                  const last_branch = j === (body.length - 1);
                  const equivalentBranch = branches_equivalent(next, branch, false);
                  if (equivalentBranch || (last_branch && branches_equivalent(next, branch, true))) {
                      if (!equivalentBranch && last_branch) {
                          next.body.push(make_node(AST_Break));
                      }

                      // let's find previous siblings with inert fallthrough...
                      let x = j - 1;
                      let fallthroughDepth = 0;
                      while (x > i) {
                          if (is_inert_body(body[x--])) {
                              fallthroughDepth++;
                          } else {
                              break;
                          }
                      }

                      const plucked = body.splice(j - fallthroughDepth, 1 + fallthroughDepth);
                      body.splice(i + 1, 0, ...plucked);
                      i += plucked.length;
                  }
              }
          }
      }

      // merge equivalent branches in a row
      for (let i = 0; i < body.length; i++) {
          let branch = body[i];
          if (branch.body.length === 0) continue;
          if (!aborts(branch)) continue;

          for (let j = i + 1; j < body.length; i++, j++) {
              let next = body[j];
              if (next.body.length === 0) continue;
              if (
                  branches_equivalent(next, branch, false)
                  || (j === body.length - 1 && branches_equivalent(next, branch, true))
              ) {
                  branch.body = [];
                  branch = next;
                  continue;
              }
              break;
          }
      }

      // Prune any empty branches at the end of the switch statement.
      {
          let i = body.length - 1;
          for (; i >= 0; i--) {
              let bbody = body[i].body;
              if (is_break(bbody[bbody.length - 1], compressor)) bbody.pop();
              if (!is_inert_body(body[i])) break;
          }
          // i now points to the index of a branch that contains a body. By incrementing, it's
          // pointing to the first branch that's empty.
          i++;
          if (!default_or_exact || body.indexOf(default_or_exact) >= i) {
              // The default behavior is to do nothing. We can take advantage of that to
              // remove all case expressions that are side-effect free that also do
              // nothing, since they'll default to doing nothing. But we can't remove any
              // case expressions before one that would side-effect, since they may cause
              // the side-effect to be skipped.
              for (let j = body.length - 1; j >= i; j--) {
                  let branch = body[j];
                  if (branch === default_or_exact) {
                      default_or_exact = null;
                      body.pop();
                  } else if (!branch.expression.has_side_effects(compressor)) {
                      body.pop();
                  } else {
                      break;
                  }
              }
          }
      }


      // Prune side-effect free branches that fall into default.
      DEFAULT: if (default_or_exact) {
          let default_index = body.indexOf(default_or_exact);
          let default_body_index = default_index;
          for (; default_body_index < body.length - 1; default_body_index++) {
              if (!is_inert_body(body[default_body_index])) break;
          }
          if (default_body_index < body.length - 1) {
              break DEFAULT;
          }

          let side_effect_index = body.length - 1;
          for (; side_effect_index >= 0; side_effect_index--) {
              let branch = body[side_effect_index];
              if (branch === default_or_exact) continue;
              if (branch.expression.has_side_effects(compressor)) break;
          }
          // If the default behavior comes after any side-effect case expressions,
          // then we can fold all side-effect free cases into the default branch.
          // If the side-effect case is after the default, then any side-effect
          // free cases could prevent the side-effect from occurring.
          if (default_body_index > side_effect_index) {
              let prev_body_index = default_index - 1;
              for (; prev_body_index >= 0; prev_body_index--) {
                  if (!is_inert_body(body[prev_body_index])) break;
              }
              let before = Math.max(side_effect_index, prev_body_index) + 1;
              let after = default_index;
              if (side_effect_index > default_index) {
                  // If the default falls into the same body as a side-effect
                  // case, then we need preserve that case and only prune the
                  // cases after it.
                  after = side_effect_index;
                  body[side_effect_index].body = body[default_body_index].body;
              } else {
                  // The default will be the last branch.
                  default_or_exact.body = body[default_body_index].body;
              }

              // Prune everything after the default (or last side-effect case)
              // until the next case with a body.
              body.splice(after + 1, default_body_index - after);
              // Prune everything before the default that falls into it.
              body.splice(before, default_index - before);
          }
      }

      // See if we can remove the switch entirely if all cases (the default) fall into the same case body.
      DEFAULT: if (default_or_exact) {
          let i = body.findIndex(branch => !is_inert_body(branch));
          let caseBody;
          // `i` is equal to one of the following:
          // - `-1`, there is no body in the switch statement.
          // - `body.length - 1`, all cases fall into the same body.
          // - anything else, there are multiple bodies in the switch.
          if (i === body.length - 1) {
              // All cases fall into the case body.
              let branch = body[i];
              if (has_nested_break(self)) break DEFAULT;

              // This is the last case body, and we've already pruned any breaks, so it's
              // safe to hoist.
              caseBody = make_node(AST_BlockStatement, branch, {
                  body: branch.body
              });
              branch.body = [];
          } else if (i !== -1) {
              // If there are multiple bodies, then we cannot optimize anything.
              break DEFAULT;
          }

          let sideEffect = body.find(branch => {
              return (
                  branch !== default_or_exact
                  && branch.expression.has_side_effects(compressor)
              );
          });
          // If no cases cause a side-effect, we can eliminate the switch entirely.
          if (!sideEffect) {
              return make_node(AST_BlockStatement, self, {
                  body: decl.concat(
                      statement(self.expression),
                      default_or_exact.expression ? statement(default_or_exact.expression) : [],
                      caseBody || []
                  )
              }).optimize(compressor);
          }

          // If we're this far, either there was no body or all cases fell into the same body.
          // If there was no body, then we don't need a default branch (because the default is
          // do nothing). If there was a body, we'll extract it to after the switch, so the
          // switch's new default is to do nothing and we can still prune it.
          const default_index = body.indexOf(default_or_exact);
          body.splice(default_index, 1);
          default_or_exact = null;

          if (caseBody) {
              // Recurse into switch statement one more time so that we can append the case body
              // outside of the switch. This recursion will only happen once since we've pruned
              // the default case.
              return make_node(AST_BlockStatement, self, {
                  body: decl.concat(self, caseBody)
              }).optimize(compressor);
          }
          // If we fall here, there is a default branch somewhere, there are no case bodies,
          // and there's a side-effect somewhere. Just let the below paths take care of it.
      }

      if (body.length > 0) {
          body[0].body = decl.concat(body[0].body);
      }

      if (body.length == 0) {
          return make_node(AST_BlockStatement, self, {
              body: decl.concat(statement(self.expression))
          }).optimize(compressor);
      }
      if (body.length == 1 && !has_nested_break(self)) {
          // This is the last case body, and we've already pruned any breaks, so it's
          // safe to hoist.
          let branch = body[0];
          return make_node(AST_If, self, {
              condition: make_node(AST_Binary, self, {
                  operator: "===",
                  left: self.expression,
                  right: branch.expression,
              }),
              body: make_node(AST_BlockStatement, branch, {
                  body: branch.body
              }),
              alternative: null
          }).optimize(compressor);
      }
      if (body.length === 2 && default_or_exact && !has_nested_break(self)) {
          let branch = body[0] === default_or_exact ? body[1] : body[0];
          let exact_exp = default_or_exact.expression && statement(default_or_exact.expression);
          if (aborts(body[0])) {
              // Only the first branch body could have a break (at the last statement)
              let first = body[0];
              if (is_break(first.body[first.body.length - 1], compressor)) {
                  first.body.pop();
              }
              return make_node(AST_If, self, {
                  condition: make_node(AST_Binary, self, {
                      operator: "===",
                      left: self.expression,
                      right: branch.expression,
                  }),
                  body: make_node(AST_BlockStatement, branch, {
                      body: branch.body
                  }),
                  alternative: make_node(AST_BlockStatement, default_or_exact, {
                      body: [].concat(
                          exact_exp || [],
                          default_or_exact.body
                      )
                  })
              }).optimize(compressor);
          }
          let operator = "===";
          let consequent = make_node(AST_BlockStatement, branch, {
              body: branch.body,
          });
          let always = make_node(AST_BlockStatement, default_or_exact, {
              body: [].concat(
                  exact_exp || [],
                  default_or_exact.body
              )
          });
          if (body[0] === default_or_exact) {
              operator = "!==";
              let tmp = always;
              always = consequent;
              consequent = tmp;
          }
          return make_node(AST_BlockStatement, self, {
              body: [
                  make_node(AST_If, self, {
                      condition: make_node(AST_Binary, self, {
                          operator: operator,
                          left: self.expression,
                          right: branch.expression,
                      }),
                      body: consequent,
                      alternative: null
                  })
              ].concat(always)
          }).optimize(compressor);
      }
      return self;

      function eliminate_branch(branch, prev) {
          if (prev && !aborts(prev)) {
              prev.body = prev.body.concat(branch.body);
          } else {
              trim_unreachable_code(compressor, branch, decl);
          }
      }
      function branches_equivalent(branch, prev, insertBreak) {
          let bbody = branch.body;
          let pbody = prev.body;
          if (insertBreak) {
              bbody = bbody.concat(make_node(AST_Break));
          }
          if (bbody.length !== pbody.length) return false;
          let bblock = make_node(AST_BlockStatement, branch, { body: bbody });
          let pblock = make_node(AST_BlockStatement, prev, { body: pbody });
          return bblock.equivalent_to(pblock);
      }
      function statement(expression) {
          return make_node(AST_SimpleStatement, expression, {
              body: expression
          });
      }
      function has_nested_break(root) {
          let has_break = false;
          let tw = new TreeWalker(node => {
              if (has_break) return true;
              if (node instanceof AST_Lambda) return true;
              if (node instanceof AST_SimpleStatement) return true;
              if (!is_break(node, tw)) return;
              let parent = tw.parent();
              if (
                  parent instanceof AST_SwitchBranch
                  && parent.body[parent.body.length - 1] === node
              ) {
                  return;
              }
              has_break = true;
          });
          root.walk(tw);
          return has_break;
      }
      function is_break(node, stack) {
          return node instanceof AST_Break
              && stack.loopcontrol_target(node) === self;
      }
      function is_inert_body(branch) {
          return !aborts(branch) && !make_node(AST_BlockStatement, branch, {
              body: branch.body
          }).has_side_effects(compressor);
      }
  });

  def_optimize(AST_Try, function(self, compressor) {
      tighten_body(self.body, compressor);
      if (self.bcatch && self.bfinally && self.bfinally.body.every(is_empty)) self.bfinally = null;
      if (compressor.option("dead_code") && self.body.every(is_empty)) {
          var body = [];
          if (self.bcatch) {
              trim_unreachable_code(compressor, self.bcatch, body);
          }
          if (self.bfinally) body.push(...self.bfinally.body);
          return make_node(AST_BlockStatement, self, {
              body: body
          }).optimize(compressor);
      }
      return self;
  });

  AST_Definitions.DEFMETHOD("remove_initializers", function() {
      var decls = [];
      this.definitions.forEach(function(def) {
          if (def.name instanceof AST_SymbolDeclaration) {
              def.value = null;
              decls.push(def);
          } else {
              walk(def.name, node => {
                  if (node instanceof AST_SymbolDeclaration) {
                      decls.push(make_node(AST_VarDef, def, {
                          name: node,
                          value: null
                      }));
                  }
              });
          }
      });
      this.definitions = decls;
  });

  AST_Definitions.DEFMETHOD("to_assignments", function(compressor) {
      var reduce_vars = compressor.option("reduce_vars");
      var assignments = [];

      for (const def of this.definitions) {
          if (def.value) {
              var name = make_node(AST_SymbolRef, def.name, def.name);
              assignments.push(make_node(AST_Assign, def, {
                  operator : "=",
                  logical: false,
                  left     : name,
                  right    : def.value
              }));
              if (reduce_vars) name.definition().fixed = false;
          } else if (def.value) {
              // Because it's a destructuring, do not turn into an assignment.
              var varDef = make_node(AST_VarDef, def, {
                  name: def.name,
                  value: def.value
              });
              var var_ = make_node(AST_Var, def, {
                  definitions: [ varDef ]
              });
              assignments.push(var_);
          }
          const thedef = def.name.definition();
          thedef.eliminated++;
          thedef.replaced--;
      }

      if (assignments.length == 0) return null;
      return make_sequence(this, assignments);
  });

  def_optimize(AST_Definitions, function(self) {
      if (self.definitions.length == 0)
          return make_node(AST_EmptyStatement, self);
      return self;
  });

  def_optimize(AST_VarDef, function(self, compressor) {
      if (
          self.name instanceof AST_SymbolLet
          && self.value != null
          && is_undefined(self.value, compressor)
      ) {
          self.value = null;
      }
      return self;
  });

  def_optimize(AST_Import, function(self) {
      return self;
  });

  def_optimize(AST_Call, function(self, compressor) {
      var exp = self.expression;
      var fn = exp;
      inline_array_like_spread(self.args);
      var simple_args = self.args.every((arg) =>
          !(arg instanceof AST_Expansion)
      );

      if (compressor.option("reduce_vars")
          && fn instanceof AST_SymbolRef
          && !has_annotation(self, _NOINLINE)
      ) {
          const fixed = fn.fixed_value();
          if (!retain_top_func(fixed, compressor)) {
              fn = fixed;
          }
      }

      var is_func = fn instanceof AST_Lambda;

      if (is_func && fn.pinned()) return self;

      if (compressor.option("unused")
          && simple_args
          && is_func
          && !fn.uses_arguments) {
          var pos = 0, last = 0;
          for (var i = 0, len = self.args.length; i < len; i++) {
              if (fn.argnames[i] instanceof AST_Expansion) {
                  if (has_flag(fn.argnames[i].expression, UNUSED)) while (i < len) {
                      var node = self.args[i++].drop_side_effect_free(compressor);
                      if (node) {
                          self.args[pos++] = node;
                      }
                  } else while (i < len) {
                      self.args[pos++] = self.args[i++];
                  }
                  last = pos;
                  break;
              }
              var trim = i >= fn.argnames.length;
              if (trim || has_flag(fn.argnames[i], UNUSED)) {
                  var node = self.args[i].drop_side_effect_free(compressor);
                  if (node) {
                      self.args[pos++] = node;
                  } else if (!trim) {
                      self.args[pos++] = make_node(AST_Number, self.args[i], {
                          value: 0
                      });
                      continue;
                  }
              } else {
                  self.args[pos++] = self.args[i];
              }
              last = pos;
          }
          self.args.length = last;
      }

      if (compressor.option("unsafe")) {
          if (exp instanceof AST_Dot && exp.start.value === "Array" && exp.property === "from" && self.args.length === 1) {
              const [argument] = self.args;
              if (argument instanceof AST_Array) {
                  return make_node(AST_Array, argument, {
                      elements: argument.elements
                  }).optimize(compressor);
              }
          }
          if (is_undeclared_ref(exp)) switch (exp.name) {
            case "Array":
              if (self.args.length != 1) {
                  return make_node(AST_Array, self, {
                      elements: self.args
                  }).optimize(compressor);
              } else if (self.args[0] instanceof AST_Number && self.args[0].value <= 11) {
                  const elements = [];
                  for (let i = 0; i < self.args[0].value; i++) elements.push(new AST_Hole);
                  return new AST_Array({ elements });
              }
              break;
            case "Object":
              if (self.args.length == 0) {
                  return make_node(AST_Object, self, {
                      properties: []
                  });
              }
              break;
            case "String":
              if (self.args.length == 0) return make_node(AST_String, self, {
                  value: ""
              });
              if (self.args.length <= 1) return make_node(AST_Binary, self, {
                  left: self.args[0],
                  operator: "+",
                  right: make_node(AST_String, self, { value: "" })
              }).optimize(compressor);
              break;
            case "Number":
              if (self.args.length == 0) return make_node(AST_Number, self, {
                  value: 0
              });
              if (self.args.length == 1 && compressor.option("unsafe_math")) {
                  return make_node(AST_UnaryPrefix, self, {
                      expression: self.args[0],
                      operator: "+"
                  }).optimize(compressor);
              }
              break;
            case "Symbol":
              if (self.args.length == 1 && self.args[0] instanceof AST_String && compressor.option("unsafe_symbols"))
                  self.args.length = 0;
                  break;
            case "Boolean":
              if (self.args.length == 0) return make_node(AST_False, self);
              if (self.args.length == 1) return make_node(AST_UnaryPrefix, self, {
                  expression: make_node(AST_UnaryPrefix, self, {
                      expression: self.args[0],
                      operator: "!"
                  }),
                  operator: "!"
              }).optimize(compressor);
              break;
            case "RegExp":
              var params = [];
              if (self.args.length >= 1
                  && self.args.length <= 2
                  && self.args.every((arg) => {
                      var value = arg.evaluate(compressor);
                      params.push(value);
                      return arg !== value;
                  })
                  && regexp_is_safe(params[0])
              ) {
                  let [ source, flags ] = params;
                  source = regexp_source_fix(new RegExp(source).source);
                  const rx = make_node(AST_RegExp, self, {
                      value: { source, flags }
                  });
                  if (rx._eval(compressor) !== rx) {
                      return rx;
                  }
              }
              break;
          } else if (exp instanceof AST_Dot) switch(exp.property) {
            case "toString":
              if (self.args.length == 0 && !exp.expression.may_throw_on_access(compressor)) {
                  return make_node(AST_Binary, self, {
                      left: make_node(AST_String, self, { value: "" }),
                      operator: "+",
                      right: exp.expression
                  }).optimize(compressor);
              }
              break;
            case "join":
              if (exp.expression instanceof AST_Array) EXIT: {
                  var separator;
                  if (self.args.length > 0) {
                      separator = self.args[0].evaluate(compressor);
                      if (separator === self.args[0]) break EXIT; // not a constant
                  }
                  var elements = [];
                  var consts = [];
                  for (var i = 0, len = exp.expression.elements.length; i < len; i++) {
                      var el = exp.expression.elements[i];
                      if (el instanceof AST_Expansion) break EXIT;
                      var value = el.evaluate(compressor);
                      if (value !== el) {
                          consts.push(value);
                      } else {
                          if (consts.length > 0) {
                              elements.push(make_node(AST_String, self, {
                                  value: consts.join(separator)
                              }));
                              consts.length = 0;
                          }
                          elements.push(el);
                      }
                  }
                  if (consts.length > 0) {
                      elements.push(make_node(AST_String, self, {
                          value: consts.join(separator)
                      }));
                  }
                  if (elements.length == 0) return make_node(AST_String, self, { value: "" });
                  if (elements.length == 1) {
                      if (elements[0].is_string(compressor)) {
                          return elements[0];
                      }
                      return make_node(AST_Binary, elements[0], {
                          operator : "+",
                          left     : make_node(AST_String, self, { value: "" }),
                          right    : elements[0]
                      });
                  }
                  if (separator == "") {
                      var first;
                      if (elements[0].is_string(compressor)
                          || elements[1].is_string(compressor)) {
                          first = elements.shift();
                      } else {
                          first = make_node(AST_String, self, { value: "" });
                      }
                      return elements.reduce(function(prev, el) {
                          return make_node(AST_Binary, el, {
                              operator : "+",
                              left     : prev,
                              right    : el
                          });
                      }, first).optimize(compressor);
                  }
                  // need this awkward cloning to not affect original element
                  // best_of will decide which one to get through.
                  var node = self.clone();
                  node.expression = node.expression.clone();
                  node.expression.expression = node.expression.expression.clone();
                  node.expression.expression.elements = elements;
                  return best_of(compressor, self, node);
              }
              break;
            case "charAt":
              if (exp.expression.is_string(compressor)) {
                  var arg = self.args[0];
                  var index = arg ? arg.evaluate(compressor) : 0;
                  if (index !== arg) {
                      return make_node(AST_Sub, exp, {
                          expression: exp.expression,
                          property: make_node_from_constant(index | 0, arg || exp)
                      }).optimize(compressor);
                  }
              }
              break;
            case "apply":
              if (self.args.length == 2 && self.args[1] instanceof AST_Array) {
                  var args = self.args[1].elements.slice();
                  args.unshift(self.args[0]);
                  return make_node(AST_Call, self, {
                      expression: make_node(AST_Dot, exp, {
                          expression: exp.expression,
                          optional: false,
                          property: "call"
                      }),
                      args: args
                  }).optimize(compressor);
              }
              break;
            case "call":
              var func = exp.expression;
              if (func instanceof AST_SymbolRef) {
                  func = func.fixed_value();
              }
              if (func instanceof AST_Lambda && !func.contains_this()) {
                  return (self.args.length ? make_sequence(this, [
                      self.args[0],
                      make_node(AST_Call, self, {
                          expression: exp.expression,
                          args: self.args.slice(1)
                      })
                  ]) : make_node(AST_Call, self, {
                      expression: exp.expression,
                      args: []
                  })).optimize(compressor);
              }
              break;
          }
      }

      if (compressor.option("unsafe_Function")
          && is_undeclared_ref(exp)
          && exp.name == "Function") {
          // new Function() => function(){}
          if (self.args.length == 0) return make_node(AST_Function, self, {
              argnames: [],
              body: []
          }).optimize(compressor);
          var nth_identifier = compressor.mangle_options && compressor.mangle_options.nth_identifier || base54;
          if (self.args.every((x) => x instanceof AST_String)) {
              // quite a corner-case, but we can handle it:
              //   https://github.com/mishoo/UglifyJS2/issues/203
              // if the code argument is a constant, then we can minify it.
              try {
                  var code = "n(function(" + self.args.slice(0, -1).map(function(arg) {
                      return arg.value;
                  }).join(",") + "){" + self.args[self.args.length - 1].value + "})";
                  var ast = parse(code);
                  var mangle = { ie8: compressor.option("ie8"), nth_identifier: nth_identifier };
                  ast.figure_out_scope(mangle);
                  var comp = new Compressor(compressor.options, {
                      mangle_options: compressor.mangle_options
                  });
                  ast = ast.transform(comp);
                  ast.figure_out_scope(mangle);
                  ast.compute_char_frequency(mangle);
                  ast.mangle_names(mangle);
                  var fun;
                  walk(ast, node => {
                      if (is_func_expr(node)) {
                          fun = node;
                          return walk_abort;
                      }
                  });
                  var code = OutputStream();
                  AST_BlockStatement.prototype._codegen.call(fun, fun, code);
                  self.args = [
                      make_node(AST_String, self, {
                          value: fun.argnames.map(function(arg) {
                              return arg.print_to_string();
                          }).join(",")
                      }),
                      make_node(AST_String, self.args[self.args.length - 1], {
                          value: code.get().replace(/^{|}$/g, "")
                      })
                  ];
                  return self;
              } catch (ex) {
                  if (!(ex instanceof JS_Parse_Error)) {
                      throw ex;
                  }

                  // Otherwise, it crashes at runtime. Or maybe it's nonstandard syntax.
              }
          }
      }

      return inline_into_call(self, fn, compressor);
  });

  def_optimize(AST_New, function(self, compressor) {
      if (
          compressor.option("unsafe") &&
          is_undeclared_ref(self.expression) &&
          ["Object", "RegExp", "Function", "Error", "Array"].includes(self.expression.name)
      ) return make_node(AST_Call, self, self).transform(compressor);
      return self;
  });

  def_optimize(AST_Sequence, function(self, compressor) {
      if (!compressor.option("side_effects")) return self;
      var expressions = [];
      filter_for_side_effects();
      var end = expressions.length - 1;
      trim_right_for_undefined();
      if (end == 0) {
          self = maintain_this_binding(compressor.parent(), compressor.self(), expressions[0]);
          if (!(self instanceof AST_Sequence)) self = self.optimize(compressor);
          return self;
      }
      self.expressions = expressions;
      return self;

      function filter_for_side_effects() {
          var first = first_in_statement(compressor);
          var last = self.expressions.length - 1;
          self.expressions.forEach(function(expr, index) {
              if (index < last) expr = expr.drop_side_effect_free(compressor, first);
              if (expr) {
                  merge_sequence(expressions, expr);
                  first = false;
              }
          });
      }

      function trim_right_for_undefined() {
          while (end > 0 && is_undefined(expressions[end], compressor)) end--;
          if (end < expressions.length - 1) {
              expressions[end] = make_node(AST_UnaryPrefix, self, {
                  operator   : "void",
                  expression : expressions[end]
              });
              expressions.length = end + 1;
          }
      }
  });

  AST_Unary.DEFMETHOD("lift_sequences", function(compressor) {
      if (compressor.option("sequences")) {
          if (this.expression instanceof AST_Sequence) {
              var x = this.expression.expressions.slice();
              var e = this.clone();
              e.expression = x.pop();
              x.push(e);
              return make_sequence(this, x).optimize(compressor);
          }
      }
      return this;
  });

  def_optimize(AST_UnaryPostfix, function(self, compressor) {
      return self.lift_sequences(compressor);
  });

  def_optimize(AST_UnaryPrefix, function(self, compressor) {
      var e = self.expression;
      if (
          self.operator == "delete" &&
          !(
              e instanceof AST_SymbolRef ||
              e instanceof AST_PropAccess ||
              e instanceof AST_Chain ||
              is_identifier_atom(e)
          )
      ) {
          return make_sequence(self, [e, make_node(AST_True, self)]).optimize(compressor);
      }
      var seq = self.lift_sequences(compressor);
      if (seq !== self) {
          return seq;
      }
      if (compressor.option("side_effects") && self.operator == "void") {
          e = e.drop_side_effect_free(compressor);
          if (e) {
              self.expression = e;
              return self;
          } else {
              return make_node(AST_Undefined, self).optimize(compressor);
          }
      }
      if (compressor.in_boolean_context()) {
          switch (self.operator) {
            case "!":
              if (e instanceof AST_UnaryPrefix && e.operator == "!") {
                  // !!foo ==> foo, if we're in boolean context
                  return e.expression;
              }
              if (e instanceof AST_Binary) {
                  self = best_of(compressor, self, e.negate(compressor, first_in_statement(compressor)));
              }
              break;
            case "typeof":
              // typeof always returns a non-empty string, thus it's
              // always true in booleans
              // And we don't need to check if it's undeclared, because in typeof, that's OK
              return (e instanceof AST_SymbolRef ? make_node(AST_True, self) : make_sequence(self, [
                  e,
                  make_node(AST_True, self)
              ])).optimize(compressor);
          }
      }
      if (self.operator == "-" && e instanceof AST_Infinity) {
          e = e.transform(compressor);
      }
      if (e instanceof AST_Binary
          && (self.operator == "+" || self.operator == "-")
          && (e.operator == "*" || e.operator == "/" || e.operator == "%")) {
          return make_node(AST_Binary, self, {
              operator: e.operator,
              left: make_node(AST_UnaryPrefix, e.left, {
                  operator: self.operator,
                  expression: e.left
              }),
              right: e.right
          });
      }
      // avoids infinite recursion of numerals
      if (self.operator != "-"
          || !(e instanceof AST_Number || e instanceof AST_Infinity || e instanceof AST_BigInt)) {
          var ev = self.evaluate(compressor);
          if (ev !== self) {
              ev = make_node_from_constant(ev, self).optimize(compressor);
              return best_of(compressor, ev, self);
          }
      }
      return self;
  });

  AST_Binary.DEFMETHOD("lift_sequences", function(compressor) {
      if (compressor.option("sequences")) {
          if (this.left instanceof AST_Sequence) {
              var x = this.left.expressions.slice();
              var e = this.clone();
              e.left = x.pop();
              x.push(e);
              return make_sequence(this, x).optimize(compressor);
          }
          if (this.right instanceof AST_Sequence && !this.left.has_side_effects(compressor)) {
              var assign = this.operator == "=" && this.left instanceof AST_SymbolRef;
              var x = this.right.expressions;
              var last = x.length - 1;
              for (var i = 0; i < last; i++) {
                  if (!assign && x[i].has_side_effects(compressor)) break;
              }
              if (i == last) {
                  x = x.slice();
                  var e = this.clone();
                  e.right = x.pop();
                  x.push(e);
                  return make_sequence(this, x).optimize(compressor);
              } else if (i > 0) {
                  var e = this.clone();
                  e.right = make_sequence(this.right, x.slice(i));
                  x = x.slice(0, i);
                  x.push(e);
                  return make_sequence(this, x).optimize(compressor);
              }
          }
      }
      return this;
  });

  var commutativeOperators = makePredicate("== === != !== * & | ^");
  function is_object(node) {
      return node instanceof AST_Array
          || node instanceof AST_Lambda
          || node instanceof AST_Object
          || node instanceof AST_Class;
  }

  def_optimize(AST_Binary, function(self, compressor) {
      function reversible() {
          return self.left.is_constant()
              || self.right.is_constant()
              || !self.left.has_side_effects(compressor)
                  && !self.right.has_side_effects(compressor);
      }
      function reverse(op) {
          if (reversible()) {
              if (op) self.operator = op;
              var tmp = self.left;
              self.left = self.right;
              self.right = tmp;
          }
      }
      if (commutativeOperators.has(self.operator)) {
          if (self.right.is_constant()
              && !self.left.is_constant()) {
              // if right is a constant, whatever side effects the
              // left side might have could not influence the
              // result.  hence, force switch.

              if (!(self.left instanceof AST_Binary
                    && PRECEDENCE[self.left.operator] >= PRECEDENCE[self.operator])) {
                  reverse();
              }
          }
      }
      self = self.lift_sequences(compressor);
      if (compressor.option("comparisons")) switch (self.operator) {
        case "===":
        case "!==":
          var is_strict_comparison = true;
          if ((self.left.is_string(compressor) && self.right.is_string(compressor)) ||
              (self.left.is_number(compressor) && self.right.is_number(compressor)) ||
              (self.left.is_boolean() && self.right.is_boolean()) ||
              self.left.equivalent_to(self.right)) {
              self.operator = self.operator.substr(0, 2);
          }
          // XXX: intentionally falling down to the next case
        case "==":
        case "!=":
          // void 0 == x => null == x
          if (!is_strict_comparison && is_undefined(self.left, compressor)) {
              self.left = make_node(AST_Null, self.left);
          } else if (compressor.option("typeofs")
              // "undefined" == typeof x => undefined === x
              && self.left instanceof AST_String
              && self.left.value == "undefined"
              && self.right instanceof AST_UnaryPrefix
              && self.right.operator == "typeof") {
              var expr = self.right.expression;
              if (expr instanceof AST_SymbolRef ? expr.is_declared(compressor)
                  : !(expr instanceof AST_PropAccess && compressor.option("ie8"))) {
                  self.right = expr;
                  self.left = make_node(AST_Undefined, self.left).optimize(compressor);
                  if (self.operator.length == 2) self.operator += "=";
              }
          } else if (self.left instanceof AST_SymbolRef
              // obj !== obj => false
              && self.right instanceof AST_SymbolRef
              && self.left.definition() === self.right.definition()
              && is_object(self.left.fixed_value())) {
              return make_node(self.operator[0] == "=" ? AST_True : AST_False, self);
          }
          break;
        case "&&":
        case "||":
          var lhs = self.left;
          if (lhs.operator == self.operator) {
              lhs = lhs.right;
          }
          if (lhs instanceof AST_Binary
              && lhs.operator == (self.operator == "&&" ? "!==" : "===")
              && self.right instanceof AST_Binary
              && lhs.operator == self.right.operator
              && (is_undefined(lhs.left, compressor) && self.right.left instanceof AST_Null
                  || lhs.left instanceof AST_Null && is_undefined(self.right.left, compressor))
              && !lhs.right.has_side_effects(compressor)
              && lhs.right.equivalent_to(self.right.right)) {
              var combined = make_node(AST_Binary, self, {
                  operator: lhs.operator.slice(0, -1),
                  left: make_node(AST_Null, self),
                  right: lhs.right
              });
              if (lhs !== self.left) {
                  combined = make_node(AST_Binary, self, {
                      operator: self.operator,
                      left: self.left.left,
                      right: combined
                  });
              }
              return combined;
          }
          break;
      }
      if (self.operator == "+" && compressor.in_boolean_context()) {
          var ll = self.left.evaluate(compressor);
          var rr = self.right.evaluate(compressor);
          if (ll && typeof ll == "string") {
              return make_sequence(self, [
                  self.right,
                  make_node(AST_True, self)
              ]).optimize(compressor);
          }
          if (rr && typeof rr == "string") {
              return make_sequence(self, [
                  self.left,
                  make_node(AST_True, self)
              ]).optimize(compressor);
          }
      }
      if (compressor.option("comparisons") && self.is_boolean()) {
          if (!(compressor.parent() instanceof AST_Binary)
              || compressor.parent() instanceof AST_Assign) {
              var negated = make_node(AST_UnaryPrefix, self, {
                  operator: "!",
                  expression: self.negate(compressor, first_in_statement(compressor))
              });
              self = best_of(compressor, self, negated);
          }
          if (compressor.option("unsafe_comps")) {
              switch (self.operator) {
                case "<": reverse(">"); break;
                case "<=": reverse(">="); break;
              }
          }
      }
      if (self.operator == "+") {
          if (self.right instanceof AST_String
              && self.right.getValue() == ""
              && self.left.is_string(compressor)) {
              return self.left;
          }
          if (self.left instanceof AST_String
              && self.left.getValue() == ""
              && self.right.is_string(compressor)) {
              return self.right;
          }
          if (self.left instanceof AST_Binary
              && self.left.operator == "+"
              && self.left.left instanceof AST_String
              && self.left.left.getValue() == ""
              && self.right.is_string(compressor)) {
              self.left = self.left.right;
              return self;
          }
      }
      if (compressor.option("evaluate")) {
          switch (self.operator) {
            case "&&":
              var ll = has_flag(self.left, TRUTHY)
                  ? true
                  : has_flag(self.left, FALSY)
                      ? false
                      : self.left.evaluate(compressor);
              if (!ll) {
                  return maintain_this_binding(compressor.parent(), compressor.self(), self.left).optimize(compressor);
              } else if (!(ll instanceof AST_Node)) {
                  return make_sequence(self, [ self.left, self.right ]).optimize(compressor);
              }
              var rr = self.right.evaluate(compressor);
              if (!rr) {
                  if (compressor.in_boolean_context()) {
                      return make_sequence(self, [
                          self.left,
                          make_node(AST_False, self)
                      ]).optimize(compressor);
                  } else {
                      set_flag(self, FALSY);
                  }
              } else if (!(rr instanceof AST_Node)) {
                  var parent = compressor.parent();
                  if (parent.operator == "&&" && parent.left === compressor.self() || compressor.in_boolean_context()) {
                      return self.left.optimize(compressor);
                  }
              }
              // x || false && y ---> x ? y : false
              if (self.left.operator == "||") {
                  var lr = self.left.right.evaluate(compressor);
                  if (!lr) return make_node(AST_Conditional, self, {
                      condition: self.left.left,
                      consequent: self.right,
                      alternative: self.left.right
                  }).optimize(compressor);
              }
              break;
            case "||":
              var ll = has_flag(self.left, TRUTHY)
                ? true
                : has_flag(self.left, FALSY)
                  ? false
                  : self.left.evaluate(compressor);
              if (!ll) {
                  return make_sequence(self, [ self.left, self.right ]).optimize(compressor);
              } else if (!(ll instanceof AST_Node)) {
                  return maintain_this_binding(compressor.parent(), compressor.self(), self.left).optimize(compressor);
              }
              var rr = self.right.evaluate(compressor);
              if (!rr) {
                  var parent = compressor.parent();
                  if (parent.operator == "||" && parent.left === compressor.self() || compressor.in_boolean_context()) {
                      return self.left.optimize(compressor);
                  }
              } else if (!(rr instanceof AST_Node)) {
                  if (compressor.in_boolean_context()) {
                      return make_sequence(self, [
                          self.left,
                          make_node(AST_True, self)
                      ]).optimize(compressor);
                  } else {
                      set_flag(self, TRUTHY);
                  }
              }
              if (self.left.operator == "&&") {
                  var lr = self.left.right.evaluate(compressor);
                  if (lr && !(lr instanceof AST_Node)) return make_node(AST_Conditional, self, {
                      condition: self.left.left,
                      consequent: self.left.right,
                      alternative: self.right
                  }).optimize(compressor);
              }
              break;
            case "??":
              if (is_nullish(self.left, compressor)) {
                  return self.right;
              }

              var ll = self.left.evaluate(compressor);
              if (!(ll instanceof AST_Node)) {
                  // if we know the value for sure we can simply compute right away.
                  return ll == null ? self.right : self.left;
              }

              if (compressor.in_boolean_context()) {
                  const rr = self.right.evaluate(compressor);
                  if (!(rr instanceof AST_Node) && !rr) {
                      return self.left;
                  }
              }
          }
          var associative = true;
          switch (self.operator) {
            case "+":
              // (x + "foo") + "bar" => x + "foobar"
              if (self.right instanceof AST_Constant
                  && self.left instanceof AST_Binary
                  && self.left.operator == "+"
                  && self.left.is_string(compressor)) {
                  var binary = make_node(AST_Binary, self, {
                      operator: "+",
                      left: self.left.right,
                      right: self.right,
                  });
                  var r = binary.optimize(compressor);
                  if (binary !== r) {
                      self = make_node(AST_Binary, self, {
                          operator: "+",
                          left: self.left.left,
                          right: r
                      });
                  }
              }
              // (x + "foo") + ("bar" + y) => (x + "foobar") + y
              if (self.left instanceof AST_Binary
                  && self.left.operator == "+"
                  && self.left.is_string(compressor)
                  && self.right instanceof AST_Binary
                  && self.right.operator == "+"
                  && self.right.is_string(compressor)) {
                  var binary = make_node(AST_Binary, self, {
                      operator: "+",
                      left: self.left.right,
                      right: self.right.left,
                  });
                  var m = binary.optimize(compressor);
                  if (binary !== m) {
                      self = make_node(AST_Binary, self, {
                          operator: "+",
                          left: make_node(AST_Binary, self.left, {
                              operator: "+",
                              left: self.left.left,
                              right: m
                          }),
                          right: self.right.right
                      });
                  }
              }
              // a + -b => a - b
              if (self.right instanceof AST_UnaryPrefix
                  && self.right.operator == "-"
                  && self.left.is_number(compressor)) {
                  self = make_node(AST_Binary, self, {
                      operator: "-",
                      left: self.left,
                      right: self.right.expression
                  });
                  break;
              }
              // -a + b => b - a
              if (self.left instanceof AST_UnaryPrefix
                  && self.left.operator == "-"
                  && reversible()
                  && self.right.is_number(compressor)) {
                  self = make_node(AST_Binary, self, {
                      operator: "-",
                      left: self.right,
                      right: self.left.expression
                  });
                  break;
              }
              // `foo${bar}baz` + 1 => `foo${bar}baz1`
              if (self.left instanceof AST_TemplateString) {
                  var l = self.left;
                  var r = self.right.evaluate(compressor);
                  if (r != self.right) {
                      l.segments[l.segments.length - 1].value += String(r);
                      return l;
                  }
              }
              // 1 + `foo${bar}baz` => `1foo${bar}baz`
              if (self.right instanceof AST_TemplateString) {
                  var r = self.right;
                  var l = self.left.evaluate(compressor);
                  if (l != self.left) {
                      r.segments[0].value = String(l) + r.segments[0].value;
                      return r;
                  }
              }
              // `1${bar}2` + `foo${bar}baz` => `1${bar}2foo${bar}baz`
              if (self.left instanceof AST_TemplateString
                  && self.right instanceof AST_TemplateString) {
                  var l = self.left;
                  var segments = l.segments;
                  var r = self.right;
                  segments[segments.length - 1].value += r.segments[0].value;
                  for (var i = 1; i < r.segments.length; i++) {
                      segments.push(r.segments[i]);
                  }
                  return l;
              }
            case "*":
              associative = compressor.option("unsafe_math");
            case "&":
            case "|":
            case "^":
              // a + +b => +b + a
              if (self.left.is_number(compressor)
                  && self.right.is_number(compressor)
                  && reversible()
                  && !(self.left instanceof AST_Binary
                      && self.left.operator != self.operator
                      && PRECEDENCE[self.left.operator] >= PRECEDENCE[self.operator])) {
                  var reversed = make_node(AST_Binary, self, {
                      operator: self.operator,
                      left: self.right,
                      right: self.left
                  });
                  if (self.right instanceof AST_Constant
                      && !(self.left instanceof AST_Constant)) {
                      self = best_of(compressor, reversed, self);
                  } else {
                      self = best_of(compressor, self, reversed);
                  }
              }
              if (associative && self.is_number(compressor)) {
                  // a + (b + c) => (a + b) + c
                  if (self.right instanceof AST_Binary
                      && self.right.operator == self.operator) {
                      self = make_node(AST_Binary, self, {
                          operator: self.operator,
                          left: make_node(AST_Binary, self.left, {
                              operator: self.operator,
                              left: self.left,
                              right: self.right.left,
                              start: self.left.start,
                              end: self.right.left.end
                          }),
                          right: self.right.right
                      });
                  }
                  // (n + 2) + 3 => 5 + n
                  // (2 * n) * 3 => 6 + n
                  if (self.right instanceof AST_Constant
                      && self.left instanceof AST_Binary
                      && self.left.operator == self.operator) {
                      if (self.left.left instanceof AST_Constant) {
                          self = make_node(AST_Binary, self, {
                              operator: self.operator,
                              left: make_node(AST_Binary, self.left, {
                                  operator: self.operator,
                                  left: self.left.left,
                                  right: self.right,
                                  start: self.left.left.start,
                                  end: self.right.end
                              }),
                              right: self.left.right
                          });
                      } else if (self.left.right instanceof AST_Constant) {
                          self = make_node(AST_Binary, self, {
                              operator: self.operator,
                              left: make_node(AST_Binary, self.left, {
                                  operator: self.operator,
                                  left: self.left.right,
                                  right: self.right,
                                  start: self.left.right.start,
                                  end: self.right.end
                              }),
                              right: self.left.left
                          });
                      }
                  }
                  // (a | 1) | (2 | d) => (3 | a) | b
                  if (self.left instanceof AST_Binary
                      && self.left.operator == self.operator
                      && self.left.right instanceof AST_Constant
                      && self.right instanceof AST_Binary
                      && self.right.operator == self.operator
                      && self.right.left instanceof AST_Constant) {
                      self = make_node(AST_Binary, self, {
                          operator: self.operator,
                          left: make_node(AST_Binary, self.left, {
                              operator: self.operator,
                              left: make_node(AST_Binary, self.left.left, {
                                  operator: self.operator,
                                  left: self.left.right,
                                  right: self.right.left,
                                  start: self.left.right.start,
                                  end: self.right.left.end
                              }),
                              right: self.left.left
                          }),
                          right: self.right.right
                      });
                  }
              }
          }
      }
      // x && (y && z)  ==>  x && y && z
      // x || (y || z)  ==>  x || y || z
      // x + ("y" + z)  ==>  x + "y" + z
      // "x" + (y + "z")==>  "x" + y + "z"
      if (self.right instanceof AST_Binary
          && self.right.operator == self.operator
          && (lazy_op.has(self.operator)
              || (self.operator == "+"
                  && (self.right.left.is_string(compressor)
                      || (self.left.is_string(compressor)
                          && self.right.right.is_string(compressor)))))
      ) {
          self.left = make_node(AST_Binary, self.left, {
              operator : self.operator,
              left     : self.left.transform(compressor),
              right    : self.right.left.transform(compressor)
          });
          self.right = self.right.right.transform(compressor);
          return self.transform(compressor);
      }
      var ev = self.evaluate(compressor);
      if (ev !== self) {
          ev = make_node_from_constant(ev, self).optimize(compressor);
          return best_of(compressor, ev, self);
      }
      return self;
  });

  def_optimize(AST_SymbolExport, function(self) {
      return self;
  });

  def_optimize(AST_SymbolRef, function(self, compressor) {
      if (
          !compressor.option("ie8")
          && is_undeclared_ref(self)
          && !compressor.find_parent(AST_With)
      ) {
          switch (self.name) {
            case "undefined":
              return make_node(AST_Undefined, self).optimize(compressor);
            case "NaN":
              return make_node(AST_NaN, self).optimize(compressor);
            case "Infinity":
              return make_node(AST_Infinity, self).optimize(compressor);
          }
      }

      const parent = compressor.parent();
      if (compressor.option("reduce_vars") && is_lhs(self, parent) !== self) {
          return inline_into_symbolref(self, compressor);
      } else {
          return self;
      }
  });

  function is_atomic(lhs, self) {
      return lhs instanceof AST_SymbolRef || lhs.TYPE === self.TYPE;
  }

  def_optimize(AST_Undefined, function(self, compressor) {
      if (compressor.option("unsafe_undefined")) {
          var undef = find_variable(compressor, "undefined");
          if (undef) {
              var ref = make_node(AST_SymbolRef, self, {
                  name   : "undefined",
                  scope  : undef.scope,
                  thedef : undef
              });
              set_flag(ref, UNDEFINED);
              return ref;
          }
      }
      var lhs = is_lhs(compressor.self(), compressor.parent());
      if (lhs && is_atomic(lhs, self)) return self;
      return make_node(AST_UnaryPrefix, self, {
          operator: "void",
          expression: make_node(AST_Number, self, {
              value: 0
          })
      });
  });

  def_optimize(AST_Infinity, function(self, compressor) {
      var lhs = is_lhs(compressor.self(), compressor.parent());
      if (lhs && is_atomic(lhs, self)) return self;
      if (
          compressor.option("keep_infinity")
          && !(lhs && !is_atomic(lhs, self))
          && !find_variable(compressor, "Infinity")
      ) {
          return self;
      }
      return make_node(AST_Binary, self, {
          operator: "/",
          left: make_node(AST_Number, self, {
              value: 1
          }),
          right: make_node(AST_Number, self, {
              value: 0
          })
      });
  });

  def_optimize(AST_NaN, function(self, compressor) {
      var lhs = is_lhs(compressor.self(), compressor.parent());
      if (lhs && !is_atomic(lhs, self)
          || find_variable(compressor, "NaN")) {
          return make_node(AST_Binary, self, {
              operator: "/",
              left: make_node(AST_Number, self, {
                  value: 0
              }),
              right: make_node(AST_Number, self, {
                  value: 0
              })
          });
      }
      return self;
  });

  const ASSIGN_OPS = makePredicate("+ - / * % >> << >>> | ^ &");
  const ASSIGN_OPS_COMMUTATIVE = makePredicate("* | ^ &");
  def_optimize(AST_Assign, function(self, compressor) {
      if (self.logical) {
          return self.lift_sequences(compressor);
      }

      var def;
      // x = x ---> x
      if (
          self.operator === "="
          && self.left instanceof AST_SymbolRef
          && self.left.name !== "arguments"
          && !(def = self.left.definition()).undeclared
          && self.right.equivalent_to(self.left)
      ) {
          return self.right;
      }

      if (compressor.option("dead_code")
          && self.left instanceof AST_SymbolRef
          && (def = self.left.definition()).scope === compressor.find_parent(AST_Lambda)) {
          var level = 0, node, parent = self;
          do {
              node = parent;
              parent = compressor.parent(level++);
              if (parent instanceof AST_Exit) {
                  if (in_try(level, parent)) break;
                  if (is_reachable(def.scope, [ def ])) break;
                  if (self.operator == "=") return self.right;
                  def.fixed = false;
                  return make_node(AST_Binary, self, {
                      operator: self.operator.slice(0, -1),
                      left: self.left,
                      right: self.right
                  }).optimize(compressor);
              }
          } while (parent instanceof AST_Binary && parent.right === node
              || parent instanceof AST_Sequence && parent.tail_node() === node);
      }
      self = self.lift_sequences(compressor);

      if (self.operator == "=" && self.left instanceof AST_SymbolRef && self.right instanceof AST_Binary) {
          // x = expr1 OP expr2
          if (self.right.left instanceof AST_SymbolRef
              && self.right.left.name == self.left.name
              && ASSIGN_OPS.has(self.right.operator)) {
              // x = x - 2  --->  x -= 2
              self.operator = self.right.operator + "=";
              self.right = self.right.right;
          } else if (self.right.right instanceof AST_SymbolRef
              && self.right.right.name == self.left.name
              && ASSIGN_OPS_COMMUTATIVE.has(self.right.operator)
              && !self.right.left.has_side_effects(compressor)) {
              // x = 2 & x  --->  x &= 2
              self.operator = self.right.operator + "=";
              self.right = self.right.left;
          }
      }
      return self;

      function in_try(level, node) {
          var right = self.right;
          self.right = make_node(AST_Null, right);
          var may_throw = node.may_throw(compressor);
          self.right = right;
          var scope = self.left.definition().scope;
          var parent;
          while ((parent = compressor.parent(level++)) !== scope) {
              if (parent instanceof AST_Try) {
                  if (parent.bfinally) return true;
                  if (may_throw && parent.bcatch) return true;
              }
          }
      }
  });

  def_optimize(AST_DefaultAssign, function(self, compressor) {
      if (!compressor.option("evaluate")) {
          return self;
      }
      var evaluateRight = self.right.evaluate(compressor);

      // `[x = undefined] = foo` ---> `[x] = foo`
      if (evaluateRight === undefined) {
          self = self.left;
      } else if (evaluateRight !== self.right) {
          evaluateRight = make_node_from_constant(evaluateRight, self.right);
          self.right = best_of_expression(evaluateRight, self.right);
      }

      return self;
  });

  function is_nullish_check(check, check_subject, compressor) {
      if (check_subject.may_throw(compressor)) return false;

      let nullish_side;

      // foo == null
      if (
          check instanceof AST_Binary
          && check.operator === "=="
          // which side is nullish?
          && (
              (nullish_side = is_nullish(check.left, compressor) && check.left)
              || (nullish_side = is_nullish(check.right, compressor) && check.right)
          )
          // is the other side the same as the check_subject
          && (
              nullish_side === check.left
                  ? check.right
                  : check.left
          ).equivalent_to(check_subject)
      ) {
          return true;
      }

      // foo === null || foo === undefined
      if (check instanceof AST_Binary && check.operator === "||") {
          let null_cmp;
          let undefined_cmp;

          const find_comparison = cmp => {
              if (!(
                  cmp instanceof AST_Binary
                  && (cmp.operator === "===" || cmp.operator === "==")
              )) {
                  return false;
              }

              let found = 0;
              let defined_side;

              if (cmp.left instanceof AST_Null) {
                  found++;
                  null_cmp = cmp;
                  defined_side = cmp.right;
              }
              if (cmp.right instanceof AST_Null) {
                  found++;
                  null_cmp = cmp;
                  defined_side = cmp.left;
              }
              if (is_undefined(cmp.left, compressor)) {
                  found++;
                  undefined_cmp = cmp;
                  defined_side = cmp.right;
              }
              if (is_undefined(cmp.right, compressor)) {
                  found++;
                  undefined_cmp = cmp;
                  defined_side = cmp.left;
              }

              if (found !== 1) {
                  return false;
              }

              if (!defined_side.equivalent_to(check_subject)) {
                  return false;
              }

              return true;
          };

          if (!find_comparison(check.left)) return false;
          if (!find_comparison(check.right)) return false;

          if (null_cmp && undefined_cmp && null_cmp !== undefined_cmp) {
              return true;
          }
      }

      return false;
  }

  def_optimize(AST_Conditional, function(self, compressor) {
      if (!compressor.option("conditionals")) return self;
      // This looks like lift_sequences(), should probably be under "sequences"
      if (self.condition instanceof AST_Sequence) {
          var expressions = self.condition.expressions.slice();
          self.condition = expressions.pop();
          expressions.push(self);
          return make_sequence(self, expressions);
      }
      var cond = self.condition.evaluate(compressor);
      if (cond !== self.condition) {
          if (cond) {
              return maintain_this_binding(compressor.parent(), compressor.self(), self.consequent);
          } else {
              return maintain_this_binding(compressor.parent(), compressor.self(), self.alternative);
          }
      }
      var negated = cond.negate(compressor, first_in_statement(compressor));
      if (best_of(compressor, cond, negated) === negated) {
          self = make_node(AST_Conditional, self, {
              condition: negated,
              consequent: self.alternative,
              alternative: self.consequent
          });
      }
      var condition = self.condition;
      var consequent = self.consequent;
      var alternative = self.alternative;
      // x?x:y --> x||y
      if (condition instanceof AST_SymbolRef
          && consequent instanceof AST_SymbolRef
          && condition.definition() === consequent.definition()) {
          return make_node(AST_Binary, self, {
              operator: "||",
              left: condition,
              right: alternative
          });
      }
      // if (foo) exp = something; else exp = something_else;
      //                   |
      //                   v
      // exp = foo ? something : something_else;
      if (
          consequent instanceof AST_Assign
          && alternative instanceof AST_Assign
          && consequent.operator === alternative.operator
          && consequent.logical === alternative.logical
          && consequent.left.equivalent_to(alternative.left)
          && (!self.condition.has_side_effects(compressor)
              || consequent.operator == "="
                  && !consequent.left.has_side_effects(compressor))
      ) {
          return make_node(AST_Assign, self, {
              operator: consequent.operator,
              left: consequent.left,
              logical: consequent.logical,
              right: make_node(AST_Conditional, self, {
                  condition: self.condition,
                  consequent: consequent.right,
                  alternative: alternative.right
              })
          });
      }
      // x ? y(a) : y(b) --> y(x ? a : b)
      var arg_index;
      if (consequent instanceof AST_Call
          && alternative.TYPE === consequent.TYPE
          && consequent.args.length > 0
          && consequent.args.length == alternative.args.length
          && consequent.expression.equivalent_to(alternative.expression)
          && !self.condition.has_side_effects(compressor)
          && !consequent.expression.has_side_effects(compressor)
          && typeof (arg_index = single_arg_diff()) == "number") {
          var node = consequent.clone();
          node.args[arg_index] = make_node(AST_Conditional, self, {
              condition: self.condition,
              consequent: consequent.args[arg_index],
              alternative: alternative.args[arg_index]
          });
          return node;
      }
      // a ? b : c ? b : d --> (a || c) ? b : d
      if (alternative instanceof AST_Conditional
          && consequent.equivalent_to(alternative.consequent)) {
          return make_node(AST_Conditional, self, {
              condition: make_node(AST_Binary, self, {
                  operator: "||",
                  left: condition,
                  right: alternative.condition
              }),
              consequent: consequent,
              alternative: alternative.alternative
          }).optimize(compressor);
      }

      // a == null ? b : a -> a ?? b
      if (
          compressor.option("ecma") >= 2020 &&
          is_nullish_check(condition, alternative, compressor)
      ) {
          return make_node(AST_Binary, self, {
              operator: "??",
              left: alternative,
              right: consequent
          }).optimize(compressor);
      }

      // a ? b : (c, b) --> (a || c), b
      if (alternative instanceof AST_Sequence
          && consequent.equivalent_to(alternative.expressions[alternative.expressions.length - 1])) {
          return make_sequence(self, [
              make_node(AST_Binary, self, {
                  operator: "||",
                  left: condition,
                  right: make_sequence(self, alternative.expressions.slice(0, -1))
              }),
              consequent
          ]).optimize(compressor);
      }
      // a ? b : (c && b) --> (a || c) && b
      if (alternative instanceof AST_Binary
          && alternative.operator == "&&"
          && consequent.equivalent_to(alternative.right)) {
          return make_node(AST_Binary, self, {
              operator: "&&",
              left: make_node(AST_Binary, self, {
                  operator: "||",
                  left: condition,
                  right: alternative.left
              }),
              right: consequent
          }).optimize(compressor);
      }
      // x?y?z:a:a --> x&&y?z:a
      if (consequent instanceof AST_Conditional
          && consequent.alternative.equivalent_to(alternative)) {
          return make_node(AST_Conditional, self, {
              condition: make_node(AST_Binary, self, {
                  left: self.condition,
                  operator: "&&",
                  right: consequent.condition
              }),
              consequent: consequent.consequent,
              alternative: alternative
          });
      }
      // x ? y : y --> x, y
      if (consequent.equivalent_to(alternative)) {
          return make_sequence(self, [
              self.condition,
              consequent
          ]).optimize(compressor);
      }
      // x ? y || z : z --> x && y || z
      if (consequent instanceof AST_Binary
          && consequent.operator == "||"
          && consequent.right.equivalent_to(alternative)) {
          return make_node(AST_Binary, self, {
              operator: "||",
              left: make_node(AST_Binary, self, {
                  operator: "&&",
                  left: self.condition,
                  right: consequent.left
              }),
              right: alternative
          }).optimize(compressor);
      }

      const in_bool = compressor.in_boolean_context();
      if (is_true(self.consequent)) {
          if (is_false(self.alternative)) {
              // c ? true : false ---> !!c
              return booleanize(self.condition);
          }
          // c ? true : x ---> !!c || x
          return make_node(AST_Binary, self, {
              operator: "||",
              left: booleanize(self.condition),
              right: self.alternative
          });
      }
      if (is_false(self.consequent)) {
          if (is_true(self.alternative)) {
              // c ? false : true ---> !c
              return booleanize(self.condition.negate(compressor));
          }
          // c ? false : x ---> !c && x
          return make_node(AST_Binary, self, {
              operator: "&&",
              left: booleanize(self.condition.negate(compressor)),
              right: self.alternative
          });
      }
      if (is_true(self.alternative)) {
          // c ? x : true ---> !c || x
          return make_node(AST_Binary, self, {
              operator: "||",
              left: booleanize(self.condition.negate(compressor)),
              right: self.consequent
          });
      }
      if (is_false(self.alternative)) {
          // c ? x : false ---> !!c && x
          return make_node(AST_Binary, self, {
              operator: "&&",
              left: booleanize(self.condition),
              right: self.consequent
          });
      }

      return self;

      function booleanize(node) {
          if (node.is_boolean()) return node;
          // !!expression
          return make_node(AST_UnaryPrefix, node, {
              operator: "!",
              expression: node.negate(compressor)
          });
      }

      // AST_True or !0
      function is_true(node) {
          return node instanceof AST_True
              || in_bool
                  && node instanceof AST_Constant
                  && node.getValue()
              || (node instanceof AST_UnaryPrefix
                  && node.operator == "!"
                  && node.expression instanceof AST_Constant
                  && !node.expression.getValue());
      }
      // AST_False or !1
      function is_false(node) {
          return node instanceof AST_False
              || in_bool
                  && node instanceof AST_Constant
                  && !node.getValue()
              || (node instanceof AST_UnaryPrefix
                  && node.operator == "!"
                  && node.expression instanceof AST_Constant
                  && node.expression.getValue());
      }

      function single_arg_diff() {
          var a = consequent.args;
          var b = alternative.args;
          for (var i = 0, len = a.length; i < len; i++) {
              if (a[i] instanceof AST_Expansion) return;
              if (!a[i].equivalent_to(b[i])) {
                  if (b[i] instanceof AST_Expansion) return;
                  for (var j = i + 1; j < len; j++) {
                      if (a[j] instanceof AST_Expansion) return;
                      if (!a[j].equivalent_to(b[j])) return;
                  }
                  return i;
              }
          }
      }
  });

  def_optimize(AST_Boolean, function(self, compressor) {
      if (compressor.in_boolean_context()) return make_node(AST_Number, self, {
          value: +self.value
      });
      var p = compressor.parent();
      if (compressor.option("booleans_as_integers")) {
          if (p instanceof AST_Binary && (p.operator == "===" || p.operator == "!==")) {
              p.operator = p.operator.replace(/=$/, "");
          }
          return make_node(AST_Number, self, {
              value: +self.value
          });
      }
      if (compressor.option("booleans")) {
          if (p instanceof AST_Binary && (p.operator == "=="
                                          || p.operator == "!=")) {
              return make_node(AST_Number, self, {
                  value: +self.value
              });
          }
          return make_node(AST_UnaryPrefix, self, {
              operator: "!",
              expression: make_node(AST_Number, self, {
                  value: 1 - self.value
              })
          });
      }
      return self;
  });

  function safe_to_flatten(value, compressor) {
      if (value instanceof AST_SymbolRef) {
          value = value.fixed_value();
      }
      if (!value) return false;
      if (!(value instanceof AST_Lambda || value instanceof AST_Class)) return true;
      if (!(value instanceof AST_Lambda && value.contains_this())) return true;
      return compressor.parent() instanceof AST_New;
  }

  AST_PropAccess.DEFMETHOD("flatten_object", function(key, compressor) {
      if (!compressor.option("properties")) return;
      if (key === "__proto__") return;

      var arrows = compressor.option("unsafe_arrows") && compressor.option("ecma") >= 2015;
      var expr = this.expression;
      if (expr instanceof AST_Object) {
          var props = expr.properties;

          for (var i = props.length; --i >= 0;) {
              var prop = props[i];

              if ("" + (prop instanceof AST_ConciseMethod ? prop.key.name : prop.key) == key) {
                  const all_props_flattenable = props.every((p) =>
                      (p instanceof AST_ObjectKeyVal
                          || arrows && p instanceof AST_ConciseMethod && !p.is_generator
                      )
                      && !p.computed_key()
                  );

                  if (!all_props_flattenable) return;
                  if (!safe_to_flatten(prop.value, compressor)) return;

                  return make_node(AST_Sub, this, {
                      expression: make_node(AST_Array, expr, {
                          elements: props.map(function(prop) {
                              var v = prop.value;
                              if (v instanceof AST_Accessor) {
                                  v = make_node(AST_Function, v, v);
                              }

                              var k = prop.key;
                              if (k instanceof AST_Node && !(k instanceof AST_SymbolMethod)) {
                                  return make_sequence(prop, [ k, v ]);
                              }

                              return v;
                          })
                      }),
                      property: make_node(AST_Number, this, {
                          value: i
                      })
                  });
              }
          }
      }
  });

  def_optimize(AST_Sub, function(self, compressor) {
      var expr = self.expression;
      var prop = self.property;
      if (compressor.option("properties")) {
          var key = prop.evaluate(compressor);
          if (key !== prop) {
              if (typeof key == "string") {
                  if (key == "undefined") {
                      key = undefined;
                  } else {
                      var value = parseFloat(key);
                      if (value.toString() == key) {
                          key = value;
                      }
                  }
              }
              prop = self.property = best_of_expression(prop, make_node_from_constant(key, prop).transform(compressor));
              var property = "" + key;
              if (is_basic_identifier_string(property)
                  && property.length <= prop.size() + 1) {
                  return make_node(AST_Dot, self, {
                      expression: expr,
                      optional: self.optional,
                      property: property,
                      quote: prop.quote,
                  }).optimize(compressor);
              }
          }
      }
      var fn;
      OPT_ARGUMENTS: if (compressor.option("arguments")
          && expr instanceof AST_SymbolRef
          && expr.name == "arguments"
          && expr.definition().orig.length == 1
          && (fn = expr.scope) instanceof AST_Lambda
          && fn.uses_arguments
          && !(fn instanceof AST_Arrow)
          && prop instanceof AST_Number) {
          var index = prop.getValue();
          var params = new Set();
          var argnames = fn.argnames;
          for (var n = 0; n < argnames.length; n++) {
              if (!(argnames[n] instanceof AST_SymbolFunarg)) {
                  break OPT_ARGUMENTS; // destructuring parameter - bail
              }
              var param = argnames[n].name;
              if (params.has(param)) {
                  break OPT_ARGUMENTS; // duplicate parameter - bail
              }
              params.add(param);
          }
          var argname = fn.argnames[index];
          if (argname && compressor.has_directive("use strict")) {
              var def = argname.definition();
              if (!compressor.option("reduce_vars") || def.assignments || def.orig.length > 1) {
                  argname = null;
              }
          } else if (!argname && !compressor.option("keep_fargs") && index < fn.argnames.length + 5) {
              while (index >= fn.argnames.length) {
                  argname = fn.create_symbol(AST_SymbolFunarg, {
                      source: fn,
                      scope: fn,
                      tentative_name: "argument_" + fn.argnames.length,
                  });
                  fn.argnames.push(argname);
              }
          }
          if (argname) {
              var sym = make_node(AST_SymbolRef, self, argname);
              sym.reference({});
              clear_flag(argname, UNUSED);
              return sym;
          }
      }
      if (is_lhs(self, compressor.parent())) return self;
      if (key !== prop) {
          var sub = self.flatten_object(property, compressor);
          if (sub) {
              expr = self.expression = sub.expression;
              prop = self.property = sub.property;
          }
      }
      if (compressor.option("properties") && compressor.option("side_effects")
          && prop instanceof AST_Number && expr instanceof AST_Array) {
          var index = prop.getValue();
          var elements = expr.elements;
          var retValue = elements[index];
          FLATTEN: if (safe_to_flatten(retValue, compressor)) {
              var flatten = true;
              var values = [];
              for (var i = elements.length; --i > index;) {
                  var value = elements[i].drop_side_effect_free(compressor);
                  if (value) {
                      values.unshift(value);
                      if (flatten && value.has_side_effects(compressor)) flatten = false;
                  }
              }
              if (retValue instanceof AST_Expansion) break FLATTEN;
              retValue = retValue instanceof AST_Hole ? make_node(AST_Undefined, retValue) : retValue;
              if (!flatten) values.unshift(retValue);
              while (--i >= 0) {
                  var value = elements[i];
                  if (value instanceof AST_Expansion) break FLATTEN;
                  value = value.drop_side_effect_free(compressor);
                  if (value) values.unshift(value);
                  else index--;
              }
              if (flatten) {
                  values.push(retValue);
                  return make_sequence(self, values).optimize(compressor);
              } else return make_node(AST_Sub, self, {
                  expression: make_node(AST_Array, expr, {
                      elements: values
                  }),
                  property: make_node(AST_Number, prop, {
                      value: index
                  })
              });
          }
      }
      var ev = self.evaluate(compressor);
      if (ev !== self) {
          ev = make_node_from_constant(ev, self).optimize(compressor);
          return best_of(compressor, ev, self);
      }
      return self;
  });

  def_optimize(AST_Chain, function (self, compressor) {
      if (is_nullish(self.expression, compressor)) {
          let parent = compressor.parent();
          // It's valid to delete a nullish optional chain, but if we optimized
          // this to `delete undefined` then it would appear to be a syntax error
          // when we try to optimize the delete. Thankfully, `delete 0` is fine.
          if (parent instanceof AST_UnaryPrefix && parent.operator === "delete") {
              return make_node_from_constant(0, self);
          }
          return make_node(AST_Undefined, self);
      }
      return self;
  });

  AST_Lambda.DEFMETHOD("contains_this", function() {
      return walk(this, node => {
          if (node instanceof AST_This) return walk_abort;
          if (
              node !== this
              && node instanceof AST_Scope
              && !(node instanceof AST_Arrow)
          ) {
              return true;
          }
      });
  });

  def_optimize(AST_Dot, function(self, compressor) {
      const parent = compressor.parent();
      if (is_lhs(self, parent)) return self;
      if (compressor.option("unsafe_proto")
          && self.expression instanceof AST_Dot
          && self.expression.property == "prototype") {
          var exp = self.expression.expression;
          if (is_undeclared_ref(exp)) switch (exp.name) {
            case "Array":
              self.expression = make_node(AST_Array, self.expression, {
                  elements: []
              });
              break;
            case "Function":
              self.expression = make_node(AST_Function, self.expression, {
                  argnames: [],
                  body: []
              });
              break;
            case "Number":
              self.expression = make_node(AST_Number, self.expression, {
                  value: 0
              });
              break;
            case "Object":
              self.expression = make_node(AST_Object, self.expression, {
                  properties: []
              });
              break;
            case "RegExp":
              self.expression = make_node(AST_RegExp, self.expression, {
                  value: { source: "t", flags: "" }
              });
              break;
            case "String":
              self.expression = make_node(AST_String, self.expression, {
                  value: ""
              });
              break;
          }
      }
      if (!(parent instanceof AST_Call) || !has_annotation(parent, _NOINLINE)) {
          const sub = self.flatten_object(self.property, compressor);
          if (sub) return sub.optimize(compressor);
      }

      if (self.expression instanceof AST_PropAccess
          && parent instanceof AST_PropAccess) {
          return self;
      }

      let ev = self.evaluate(compressor);
      if (ev !== self) {
          ev = make_node_from_constant(ev, self).optimize(compressor);
          return best_of(compressor, ev, self);
      }
      return self;
  });

  function literals_in_boolean_context(self, compressor) {
      if (compressor.in_boolean_context()) {
          return best_of(compressor, self, make_sequence(self, [
              self,
              make_node(AST_True, self)
          ]).optimize(compressor));
      }
      return self;
  }

  function inline_array_like_spread(elements) {
      for (var i = 0; i < elements.length; i++) {
          var el = elements[i];
          if (el instanceof AST_Expansion) {
              var expr = el.expression;
              if (
                  expr instanceof AST_Array
                  && !expr.elements.some(elm => elm instanceof AST_Hole)
              ) {
                  elements.splice(i, 1, ...expr.elements);
                  // Step back one, as the element at i is now new.
                  i--;
              }
              // In array-like spread, spreading a non-iterable value is TypeError.
              // We therefore can’t optimize anything else, unlike with object spread.
          }
      }
  }

  def_optimize(AST_Array, function(self, compressor) {
      var optimized = literals_in_boolean_context(self, compressor);
      if (optimized !== self) {
          return optimized;
      }
      inline_array_like_spread(self.elements);
      return self;
  });

  function inline_object_prop_spread(props, compressor) {
      for (var i = 0; i < props.length; i++) {
          var prop = props[i];
          if (prop instanceof AST_Expansion) {
              const expr = prop.expression;
              if (
                  expr instanceof AST_Object
                  && expr.properties.every(prop => prop instanceof AST_ObjectKeyVal)
              ) {
                  props.splice(i, 1, ...expr.properties);
                  // Step back one, as the property at i is now new.
                  i--;
              } else if (expr instanceof AST_Constant
                  && !(expr instanceof AST_String)) {
                  // Unlike array-like spread, in object spread, spreading a
                  // non-iterable value silently does nothing; it is thus safe
                  // to remove. AST_String is the only iterable AST_Constant.
                  props.splice(i, 1);
                  i--;
              } else if (is_nullish(expr, compressor)) {
                  // Likewise, null and undefined can be silently removed.
                  props.splice(i, 1);
                  i--;
              }
          }
      }
  }

  def_optimize(AST_Object, function(self, compressor) {
      var optimized = literals_in_boolean_context(self, compressor);
      if (optimized !== self) {
          return optimized;
      }
      inline_object_prop_spread(self.properties, compressor);
      return self;
  });

  def_optimize(AST_RegExp, literals_in_boolean_context);

  def_optimize(AST_Return, function(self, compressor) {
      if (self.value && is_undefined(self.value, compressor)) {
          self.value = null;
      }
      return self;
  });

  def_optimize(AST_Arrow, opt_AST_Lambda);

  def_optimize(AST_Function, function(self, compressor) {
      self = opt_AST_Lambda(self, compressor);
      if (compressor.option("unsafe_arrows")
          && compressor.option("ecma") >= 2015
          && !self.name
          && !self.is_generator
          && !self.uses_arguments
          && !self.pinned()) {
          const uses_this = walk(self, node => {
              if (node instanceof AST_This) return walk_abort;
          });
          if (!uses_this) return make_node(AST_Arrow, self, self).optimize(compressor);
      }
      return self;
  });

  def_optimize(AST_Class, function(self) {
      // HACK to avoid compress failure.
      // AST_Class is not really an AST_Scope/AST_Block as it lacks a body.
      return self;
  });

  def_optimize(AST_Yield, function(self, compressor) {
      if (self.expression && !self.is_star && is_undefined(self.expression, compressor)) {
          self.expression = null;
      }
      return self;
  });

  def_optimize(AST_TemplateString, function(self, compressor) {
      if (
          !compressor.option("evaluate")
          || compressor.parent() instanceof AST_PrefixedTemplateString
      ) {
          return self;
      }

      var segments = [];
      for (var i = 0; i < self.segments.length; i++) {
          var segment = self.segments[i];
          if (segment instanceof AST_Node) {
              var result = segment.evaluate(compressor);
              // Evaluate to constant value
              // Constant value shorter than ${segment}
              if (result !== segment && (result + "").length <= segment.size() + "${}".length) {
                  // There should always be a previous and next segment if segment is a node
                  segments[segments.length - 1].value = segments[segments.length - 1].value + result + self.segments[++i].value;
                  continue;
              }
              // `before ${`innerBefore ${any} innerAfter`} after` => `before innerBefore ${any} innerAfter after`
              // TODO:
              // `before ${'test' + foo} after` => `before innerBefore ${any} innerAfter after`
              // `before ${foo + 'test} after` => `before innerBefore ${any} innerAfter after`
              if (segment instanceof AST_TemplateString) {
                  var inners = segment.segments;
                  segments[segments.length - 1].value += inners[0].value;
                  for (var j = 1; j < inners.length; j++) {
                      segment = inners[j];
                      segments.push(segment);
                  }
                  continue;
              }
          }
          segments.push(segment);
      }
      self.segments = segments;

      // `foo` => "foo"
      if (segments.length == 1) {
          return make_node(AST_String, self, segments[0]);
      }

      if (
          segments.length === 3
          && segments[1] instanceof AST_Node
          && (
              segments[1].is_string(compressor)
              || segments[1].is_number(compressor)
              || is_nullish(segments[1], compressor)
              || compressor.option("unsafe")
          )
      ) {
          // `foo${bar}` => "foo" + bar
          if (segments[2].value === "") {
              return make_node(AST_Binary, self, {
                  operator: "+",
                  left: make_node(AST_String, self, {
                      value: segments[0].value,
                  }),
                  right: segments[1],
              });
          }
          // `${bar}baz` => bar + "baz"
          if (segments[0].value === "") {
              return make_node(AST_Binary, self, {
                  operator: "+",
                  left: segments[1],
                  right: make_node(AST_String, self, {
                      value: segments[2].value,
                  }),
              });
          }
      }
      return self;
  });

  def_optimize(AST_PrefixedTemplateString, function(self) {
      return self;
  });

  // ["p"]:1 ---> p:1
  // [42]:1 ---> 42:1
  function lift_key(self, compressor) {
      if (!compressor.option("computed_props")) return self;
      // save a comparison in the typical case
      if (!(self.key instanceof AST_Constant)) return self;
      // allow certain acceptable props as not all AST_Constants are true constants
      if (self.key instanceof AST_String || self.key instanceof AST_Number) {
          if (self.key.value === "__proto__") return self;
          if (self.key.value == "constructor"
              && compressor.parent() instanceof AST_Class) return self;
          if (self instanceof AST_ObjectKeyVal) {
              self.quote = self.key.quote;
              self.key = self.key.value;
          } else if (self instanceof AST_ClassProperty) {
              self.quote = self.key.quote;
              self.key = make_node(AST_SymbolClassProperty, self.key, {
                  name: self.key.value
              });
          } else {
              self.quote = self.key.quote;
              self.key = make_node(AST_SymbolMethod, self.key, {
                  name: self.key.value
              });
          }
      }
      return self;
  }

  def_optimize(AST_ObjectProperty, lift_key);

  def_optimize(AST_ConciseMethod, function(self, compressor) {
      lift_key(self, compressor);
      // p(){return x;} ---> p:()=>x
      if (compressor.option("arrows")
          && compressor.parent() instanceof AST_Object
          && !self.is_generator
          && !self.value.uses_arguments
          && !self.value.pinned()
          && self.value.body.length == 1
          && self.value.body[0] instanceof AST_Return
          && self.value.body[0].value
          && !self.value.contains_this()) {
          var arrow = make_node(AST_Arrow, self.value, self.value);
          arrow.async = self.async;
          arrow.is_generator = self.is_generator;
          return make_node(AST_ObjectKeyVal, self, {
              key: self.key instanceof AST_SymbolMethod ? self.key.name : self.key,
              value: arrow,
              quote: self.quote,
          });
      }
      return self;
  });

  def_optimize(AST_ObjectKeyVal, function(self, compressor) {
      lift_key(self, compressor);
      // p:function(){} ---> p(){}
      // p:function*(){} ---> *p(){}
      // p:async function(){} ---> async p(){}
      // p:()=>{} ---> p(){}
      // p:async()=>{} ---> async p(){}
      var unsafe_methods = compressor.option("unsafe_methods");
      if (unsafe_methods
          && compressor.option("ecma") >= 2015
          && (!(unsafe_methods instanceof RegExp) || unsafe_methods.test(self.key + ""))) {
          var key = self.key;
          var value = self.value;
          var is_arrow_with_block = value instanceof AST_Arrow
              && Array.isArray(value.body)
              && !value.contains_this();
          if ((is_arrow_with_block || value instanceof AST_Function) && !value.name) {
              return make_node(AST_ConciseMethod, self, {
                  async: value.async,
                  is_generator: value.is_generator,
                  key: key instanceof AST_Node ? key : make_node(AST_SymbolMethod, self, {
                      name: key,
                  }),
                  value: make_node(AST_Accessor, value, value),
                  quote: self.quote,
              });
          }
      }
      return self;
  });

  def_optimize(AST_Destructuring, function(self, compressor) {
      if (compressor.option("pure_getters") == true
          && compressor.option("unused")
          && !self.is_array
          && Array.isArray(self.names)
          && !is_destructuring_export_decl(compressor)
          && !(self.names[self.names.length - 1] instanceof AST_Expansion)) {
          var keep = [];
          for (var i = 0; i < self.names.length; i++) {
              var elem = self.names[i];
              if (!(elem instanceof AST_ObjectKeyVal
                  && typeof elem.key == "string"
                  && elem.value instanceof AST_SymbolDeclaration
                  && !should_retain(compressor, elem.value.definition()))) {
                  keep.push(elem);
              }
          }
          if (keep.length != self.names.length) {
              self.names = keep;
          }
      }
      return self;

      function is_destructuring_export_decl(compressor) {
          var ancestors = [/^VarDef$/, /^(Const|Let|Var)$/, /^Export$/];
          for (var a = 0, p = 0, len = ancestors.length; a < len; p++) {
              var parent = compressor.parent(p);
              if (!parent) return false;
              if (a === 0 && parent.TYPE == "Destructuring") continue;
              if (!ancestors[a].test(parent.TYPE)) {
                  return false;
              }
              a++;
          }
          return true;
      }

      function should_retain(compressor, def) {
          if (def.references.length) return true;
          if (!def.global) return false;
          if (compressor.toplevel.vars) {
               if (compressor.top_retain) {
                   return compressor.top_retain(def);
               }
               return false;
          }
          return true;
      }
  });

  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  const intToChar = new Uint8Array(64); // 64 possible chars.
  const charToInteger = new Uint8Array(128); // z is 122 in ASCII
  for (let i = 0; i < chars.length; i++) {
      const c = chars.charCodeAt(i);
      charToInteger[c] = i;
      intToChar[i] = c;
  }
  // Provide a fallback for older environments.
  typeof TextDecoder !== 'undefined'
      ? new TextDecoder()
      : typeof Buffer !== 'undefined'
          ? {
              decode(buf) {
                  const out = Buffer.from(buf.buffer, buf.byteOffset, buf.byteLength);
                  return out.toString();
              },
          }
          : {
              decode(buf) {
                  let out = '';
                  for (let i = 0; i < buf.length; i++) {
                      out += String.fromCharCode(buf[i]);
                  }
                  return out;
              },
          };

  Object.freeze({
      source: null,
      line: null,
      column: null,
      name: null,
  });
  Object.freeze({
      line: null,
      column: null,
  });

})();

"""###
private let compressedToolsJs = Data(base64Encoded:"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")!

import Foundation

// swiftlint:disable all



public enum ToolsPamphlet {
    public static let version = "v0.2.4-5-g151f2c9"
    
    #if DEBUG
    public static func get(string member: String) -> String? {
        switch member {
        case "/tools.js": return ToolsPamphlet.ToolsJs()
        default: break
        }
        return nil
    }
    #else
    public static func get(string member: String) -> StaticString? {
        switch member {
        case "/tools.js": return ToolsPamphlet.ToolsJs()
        default: break
        }
        return nil
    }
    #endif
    public static func get(gzip member: String) -> Data? {
        #if DEBUG
            return nil
        #else
            switch member {
        case "/tools.js": return ToolsPamphlet.ToolsJsGzip()
            default: break
            }
            return nil
        #endif
    }
    public static func get(data member: String) -> Data? {
        switch member {

        default: break
        }
        return nil
    }
}
