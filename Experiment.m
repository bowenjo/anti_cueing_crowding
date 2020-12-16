classdef Experiment < handle
    %Experiment: Module for running experiments
    %   Methods:
    %   1) append_block
    %       appends a block module for running a designated amount of
    %       trials
    %   2) run
    %       runs the full experiment (all appended blocks)
    %   3) save_run
    %       saves the experiment design for each block to a file
        
    properties
    blocks % struct - blocks of the experiment
    nTrialTracker % struct - the number of trials in each block
    checkpoint % struct - checkpointing info for resuming a saved run
    end
    
    methods
        function self = Experiment()
            % ------------------------------------
            % Construct an instance of the class
            % ------------------------------------
            self.blocks = struct;
            self.nTrialTracker = struct;
            
            % initialize checkpointing
            self.checkpoint = struct;
            self.checkpoint.trial = 1;
            self.checkpoint.block = '';
        end
        
        function append_block(self, index, Module, nTrials)
            % -----------------------------------------------------------
            % Appends an experiment block to the full design
            %   index - str - the field name for the block
            %   Module - MatLab class - the block module containing all the
            %       design information for the block of trials
            %   nTrials - int - the number of trials to run the block
            % -----------------------------------------------------------
            self.blocks.(index) = Module;
            self.nTrialTracker.(index) = nTrials;
        end
        
        function run(self, blockIndices, file)
            % ------------------------------------------------------------
            % Runs a block
            %   blockIndices - cell array - block indices to run
            %   file - str - file to save experiment design and results to
            % ------------------------------------------------------------
            if isempty(blockIndices)
                blockIndices = fields(self.blocks)';
            end
            
            startBlockIdx = 1;
            % get the checkpointed block index
            if ~isempty(self.checkpoint.block)
                for key = blockIndices
                    if string(key) == self.checkpoint.block
                        break
                    else
                        startBlockIdx = startBlockIdx + 1;
                    end
                end
                % if the checkpointed block is not in the block indices
                if startBlockIdx-1 == length(blockIndices)
                    startBlockIdx = 1;
                end
            end
            
            for key = blockIndices(startBlockIdx:length(blockIndices))
                % update checkpoint block
                self.checkpoint.block = key;
                % save the experiment
                if ~isempty(file)
                    save(file, 'self')
                end
                
                % get the block info
                block = self.blocks.(string(key));
                startTrial = self.checkpoint.trial;
                nTrials = self.nTrialTracker.(string(key));
                
                % run the block
                [stopTrial, rsp] = block.run(startTrial, nTrials, key);
                % if experiment was paused part way
                while stopTrial < nTrials && string(rsp) == "pause" 
                    % update checkpoint and save
                    self.checkpoint.trial = stopTrial;
                    if ~isempty(file)
                        save(file, 'self')
                    end
                    
                    % pause the screen
                    Pause = WaitScreen(block.window, block.windowRect, ...
                        'Paused', 70, []);
                    Pause.run(0, 0, 0);
                    % continue running the experiment
                    [stopTrial, rsp] = block.run(stopTrial+1, nTrials, key);
                end
                % reset the trial tracker
                self.checkpoint.trial = 1;
            end
            Eyelink('StopRecording');
        end
        
        function results = save_run(self, file, blockIndices)
            % ------------------------------------------------------
            % Dumps the results for each block in blockIndices
            % into a single results structure
            %   file - str - file to save results
            %   blockIndices - list - block indices to save
            % ------------------------------------------------------
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



            

