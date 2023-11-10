#[starknet::interface]
trait IProjectControllerContract<TContractState> {
    fn create_project(ref self: TContractState,  project_cid : felt252,reward: felt252,orgId: felt252,
         deadline:felt252);
     
}

#[starknet::contract]
mod projectControllerContract {
    use starknet::ContractAddress;
    #[derive(Copy, Drop, starknet::Store)]
    enum ProposalStatus {
            Proposed,
            Accepted,
            Rejected,
            Awarded
        }
    #[derive(Copy, Drop, starknet::Store)]
    enum QuestStatus {
        Open,
        Closed,
        Awarded
    }
      ////////////////////////////////
    // Project structs go here
    ////////////////////////////////
    #[derive(Copy, Drop, starknet::Store)]
    struct Quest {
        id: felt252,
        cid: felt252,
        reward: felt252,
        orgId: felt252,
        deadline: felt252,
        winner_proposalId: felt252,
    }
    #[derive(Copy, Drop, starknet::Store)]
    struct Proposal {
        id: felt252,
        cid: felt252,
        proposer: felt252,
        quest_id: felt252,
        status: ProposalStatus,
        work_cid: felt252,
    }
    #[storage]
    struct Storage {
        quests :  LegacyMap::<felt252, Quest>,
        proposals :  LegacyMap::<felt252, Proposal>,
        proposal_ids :  LegacyMap::<(felt252,ContractAddress), felt252>,
        total_quests: felt252,
        credential: ContractAddress,
        organization_controller: ContractAddress
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
    }

}
