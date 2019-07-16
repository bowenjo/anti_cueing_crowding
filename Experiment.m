classdef Experiment
    %Experiment: Module for running experiments
    %   Methods:
    %   1) append_block
    %       appends a block module for running a designated amount of
    %       trials
    %   2) run
    %       runs the full experiment (all appended blocks)
    
    properties
    blocks % containers.Map() - blocks of the experiment
    nTrialTracker % containers.Map() - the number of trials in each block
    end
    
    methods
        function self = Experiment()
            self.blocks = containers.Map();
            self.nTrialTracker = containers.Map();
        end
        
        function append_block(self, index, Module, nTrials)
            %append_block Appends an experiment block to the full design
            %   index - str - the container key
            %   Module - MatLab class - the block module containing all the
            %       design information for the block of trials
            %   nTrials - int - the number of trials to run the block
            self.blocks(index) = Module;
            self.nTrialTracker(index) = nTrials;
        end
        
        function run(self)
            blockKeys = keys(self.blocks);
            for i = 1:length(blockKeys)
                key = blockKeys{i};
                block = self.blocks(key);
                nTrials = self.nTrialTracker(key);
                block.run(nTrials, key);
            end
            Eyelink('StopRecording');
        end
        
        function resultsTable = save_run(self, file)
            blockKeys = keys(self.blocks);
            Trial = [];
            for i = 1:length(blockKeys)
                key = blockKeys{i};
                block = self.blocks(key);
                [Trial, resultKeys] = block.dump_results_info(Trial);
            end
            
            resultsTable = array2table(Trial, 'RowNames', resultKeys);
            save(file, 'resultsTable')
        end
    end
end



            

