function printAllNWBTables(nwb)
% printAllNWBTables  Iterates through the NWB object and prints all DynamicTables
%   to the command window for sanity checking.

    fprintf('\n========== NWB TABLE SANITY CHECK ==========\n');

    %% 1. Top-Level Electrodes Table
    if ~isempty(nwb.general_extracellular_ephys_electrodes)
        fprintf('\n--- Table: general_extracellular_ephys_electrodes ---\n');
        nwb.general_extracellular_ephys_electrodes.toTable()
    end

    %% 2. Top-Level Units Table (IC Spikes)
    if ~isempty(nwb.units)
        % Note: nwb.units.toTable() can be huge if there are many spikes. 
        % It prints the first few rows and last few rows.
        fprintf('\n--- Table: units (IC Spikes) ---\n');
        nwb.units.toTable()
    end

    %% 3. Processing Modules
    if ~isempty(nwb.processing)
        moduleNames = nwb.processing.keys();
        
        for iMod = 1:numel(moduleNames)
            modName = moduleNames{iMod};
            module = nwb.processing.get(modName);
            
            fprintf('\n>>> Processing Module: %s <<<\n', modName);

            % Check for DataInterfaces (e.g., ElectricalSeries are not tables, skip)
            % We are specifically looking for DynamicTables here.
            
            if ~isempty(module.dynamictable)
                tableNames = module.dynamictable.keys();
                
                for iTbl = 1:numel(tableNames)
                    tblName = tableNames{iTbl};
                    tbl = module.dynamictable.get(tblName);
                    
                    if isa(tbl, 'types.hdmf_common.DynamicTable')
                        fprintf('\n--- Table: %s.%s ---\n', modName, tblName);
                         if strcmp(tblName, 'abr_wave_annotations')
                            warning('currently unable to print ABR_Wave_tables, but they exist')
                        else
                            % Use standard printer for 2D data
                            tbl.toTable()
                        end
                    end
                end
            else
                fprintf('  (No DynamicTables found in this module)\n');
            end
        end
    end

    fprintf('\n========== END SANITY CHECK ==========\n\n');
end
