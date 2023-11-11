#[starknet::interface]
trait IProjectControllerContract<TContractState> {
    fn register_project(
        ref self: TContractState,
        project_cid: felt252,
        reward: felt252,
        orgId: felt252,
        deadline: felt252
    );
    fn submit_work(ref self: TContractState, project_id: u256, work_cid: felt252);
    fn accept_work(ref self: TContractState, submission_id: u256);
    fn get_project_status(self: @TContractState, project_id: u256) -> felt252;
    fn is_proiject_exist(self: @TContractState, project_id: u256) -> bool;
    fn is_submission_exist(self: @TContractState, project_id: u256) -> bool;
//  fn get_project(self: @TContractState,  project_id: felt252) -> Project;
//  fn get_submission(self: @TContractState,  submission_id: felt252) -> Submission;
//   fn get_project_status(self: @TContractState, project_id: felt252) -> ProjectStatus;
}

#[starknet::contract]
mod ProjectControllerContract {
    use option::OptionTrait;
    use starknet::{ContractAddress, get_caller_address};
    use serde::Serde;
    use openzeppelin::token::erc20::ERC20ABIDispatcherTrait;
    use openzeppelin::token::erc20::ERC20ABIDispatcher;
    use starknet::get_contract_address;
    use integer::u256_from_felt252;

    #[derive(Copy, Drop, starknet::Store, Serde)]
    enum SubmissionStatus {
        Proposed,
        Accepted,
        Rejected
    }
    #[derive(Copy, Drop, starknet::Store, Serde)]
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
    #[derive(Copy, Drop, starknet::Store, Serde)]
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
        projects: LegacyMap::<u256, Project>,
        submissions: LegacyMap::<u256, Submission>,
        submission_ids: LegacyMap::<(u256, ContractAddress), u256>,
        total_projects: u256,
        credential: ContractAddress,
        organization_controller: ContractAddress,
        eth_address: ContractAddress,
    }


    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(
        ref self: ContractState,
        credential: ContractAddress,
        eth_address: ContractAddress,
        organization_controller: ContractAddress
    ) {
        self.credential.write(credential);
        self.organization_controller.write(organization_controller);
        self.eth_address.write(eth_address);
    }
    #[external(v0)]
    #[generate_trait]
    impl IProjectControllerContractImpl of ProjectControllerContractTrait {
        fn register_project(
            ref self: ContractState,
            project_cid: felt252,
            reward: felt252,
            orgId: felt252,
            deadline: felt252
        ) {
            /// TODO: add checks 
            // if (nonceUsed[nonce]) revert InvalidNonce();
            // if (!organizationController.exists(orgId))
            //     revert InvalidOrganizationId();
            // if (organizationController.adminOf(orgId) != msg.sender)
            //     revert Unauthorized();
            // if (deadline <= block.timestamp) revert DeadlineAlreadyPassed();
 
            // // create project 
            let allowance = ERC20ABIDispatcher { contract_address: self.eth_address.read() }
                .allowance(get_caller_address(), get_contract_address());
            assert(allowance >= u256_from_felt252(reward), 'approve at least 0.001 ETH!');

            ERC20ABIDispatcher { contract_address: self.eth_address.read() }.transfer_from(get_caller_address(), get_contract_address(), u256_from_felt252(reward));

            let total = self.total_projects.read();
            let project = Project {
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
            self.emit(Register { project_cid, reward, by: get_caller_address(), orgId, deadline });
        }


        fn submit_work(ref self: ContractState, project_id: u256, work_cid: felt252) {
            /// TODO: add more checks 
            assert(self.is_proiject_exist(project_id), 'project does not exist');
            // assert(self.get_project_status(project_id) == ProjectStatus::Open, 'project is not open');
            // assert(project.deadline > block.timestamp, 'deadline has passed')

            let submission = Submission {
                id: self.submission_ids.read((project_id, get_caller_address())),
                cid: work_cid,
                submittor: get_caller_address(),
                project_id: project_id,
                status: SubmissionStatus::Proposed,
                work_cid: work_cid,
            };
            self
                .submissions
                .write(self.submission_ids.read((project_id, get_caller_address())), submission);

            self
                .emit(
                    WorkSubmitted {
                        project_cid: 2, work_id: 5, worker: get_caller_address(), work_cid
                    }
                );
        }


        fn accept_work(ref self: ContractState, submission_id: u256) {
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
            let sumbmission= self.submissions.read(submission_id);
            let winner = sumbmission.submittor;
            // TODO: refund winner with reward
             ERC20ABIDispatcher { contract_address: self.eth_address.read() }.transfer_from( get_contract_address(),winner, u256_from_felt252(project.reward));

            // ToDo: mint NFT to winner
            self.emit(WorkAccepted { project_cid: 4, worker: get_caller_address() });
        }
        fn get_project_status(self: @ContractState, project_id: u256) -> ProjectStatus {
            let project = self.projects.read(project_id);
            project.status
        }
        fn is_proiject_exist(self: @ContractState, project_id: u256) -> bool {
            let project = self.projects.read(project_id);
            project.id != 0
        }
        fn is_submission_exist(self: @ContractState, submission_id: u256) -> bool {
            let submission = self.submissions.read(submission_id);
            submission.id != 0
        }
        fn get_project(self: @ContractState, project_id: u256) -> Project {
            self.projects.read(project_id)
        }
        fn get_submission(self: @ContractState, submission_id: u256) -> Submission {
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
        project_cid: felt252,
        reward: felt252,
        by: ContractAddress,
        orgId: felt252,
        deadline: felt252
    }
    #[derive(Drop, starknet::Event)]
    struct WorkSubmitted {
        #[key]
        project_cid: felt252,
        work_id: felt252,
        worker: ContractAddress,
        work_cid: felt252,
    }
    #[derive(Drop, starknet::Event)]
    struct WorkAccepted {
        #[key]
        project_cid: felt252,
        worker: ContractAddress,
    }
}
