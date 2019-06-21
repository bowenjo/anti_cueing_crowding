classdef Experiment
    %EXPERIMENT Module for running experiments
    %   Detailed explanation goes here
    
    properties
    blocks % blocks of the experiment
    nTrialTracker
    end
    
    methods
        function self = Experiment()
            self.blocks = containers.Map();
            self.nTrialTracker = containers.Map();
        end
        
        function [] = append_block(self, index, Module, nTrials)
            %append_block Appends an experiment block to the full design
            %   Detailed explanation goes here
            self.blocks(index) = Module;
            self.nTrialTracker(index) = nTrials;
        end
        
        function [] = run(self)
            blockKeys = keys(self.blocks);
            for i = 1:length(blockKeys)
                key = blockKeys{i};
                block = self.blocks(key);
                nTrials = self.nTrialTracker(key);
                block.run(nTrials);
            end
        end
    end
end



            

