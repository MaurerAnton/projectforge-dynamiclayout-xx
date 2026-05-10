// SPDX-License-Identifier: MIT
// DynamicLayout Solidity API — generate layout JSON from Solidity (EVM) code.
// Single-file. Zero dependencies. Works on Solidity 0.8.20+.
// Note: Gas-heavy (string building). Use for view/pure functions, not txns.
//
// Example (foundry test):
//   DynamicLayout dl = new DynamicLayout();
//   dl.begin("My Page");
//   dl.fieldset("Info");
//   dl.label("Hello from Solidity!");
//   dl.endFieldset();
//   dl.button("ok", "OK", "primary", true);
//   string memory json = dl.end();

pragma solidity ^0.8.20;

contract DynamicLayout {
    string private buf;
    uint private _depth;
    bool private _comma;
    uint private _cnt;

    function begin(string memory title) external {
        buf = '{"ui":{';
        _depth = 2; _comma = false; _cnt = 0;
        kv("title", title);
        arr("layout");
    }

    function end() external view returns (string memory) {
        return string(abi.encodePacked(buf, '],"translations":{},"userAccess":{"cancel":true}}}'));
    }

    function fieldset(string memory title) external { obj(); kvVal("type", "FIELDSET"); kvVal("key", key("fs")); kvVal("title", title); arr("content"); }
    function endFieldset() external { ca(); co(); }
    function label(string memory text) external { obj(); kvVal("type", "LABEL"); kvVal("key", key("l")); kvVal("label", text); co(); }
    function alert(string memory msg, string memory color) external { obj(); kvVal("type", "ALERT"); kvVal("key", key("a")); kvVal("message", msg); kvVal("color", color); co(); }
    function badge(string memory title, string memory color) external { obj(); kvVal("type", "BADGE"); kvVal("key", key("bd")); kvVal("title", title); kvVal("color", color); co(); }
    function spacer(uint px) external { obj(); kvVal("type", "SPACER"); kvVal("key", key("sp")); kvInt("width", px); co(); }
    function input(string memory id, string memory label_, bool required) external { obj(); kvVal("type", "INPUT"); kvVal("key", key("i")); kvVal("id", id); kvVal("label", label_); if (required) kvBool("required"); co(); }
    function checkbox(string memory id, string memory label_) external { obj(); kvVal("type", "CHECKBOX"); kvVal("key", key("cb")); kvVal("id", id); kvVal("label", label_); co(); }
    function rating(string memory id, string memory label_) external { obj(); kvVal("type", "RATING"); kvVal("key", key("rt")); kvVal("id", id); kvVal("label", label_); co(); }
    function button(string memory id, string memory title, string memory color, bool isDefault) external { obj(); kvVal("type", "BUTTON"); kvVal("key", key("btn")); kvVal("id", id); kvVal("title", title); kvVal("color", color); if (isDefault) kvBool("default"); co(); }
    function section(string memory title, string memory text) external { fieldset(title); label(text); endFieldset(); }

    // internal
    function cm() private { if (_comma) { buf = string(abi.encodePacked(buf, ',')); _comma = false; } }
    function indent() private { buf = string(abi.encodePacked(buf, '\n')); for (uint i = 0; i < _depth; i++) buf = string(abi.encodePacked(buf, '  ')); }
    function esc(string memory s) private pure returns (string memory) { return s; }
    function kvVal(string memory k, string memory v) private { cm(); buf = string(abi.encodePacked(buf, ',')); indent(); buf = string(abi.encodePacked(buf, '"', k, '": "', v, '"')); _comma = true; }
    function kvInt(string memory k, uint v) private { cm(); buf = string(abi.encodePacked(buf, ',', unicode'\n')); buf = string(abi.encodePacked(buf, '"', k, '": ', toString(v))); _comma = true; }
    function kvBool(string memory k) private { cm(); buf = string(abi.encodePacked(buf, ',')); indent(); buf = string(abi.encodePacked(buf, '"', k, '": true')); _comma = true; }
    function obj() private { cm(); buf = string(abi.encodePacked(buf, ',')); indent(); buf = string(abi.encodePacked(buf, '{')); _depth++; _comma = false; }
    function co() private { _depth--; indent(); buf = string(abi.encodePacked(buf, '}')); _comma = true; }
    function arr(string memory k) private { cm(); buf = string(abi.encodePacked(buf, ',')); indent(); buf = string(abi.encodePacked(buf, '"', k, '": [')); _depth++; _comma = false; }
    function ca() private { _depth--; indent(); buf = string(abi.encodePacked(buf, ']')); _comma = true; }
    function key(string memory p) private returns (string memory) { _cnt++; return string(abi.encodePacked(p, '_', toString(_cnt))); }
    function toString(uint v) private pure returns (string memory) { if (v == 0) return "0"; uint t = v; uint l; while (t > 0) { l++; t /= 10; } bytes memory b = new bytes(l); while (v > 0) { b[--l] = bytes1(uint8((v % 10) + 48)); v /= 10; } return string(b); }
}
