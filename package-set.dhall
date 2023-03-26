let aviate_labs = https://github.com/aviate-labs/package-set/releases/download/v0.1.8/package-set.dhall sha256:9ab42c1f732299dc8c1f631d39ea6a2551414bf6efc8bbde4e11e36ebc6d7edd
let vessel_package_set =
      https://github.com/dfinity/vessel-package-set/releases/download/mo-0.8.3-20230224/package-set.dhall
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  -- This is where you can add your own packages to the package-set
  additions =
    [{ name = "map_8_0_0"
  , repo = "https://github.com/ZhenyaUsenko/motoko-hash-map"
  , version = "v8.0.0"
  , dependencies = [ "base"]
  }
] : List Package

let
  {- This is where you can override existing packages in the package-set

     For example, if you wanted to use version `v2.0.0` of the foo library:
     let overrides = [
         { name = "foo"
         , version = "v2.0.0"
         , repo = "https://github.com/bar/foo"
         , dependencies = [] : List Text
         }
     ]
  -}
  overrides =
    [] : List Package

in  aviate_labs # vessel_package_set # additions # overrides
