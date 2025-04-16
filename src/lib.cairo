#[starknet::interface]
trait IGame<TContractState> {
    fn start_new_game(ref self: TContractState);
    fn make_decision(ref self: TContractState, choice: felt252) -> u16;
    fn get_current_node(self: @TContractState) -> u16;
}

#[starknet::contract]
mod StoryContract {
    use core::array::ArrayTrait;
    use core::traits::Into;
    use starknet::ContractAddress;
    //use starknet::get_caller_address;
    use starknet::storage::Map;
    use starknet::storage::StorageMapReadAccess;
    use starknet::storage::StorageMapWriteAccess;

    #[storage]
    struct Storage {
        player_current_node: Map<ContractAddress, u16>,
        player_decision_history: Map<(ContractAddress, u16), u8>,
        decision_tree: Map<(u16, u8), u16>,
        player_story_completed: Map<ContractAddress, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Decision: Decision,
        StoryCompleted: StoryCompleted,

    }
    
    #[derive(Drop, starknet::Event)]
    struct Decision {
        player: ContractAddress,
        node_id: u16,
        choice: u8,
        next_node: u16,
    }

    #[derive(Drop, starknet::Event)]
    struct StoryCompleted {
        player: ContractAddress,
        final_node: u16,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
    // Początkowe ustawienie drzewa decyzyjnego
        self.decision_tree.write((1_u16, 1_u8), 10_u16);
        self.decision_tree.write((1_u16, 2_u8), 11_u16);
        self.decision_tree.write((10_u16, 1_u8), 100_u16);
        self.decision_tree.write((10_u16, 2_u8), 101_u16);
        self.decision_tree.write((11_u16, 1_u8), 110_u16);
        self.decision_tree.write((11_u16, 2_u8), 111_u16);
        self.decision_tree.write((101_u16, 1_u8), 1010_u16);
        self.decision_tree.write((101_u16, 2_u8), 1011_u16);
        self.decision_tree.write((110_u16, 1_u8), 1100_u16);
        self.decision_tree.write((110_u16, 2_u8), 1101_u16);
    }

    #[abi(embed_v0)]
    impl GameImpl of super::IGame<ContractState> {
        fn start_new_game(ref self: ContractState) {
            //let player = get_caller_address();
            self.player_current_node.write(0.try_into().unwrap(), 1);
        }

        fn make_decision(ref self: ContractState, choice: felt252) -> u16 {
            let choice: u8 = choice.try_into().unwrap();
            //let player = get_caller_address();
            let current_node = self.player_current_node.read(0.try_into().unwrap());

            assert(!self.player_story_completed.read(0.try_into().unwrap()), 'Story Already Completed!');

            let next_node = self.calculate_next_node(current_node, choice);

            self.player_decision_history.write((0.try_into().unwrap(), current_node), choice);

            self.player_current_node.write(0.try_into().unwrap(), next_node);

            if self.is_ending_node(next_node) {
                self.player_story_completed.write(0.try_into().unwrap(), true);
                self.emit(Event::StoryCompleted(StoryCompleted {player: 0.try_into().unwrap(), final_node: next_node}));
            }

            self.emit(Event::Decision(Decision {player: 0.try_into().unwrap(), node_id: current_node, choice, next_node}));

            next_node
        }

        // View functions
        fn get_current_node(self: @ContractState) -> u16 {
            //self.player_current_node.read(get_caller_address())
            self.player_current_node.read(0.try_into().unwrap())
            
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        // Calculate next story node based on current node and choice
        fn calculate_next_node(self: @ContractState, current_node: u16, choice: u8) -> u16 {
            let next_node = self.decision_tree.read((current_node, choice));
            //assert(current_node == 1_u16, 'Invalid current node');
            //assert(choice == 1_u8, 'Invalid choice');
            //assert(next_node == 10_u16, 'Invalid next node');
            assert(current_node != 0_u16, 'Invalid node');
            assert(next_node != current_node, 'Error with calculating new node');
            assert(choice == 1_u8 || choice == 2_u8, 'Invalid choice');
            next_node
        }

        // Check if current node is an ending
        fn is_ending_node(self: @ContractState, node: u16) -> bool {
            node == 100 || node == 111 || node == 1010 || node == 1011 || node == 1100 || node == 1101
        }
    }
}