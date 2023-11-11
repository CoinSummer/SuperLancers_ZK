
#[starknet::interface]
trait IProjectControllerContract<TContractState> {
    fn register_project(ref self: TContractState,  project_cid : felt252,reward: felt252,orgId: felt252,
         deadline:felt252);
    fn submit_work(ref self: TContractState,  project_id : u256,work_cid: felt252);
    fn accept_work(ref self: TContractState,  submission_id : u256);
     fn get_project_status(self: @TContractState, project_id: u256) -> felt252;
     fn is_proiject_exist(self: @TContractState, project_id: u256) -> bool;
     fn is_submission_exist(self: @TContractState, project_id: u256) -> bool;
     //  fn get_project(self: @TContractState,  project_id: felt252) -> Project;
    //  fn get_submission(self: @TContractState,  submission_id: felt252) -> Submission;
    //   fn get_project_status(self: @TContractState, project_id: felt252) -> ProjectStatus;
}

#[starknet::contract]
mod projectControllerContract {
use option::OptionTrait;
use starknet::{ContractAddress,get_caller_address};
use serde::Serde;
/////////////////////////////////// OpenZeppelin inegration /////////////////////////////////
use openzeppelin::access::accesscontrol::AccessControlComponent;
   use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);


 #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;


////////////////////////////////////////////////////////
    #[derive(Copy, Drop, starknet::Store,Serde)]
    enum SubmissionStatus {
            Proposed,
            Accepted,
            Rejected
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
        id: u256,
        cid: felt252,
        reward: felt252,
        orgId: felt252,
        deadline: felt252,
        status: ProjectStatus,
        winner_proposalId: u256,
    }
    #[derive(Copy, Drop, starknet::Store,Serde)]
    struct Submission {
        id: u256,
        cid: felt252,
        submittor: ContractAddress,
        project_id: u256,
        status: SubmissionStatus,
        work_cid: felt252,
    }
    #[storage]
    struct Storage {
          #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        projects :  LegacyMap::<u256, Project>,
        submissions :  LegacyMap::<u256, Submission>,
        submission_ids :  LegacyMap::<(u256,ContractAddress), u256>,
        total_projects: u256,
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
             self.erc721.initializer('Project Controller', 'PC');
             // for testing only
        self.erc721._mint(get_caller_address(), 1);
        self.erc721._set_token_uri(1, 'ipfs/Qmkjdfkdfd');
        
    }
 #[external(v0)]
#[generate_trait]
impl IProjectControllerContractImpl of ProjectControllerContractTrait{
     
        fn register_project(ref self: ContractState,  project_cid : felt252,reward: felt252,orgId: felt252,
         deadline:felt252){
         /// TODO: add checks 
        // if (nonceUsed[nonce]) revert InvalidNonce();
        // if (!organizationController.exists(orgId))
        //     revert InvalidOrganizationId();
        // if (organizationController.adminOf(orgId) != msg.sender)
        //     revert Unauthorized();
        // if (deadline <= block.timestamp) revert DeadlineAlreadyPassed();
        // if (msg.value != reward) revert InvalidValue();

        // // create project 
        let total = self.total_projects.read();
        let project = Project{
            id: total,
            cid: project_cid,
            reward: reward,
            orgId: orgId,
            deadline: deadline,
            status: ProjectStatus::Open,
            winner_proposalId: 0,  
        };
        self.projects.write(total, project);
        self.total_projects.write(self.total_projects.read() + 1_u256);
            self.emit(
            Register{ project_cid, reward, by:get_caller_address(), orgId,deadline}
            );
        }


        fn submit_work(ref self: ContractState,  project_id : u256,work_cid: felt252){
          /// TODO: add more checks 
          assert(self.is_proiject_exist(project_id), 'project does not exist');
            // assert(self.get_project_status(project_id) == ProjectStatus::Open, 'project is not open');
            // assert(project.deadline > block.timestamp, 'deadline has passed')

            let submission = Submission{
                id: self.submission_ids.read((project_id,get_caller_address())),
                cid: work_cid,
                submittor: get_caller_address(),
                project_id: project_id,
                status: SubmissionStatus::Proposed,
                work_cid: work_cid,
            };
            self.submissions.write(self.submission_ids.read((project_id,get_caller_address())), submission);
          
          
            self.emit(
            WorkSubmitted{  project_cid : 2,
            work_id: 5,
            worker: get_caller_address(),
            work_cid}
                );
        }


        fn accept_work(ref self: ContractState,  submission_id : u256){
            /// TODO:: Add more logic
            assert(self.is_submission_exist(submission_id), 'submission does not exist');
            let mut submission = self.submissions.read(submission_id);
            let mut project = self.projects.read(submission.project_id);
            // assert(project.status == ProjectStatus::Open, 'project is not open');
            // assert(project.winner_proposalId == 0, 'project already has a winner');
            // assert(project.orgId == get_caller_address(), 'caller is not the organization');
            project.status = ProjectStatus::Awarded;
            project.winner_proposalId = submission_id;
            submission.status = SubmissionStatus::Accepted;
            self.projects.write(submission.project_id, project);
            self.submissions.write(submission_id, submission);
            // TODO: refund winner with reward
            // ToDo: mint NFT to winner
            self.emit(
            WorkAccepted{ project_cid : 4,
            worker: get_caller_address()}
            );
        }
     fn get_project_status(self: @ContractState, project_id: u256) -> ProjectStatus{
        let project = self.projects.read(project_id);
        project.status
        
        }
     fn is_proiject_exist(self: @ContractState, project_id: u256) -> bool{
        let project = self.projects.read(project_id);
        project.id != 0
     }
     fn is_submission_exist(self: @ContractState, submission_id: u256) -> bool{
        let submission = self.submissions.read(submission_id);
        submission.id != 0

     }
     fn get_project(self: @ContractState,  project_id: u256) -> Project{
        self.projects.read(project_id)       
     }
     fn get_submission(self: @ContractState,  submission_id: u256) -> Submission{
        self.submissions.read(submission_id)       
     }
    
}


















    //////////////////// Events go here //////////////////////////////////
       #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
          #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
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
