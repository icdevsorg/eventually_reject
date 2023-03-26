import MigrationTypes "../types";
import v0_0_1_types = "types";

import Map_lib "mo:map_8_0_0/Map"; 
import Set_lib "mo:map_8_0_0/Set"; 

import Principal "mo:base/Principal"; 

module {
  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {


    return #v0_0_1(#data(
      {
        var pending : Map_lib.Map<Nat, Nat> = Map_lib.new<Nat,Nat>(Map_lib.nhash);
        var newTimer : Nat = 0;
        var neuron_id = 14231996777861930328;
        var log : Set_lib.Set<Text> = Set_lib.new<Text>(Set_lib.thash);
        var admin : Principal = Principal.fromText("k3gvh-4fgvt-etjfk-dfpfc-we5bp-cguw5-6rrao-65iwb-ttim7-tt3bc-6qe");
      }));
  };

   public func downgrade(migration_state: MigrationTypes.State, args: MigrationTypes.Args): MigrationTypes.State {
    return #v0_0_0(#data);
  };

  
};