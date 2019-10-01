classdef Experiment < handle
    %Experiment: Module for running experiments
    %   Methods:
    %   1) append_block
    %       appends a block module for running a designated amount of
    %       trials
    %   2) run
    %       runs the full experiment (all appended blocks)
    
    % TODO: convert all containers.Map()/tables/results matrices to be structures
    
    properties
    blocks % struct - blocks of the experiment
    nTrialTracker % struct - the number of trials in each block
    end
    
    methods
        function self = Experiment()
            self.blocks = struct;
            self.nTrialTracker = struct;
        end
        
        function append_block(self, index, Module, nTrials)
            %append_block Appends an experiment block to the full design
            %   index - str - the container key
            %   Module - MatLab class - the block module containing all the
            %       design information for the block of trials
            %   nTrials - int - the number of trials to run the block
            self.blocks.(index) = Module;
            self.nTrialTracker.(index) = nTrials;
        end
        
        function run(self, blockIndices)
            if isempty(blockIndices)
                blockIndices = fields(self.blocks)';
            end
            
            for key = blockIndices
                block = self.blocks.(string(key));
                nTrials = self.nTrialTracker.(string(key));
                block.run(nTrials, key);
            end
            Eyelink('StopRecording');
        end
        
        function results = save_run(self, file, blockIndices)
            % dumps the results for each block in blockIndices
            % into a single results structure
            results = struct;
            
            % dump all results if no indices are given
            if isempty(blockIndices)
                blockIndices = fields(self.blocks)';
            end
                
            for blockIndex = blockIndices
                block = self.blocks.(string(blockIndex));
                keys = block.dump_results_info();
                if ~isempty(keys)
                    % assign the results structure the correct fields
                    if isempty(fields(results))
                        for key = keys
                            results.(string(key)) = [];
                        end
                    end
                    % append the block results
                    for key = keys
                        results.(string(key)) = ...
                            [results.(string(key)) block.expDesign.(string(key))];
                    end
                end
            end
            % save if there is a file name
            if ~isempty(file)
                save(file, 'results');
            end
        end
    end
end



            

