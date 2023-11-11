
#[starknet::interface]
trait IProjectControllerContract<TContractState> {
    fn register_project(ref self: TContractState,  project_cid : felt252,reward: felt252,orgId: felt252,
         deadline:felt252);
    fn submit_work(ref self: TContractState,  project_id : felt252,work_cid: felt252);
    fn accept_work(ref self: TContractState,  submission_id : felt252);
     fn get_project_status(self: @TContractState, project_id: felt252) -> felt252;
     fn is_proiject_exist(self: @TContractState, project_id: felt252) -> bool;
     fn is_submission_exist(self: @TContractState, project_id: felt252) -> bool;
    //  fn get_project(self: @TContractState,  project_id: felt252) -> Project;
     
}

#[starknet::contract]
mod projectControllerContract {
use option::OptionTrait;
use starknet::{ContractAddress,get_caller_address};
use openzeppelin::access::accesscontrol::AccessControlComponent;
use serde::Serde;

    #[derive(Copy, Drop, starknet::Store,Serde)]
    enum SubmissionStatus {
            Proposed,
            Accepted,
            Rejected,
            Awarded
        }
    #[derive(Copy, Drop, starknet::Store,Serde)]
    enum ProjectStatus {
        Open,
        Closed,
        Awarded
    }
      ////////////////////////////////
    // Project structs go here
    ////////////////////////////////
    #[derive(Copy, Drop, starknet::Store, Serde)]
    struct Project {
        id: felt252,
        cid: felt252,
        reward: felt252,
        orgId: felt252,
        deadline: felt252,
        winner_proposalId: felt252,
    }
    #[derive(Copy, Drop, starknet::Store,Serde)]
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

            self.credential.write (credential);
            self.organization_controller.write (organization_controller);
        
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


        fn submit_work(ref self: ContractState,  project_id : felt252,work_cid: felt252){
             self.emit(
            WorkSubmitted{  project_cid : 2,
        work_id: 5,
        worker: get_caller_address(),
        work_cid}
            );
        }


        fn accept_work(ref self: ContractState,  submission_id : felt252){
             self.emit(
            WorkAccepted{ project_cid : 4,
        worker: get_caller_address()}
            );
        }
     fn get_project_status(self: @ContractState, project_id: felt252) -> felt252{
            0
        }
     fn is_proiject_exist(self: @ContractState, project_id: felt252) -> bool{
        true
     }
     fn is_submission_exist(self: @ContractState, submission_id: felt252) -> bool{
        false
     }
     fn get_project(self: @ContractState,  project_id: felt252) -> Project{
        self.projects.read(project_id)       
     }
     fn get_submission(self: @ContractState,  submission_id: felt252) -> Submission{
        self.submissions.read(submission_id)       
     }
    
}


















    //////////////////// Events go here //////////////////////////////////
       #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Register: Register,
        WorkSubmitted: WorkSubmitted,
        WorkAccepted: WorkAccepted,
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
    #[derive(Drop, starknet::Event)]
    struct WorkSubmitted {
        #[key]
        project_cid : felt252,
        work_id: felt252,
        worker: ContractAddress,
        work_cid: felt252,
     }
    #[derive(Drop, starknet::Event)]
    struct WorkAccepted {
        #[key]
        project_cid : felt252,
        worker: ContractAddress,
     }

}
