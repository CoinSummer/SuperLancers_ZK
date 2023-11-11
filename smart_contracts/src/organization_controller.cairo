#[starknet::contract]
mod OrganizationControllerContract {
    use option::OptionTrait;
    use starknet::{ContractAddress, get_caller_address};
    use serde::Serde;
    /////////////////////////////// OZ work /////

    use openzeppelin::security::pausable::PausableComponent;
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);

    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl InternalImpl = PausableComponent::InternalImpl<ContractState>;


    ///////////////////////////////
    ////////////////////////////////
    // Org structs go here
    ////////////////////////////////
    #[derive(Copy, Drop, starknet::Store, Serde)]
    struct Organization {
        id: u256,
        cid: felt252,
        name: felt252,
        admin: ContractAddress,
    }

    #[storage]
    struct Storage {
        organizations: LegacyMap::<u256, Organization>,
        admin_to_org_id: LegacyMap::<ContractAddress, u256>,
        total_orgs: u256,
        #[substorage(v0)]
        pausable: PausableComponent::Storage
    }


    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(ref self: ContractState) {}
    #[external(v0)]
    #[generate_trait]
    impl IOrganizationControllerContractImpl of OrganizationControllerContractTrait {
        fn register_org(
            ref self: ContractState, cid: felt252, name: felt252, admin: ContractAddress
        ) {
            assert(!self.pausable.is_paused(), 'Should not be paused');
            let mut id = self.total_orgs.read();
            let org = Organization { id, cid, name, admin, };
            self.organizations.write(id, org);
            self.admin_to_org_id.write(admin, id);
            self.total_orgs.write(id + 1);
            self.emit(Register { id, cid, name, admin, });
        }

        fn update_org(
            ref self: ContractState, cid: felt252, name: felt252, admin: ContractAddress
        ) {
            assert(!self.pausable.is_paused(), 'Should not be paused');
            let org_id = self.admin_to_org_id.read(admin);
            let mut org = self.organizations.read(org_id);
            org.cid = cid;
            org.name = name;
            org.admin = admin;
            self.organizations.write(org_id, org);
            self.emit(OrgUpdate { id: org_id, cid, name, admin, });
        }
    }

    //////////////////// Events go here //////////////////////////////////
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Register: Register,
        #[flat]
        PausableEvent: PausableComponent::Event,
        OrgUpdate: OrgUpdate,
    }

    /// Emitted when org are registered.
    #[derive(Drop, starknet::Event)]
    struct Register {
        #[key]
        id: u256,
        admin: ContractAddress,
        cid: felt252,
        name: felt252,
    }
    #[derive(Drop, starknet::Event)]
    struct OrgUpdate {
        #[key]
        id: u256,
        admin: ContractAddress,
        cid: felt252,
        name: felt252,
    }
}
