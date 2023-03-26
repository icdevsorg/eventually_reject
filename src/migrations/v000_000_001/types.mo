import Map_lib "mo:map_8_0_0/Map"; 

import Set_lib "mo:map_8_0_0/Set"; 

module {
  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  

  public let Map = Map_lib;

  public type State = {
    // this is the data you previously had as stable variables inside your actor class
    var pending : Map.Map<Nat,  Nat>; //(proposalid, (timerid, timetovote))
    var newTimer : Nat;
    var neuron_id : Nat;
    var log : Set_lib.Set<Text>;
    var admin : Principal;
  };
};
