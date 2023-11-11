#[starknet::contract]
mod CredentialContract {
    use starknet::{ContractAddress, get_caller_address};
    /////////////////////////////////// OpenZeppelin inegration /////////////////////////////////
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin::access::accesscontrol::DEFAULT_ADMIN_ROLE;

    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    const MINTER_ROLE: felt252 = 'MINTOR_ROLE';

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

    //  Access Control 
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlCamelImpl =
        AccessControlComponent::AccessControlCamelImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    ////////////////////////////////////////////////////////

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        counter : u256
    }


    ////////////////////////////////
    // Constructor - initialized on deployment
    ////////////////////////////////
    #[constructor]
    fn constructor(ref self: ContractState,) {
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(MINTER_ROLE, get_caller_address());
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, get_caller_address());
        self.erc721.initializer('Credential Soulbound Token', 'CST');
    }
    #[external(v0)]
    #[generate_trait]
    impl IProjectControllerContractImpl of ProjectControllerContractTrait {// mint function 
  
    fn mint (
        ref self: ContractState,
        to: ContractAddress,
       
    ) {
        self.accesscontrol.assert_only_role(MINTER_ROLE);
        let mut _counter = self.counter.read();
        _counter += 1;
        self.counter.write(_counter);
        
       self.erc721._mint(to, _counter);
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
        #[flat]
        AccessControlEvent: AccessControlComponent::Event
    }
}
