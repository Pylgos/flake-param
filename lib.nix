{ lib }:

let
  l = builtins // lib;
in
{
  defautSystems = l.systems.flakeExposed;

  defaultSystemIndependentFields = [ "lib" ];

  funcName = "_flakeParamsFun";

  isParametrizedFlake = flake: l.hasAttr l.funcName flake;

  instantiate = flake: args: flake.${l.funcName} args;

  callFlake = flake: args:
    if l.isParametrizedFlake flake then
      l.instantiate flake args

    else
      flake;
  
  callFlakeDeSystemize = flake: args:
    if l.isParametrizedFlake flake then
      l.instantiate flake args

    else if args ? localSystem.system then
      let
        system = args.localSystem.system;
      in
      l.mapAttrs
        (name: value:
          if (l.isAttrs value) && (l.hasAttr system value) then
            value.${system}
          else
            value
        )
        flake

    else
      flake;

  callFlakes = flakes: args:
    l.mapAttrs
      (name: value: l.callFlake value args)
      flakes;
  
  callFlakesDeSystemize = flakes: args:
    l.mapAttrs
      (name: value: l.callFlakeDeSystemize value args)
      flakes;

  makeFun = inputs: f: args:
    let
      newInputs = l.callFlakes inputs args;
    in
    f newInputs args;

  attrNamesToAttr = names: value:
    l.listToAttrs
      (map
        (name: l.nameValuePair name value)
        names
      );

  mergeAttrsRecurseOnce = lhs: rhs:
    l.mapAttrs
      (name: _:
        (lhs.${name} or { }) // (rhs.${name} or { })
      )
      (lhs // rhs);

  mergeListOfAttrsRecurseOnce = listOfAttrs:
    l.foldl
      l.mergeAttrsRecurseOnce
      { }
      listOfAttrs;

  parametrize =
    { inputs
    , compat ? false
    , deSystemizeInput ? !compat
    , deSystemizeOutput ? compat
    , systemIndependentFields ? l.defaultSystemIndependentFields
    , systems ? l.defautSystems
    }: f:
    let
      defaultInstances =
        (l.genAttrs
          systems
          (system:
            let
              args = {
                localSystem = l.systems.elaborate system;
                crossSystem = l.systems.elaborate system;
              };
              newInputs =
                if deSystemizeInput
                then l.callFlakesDeSystemize inputs args
                else l.callFlakes inputs args;
            in
            f newInputs args
          )
        );

      warnInvalidAccessToSystemArgs =
        l.warn ''
          flake-param: Illegal reference to a system argument.
          Do not access system-specific arguments such as "localSystem" or "crossSystem" in fields marked as system-independent.
          System-independent fields: ${l.toJSON systemIndependentFields}.
        '';

      noSystemInstance =
        let
          args = {
            localSystem = warnInvalidAccessToSystemArgs { _ = "invalid system"; };
            crossSystem = warnInvalidAccessToSystemArgs { _ = "invalid system"; };
          };
          newInputs = l.callFlakes inputs args;
        in
        f newInputs args;

      systemIndependentAttrs =
        l.intersectAttrs
          (l.attrNamesToAttr
            systemIndependentFields
            null
          )
          noSystemInstance;

      systemDependentAttrs =
        l.mergeListOfAttrsRecurseOnce
          (l.mapAttrsToList
            (system: instance:
              l.concatMapAttrs
                (fieldName: field:
                  if l.hasAttr fieldName systemIndependentAttrs then
                    { }

                  else
                    {
                      ${fieldName}.${system} =
                        if deSystemizeOutput && (l.hasAttr system field)
                        then field.${system}
                        else field;
                    }
                )
                instance
            )
            defaultInstances
          );

    in
    systemDependentAttrs // systemIndependentAttrs // {
      inherit systemIndependentFields;
      ${l.funcName} = l.makeFun inputs f;
    };
}
