{ lib }:
let
  inherit (lib) runTests;
  l = lib;
in

runTests {
  test_attrNamesToAttr = {
    expr = l.attrNamesToAttr [ "a" "b" "c" ] null;
    expected = { a = null; b = null; c = 1; };
  };

  test_mergeAttrsRecurseOnce = {
    expr = l.mergeAttrsRecurseOnce
      { a = { b = 1; }; d = { e = { f = 11; }; }; }
      { a = { b = 2; c = 3; }; d = { e = { g = 22; }; }; };
    expected = { a = { b = 2; c = 3; }; d = { e = { g = 22; }; }; };
  };
}
