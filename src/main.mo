import MigrationTypes "./migrations/types";
import Migrations "./migrations";
import Types "./types";

import AccountIdentifier "mo:principal/AccountIdentifier";


import Result "mo:base/Result";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import json "mo:json/JSON";

import GovTypes "GovTypes";

import Map "mo:map_8_0_0/Map";
import Set "mo:map_8_0_0/Set";
import ExperimentalCycles "mo:base/ExperimentalCycles";

shared (deployer) actor class QuickList() = this {

  stable var migration_state: MigrationTypes.State = #v0_0_0(#data);

  stable var admin = deployer.caller;

  // Do not forget to change #v0_1_0 when you are adding a new migration
  // If you use one previous state in place of #v0_1_0 it will run downgrade methods instead
  migration_state := Migrations.migrate(migration_state, #v0_0_1(#id), {owner = deployer.caller;});

  let #v0_0_1(#data(state_current)) = migration_state;

  let { ihash; nhash; thash; phash; calcHash } = Map;

  //replace this id with the id for the governance canister you would like to m
  let gov : GovTypes.Service = actor("rrkah-fqaaa-aaaaa-aaaaq-cai");

  let twelve_hours = 60 * 60 * 12 * 1000000000;
  let eight_hours = 60 * 60 * 8 * 1000000000;

  public shared(msg) func init() : async Result.Result<Bool, Text>{
    if(msg.caller != state_current.admin){
      return #err("not authorized");
    };

    await checkForNewVotes();
    
    return #ok(true);
  };

  private func checkForNewVotes() : async (){
    try{
      if(state_current.newTimer > 0){
        Timer.cancelTimer(state_current.newTimer);
      };
     //initialize the timers
      ignore Set.put(state_current.log, Set.thash, Int.toText(Time.now()) # "Running checkForNewVotes");
      let open_items = await gov.list_proposals({
        include_reward_status = [1];
        before_proposal = null;
        limit = 1000;
        exclude_topic = [2];
        include_status = [
          0 : Int32,
          1 : Int32,
          2 : Int32,
          3 : Int32,
          4 : Int32
        ];
      });

      label process for(thisItem in open_items.proposal_info.vals()){

        let ?propid_64 = thisItem.id else continue process;
        let propid = Nat64.toNat(propid_64.id);

        switch(thisItem.deadline_timestamp_seconds){
          case(null){};
          case(?val){
            //check the ballots
            let timeToVote = (Nat64.toNat(val) * 1000000000) - twelve_hours - 360000000000;
            if(timeToVote < Int.abs(Time.now())){
              label search for(thisBallot in thisItem.ballots.vals()){
                if(thisBallot.1.vote == 0){
                  let neuron_id = Nat64.toNat(thisBallot.0);
                  ignore Map.put(state_current.pending, nhash, propid, neuron_id);
                };
              };
            };
          };
        }
      };

      //set a timer to check for new items
      ignore Set.put(state_current.log, Set.thash, Int.toText(Time.now()) # " Setting next run:" # Nat.toText(eight_hours/1000000000));
      state_current.newTimer := Timer.setTimer(#seconds(eight_hours/1000000000), checkForNewVotes);

      if(Map.size(state_current.pending) > 0){
        ignore Set.put(state_current.log, Set.thash, Int.toText(Time.now()) # " Found Needed Votes:" # Nat.toText(Map.size(state_current.pending)));
        await* processVotes();
      };
    } catch (e){
      ignore Set.put(state_current.log, Set.thash, Int.toText(Time.now()) # " Error Occured in check: " # Error.message(e));
    };
  };

  private func processVotes() : async* (){
    try{
      let aBuffer = Buffer.Buffer<(Nat, async GovTypes.ManageNeuronResponse)>(9);
      for(thisItem in Map.entries(state_current.pending)){

        ignore Set.put(state_current.log, Set.thash, Int.toText(Time.now()) # " Voting Proposal:" # Nat.toText(thisItem.0) # "  NeruonId:" # Nat.toText(thisItem.1));

        aBuffer.add((thisItem.0, gov.manage_neuron({
          id = ?{
            id = Nat64.fromNat(thisItem.1);
          };
          neuron_id_or_subaccount = null;
          command = ?#RegisterVote({
            vote = 2;
            proposal = ?{id =Nat64.fromNat(thisItem.0)};
          });

        })));

        if(aBuffer.size() >=8){
          for(thisAwait in aBuffer.vals()){
            ignore Set.put(state_current.log, Set.thash, Int.toText(Time.now()) # " Awaiting 8 Votes");
            ignore await thisAwait.1;
            Map.delete(state_current.pending, Map.nhash, thisAwait.0);
          };
          aBuffer.clear();
        };
      };

      for(thisAwait in aBuffer.vals()){
        ignore Set.put(state_current.log, Set.thash, Int.toText(Time.now()) # " Awaiting Final Votes");
        ignore await thisAwait.1;
        Map.delete(state_current.pending, Map.nhash, thisAwait.0);
      };
      ignore Set.put(state_current.log, Set.thash, Int.toText(Time.now()) # " Finished Votes");
      cleanLog();
    } catch (e){
      ignore Set.put(state_current.log, Set.thash, Int.toText(Time.now()) # " Error Occured in process: " # Error.message(e));
    };
  };

  private func cleanLog(){
    if(Set.size(state_current.log) > 1000){

      for(thisItem in Iter.range(1,100)){
        ignore Set.popFront(state_current.log);
      };

    };
    
  };

 
  // Handles http request
  public query(msg) func http_request(rawReq: Types.HttpRequest): async (Types.HTTPResponse) {


    
    


        let main_text = Buffer.Buffer<Text>(1);
        
        for(thisItem in Set.toArrayDesc(state_current.log).vals()){
          main_text.add(thisItem #  "\n\n");
        };
       

        return {
          body = Text.encodeUtf8(Text.join("", main_text.vals()));
          headers = [("Content-Type", "text/plain")];
          status_code = 200;
          streaming_strategy = null;
        };
     
  };

  public query(msg) func get_metrics(): async {
    log_size: Nat;
    timer_id: Nat;
    cycles: Nat;
    admin: Principal;
    neuron_id : Nat;
  } {
    {
      timer_id = state_current.newTimer;
      log_size = Set.size(state_current.log);
      cycles = ExperimentalCycles.balance();
      admin = state_current.admin;
      neuron_id = state_current.neuron_id;
    };
  };

 

}