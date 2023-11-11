
#[starknet::interface]
trait IProjectControllerContract<TContractState> {
    fn register_project(ref self: TContractState,  project_cid : felt252,reward: felt252,orgId: felt252,
         deadline:felt252);
    fn submit_work(ref self: TContractState,  project_id : felt252,work_cid: felt252);
    fn accept_work(ref self: TContractState,  submission_id : felt252);
     fn get_project_status(self: @TContractState, project_id: felt252) -> felt252;
    //  fn get_project(self: @TContractState,  project_id: felt252) -> Project;
     
}

#[starknet::contract]
mod projectControllerContract {
use option::OptionTrait;
use starknet::{ContractAddress,get_caller_address};
use openzeppelin::access::accesscontrol::AccessControlComponent;

    #[derive(Copy, Drop, starknet::Store)]
    enum SubmissionStatus {
            Proposed,
            Accepted,
            Rejected,
            Awarded
        }
    #[derive(Copy, Drop, starknet::Store)]
    enum ProjectStatus {
        Open,
        Closed,
        Awarded
    }
      ////////////////////////////////
    // Project structs go here
    ////////////////////////////////
    #[derive(Copy, Drop, starknet::Store)]
    struct Project {
        id: felt252,
        cid: felt252,
        reward: felt252,
        orgId: felt252,
        deadline: felt252,
        winner_proposalId: felt252,
    }
    #[derive(Copy, Drop, starknet::Store)]
    struct Submission {
        id: felt252,
        cid: felt252,
        submittor: ContractAddress,
        project_id: felt252,
        status: SubmissionStatus,
        work_cid: felt252,
    }
    #[storage]
    struct Storage {
        projects :  LegacyMap::<felt252, Project>,
        submissions :  LegacyMap::<felt252, Submission>,
        submission_ids :  LegacyMap::<(felt252,ContractAddress), felt252>,
        total_projects: felt252,
        credential: ContractAddress,
        organization_controller: ContractAddress
    }



    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(ref self: ContractState,  credential: ContractAddress,
        organization_controller: ContractAddress) {
        
    }
 #[external(v0)]
#[generate_trait]
impl IProjectControllerContractImpl of ProjectControllerContractTrait{
     
        fn register_project(ref self: ContractState,  project_cid : felt252,reward: felt252,orgId: felt252,
         deadline:felt252){
             self.emit(
            Register{ project_cid, reward, by:get_caller_address(), orgId,deadline}
            );
        }
}


















    //////////////////// Events go here //////////////////////////////////
       #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Register: Register,
     }

    /// Emitted when projects are registered.
    #[derive(Drop, starknet::Event)]
    struct Register {
        #[key]
        project_cid : felt252,
        reward: felt252,
        by: ContractAddress,
        orgId: felt252,
         deadline:felt252
    }

}
