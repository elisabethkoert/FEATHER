function [nwb, abrElecRegion, icElecTableOffset] = setupElectrodes(nwb, ee, hasIC)
% setupElectrodes  Creates the unified electrode table and regions.
%  NWB requires exactly ONE electrodes table for the whole file
%  (nwb.general_extracellular_ephys_electrodes). We build ABR's 3 rows and
%  IC's 32 rows (if IC data exists for this animal) as parallel vectors
%  FIRST, then concatenate into one combined table, THEN derive per-
%  modality DynamicTableRegions pointing at the combined table's row
%  ranges. This must happen before any ElectricalSeries/Units are built.
%  ========================================================================

    % --- ABR Device/Group ---
    abrDevice = types.core.Device(...
        'description', 'Custom-built ABR differential amplifier with needle electrodes', ...
        'manufacturer', 'custom-built');
    nwb.general_devices.set('ABR_amplifier', abrDevice);

    % ElectrodeGroup: a logical grouping of electrodes that share a device/location.
    % Here, all 3 needle electrodes (vertex, retroauricular ref, hindlimb ground)
    % belong to one group since they're part of one differential recording setup.
    abrElectrodeGroup = types.core.ElectrodeGroup(...
        'description', 'Needle electrode set for ABR: vertex (active), retroauricular (reference), hindlimb (ground)', ...
        'location', 'scalp/subdermal', ...
        'device', types.untyped.SoftLink(abrDevice));
    nwb.general_extracellular_ephys.set('ABR_electrodes', abrElectrodeGroup);

    nABRelec = 3;
    abrLocations  = {'vertex (active)'; 'retroauricular (reference)'; 'hindlimb (ground)'};
    abrGroupRefs  = repmat(types.untyped.ObjectView(abrElectrodeGroup), nABRelec, 1);
    abrGroupNames = repmat({'ABR_electrodes'}, nABRelec, 1);
    abrDepths     = nan(nABRelec, 1);

    % --- IC Device/Group ---
    nICelec = 0;
    icLocations = {}; icGroupRefs = []; icGroupNames = {}; icDepths = [];

    if hasIC
        % Load user input to get electrode name if available
        in_dir_name = fullfile(expProcDataDir(ee.ExperimenterID, ee.ExpID), 'ICME', strcat("ICUserInput_", ee.ExpID, ".mat"));
        if isfile(in_dir_name)
            load(in_dir_name, 'UT'); % loads UT
            if exist('Electrode','var')
                electrode_name = Electrode.name;
            else
                electrode_name = 'unknown';
            end
        else
            error(sprintf('no IC user input table found for %s but trying to exprot IC data',ee.ExpID))
        end

        icDevice = types.core.Device(...
            'description', 'A1x32-6mm-50-177-A32, 32 channel linear MEA', ...
            'serial_number', electrode_name, ...
            'manufacturer', 'NeuroNexus');
        nwb.general_devices.set('IC_MEA', icDevice);

        icElectrodeGroup = types.core.ElectrodeGroup(...
            'description', 'Linear 32-channel IC probe', ...
            'location', 'inferior colliculus', ...
            'device', types.untyped.SoftLink(icDevice));
        nwb.general_extracellular_ephys.set('IC_array', icElectrodeGroup);

        nICelec = 32;
        icLocations  = repmat({'inferior colliculus'}, nICelec, 1);
        icGroupRefs  = repmat(types.untyped.ObjectView(icElectrodeGroup), nICelec, 1);
        icGroupNames = repmat({'IC_array'}, nICelec, 1);
        icDepths = (0:nICelec-1)' * 50;    % elecN (0-based) = depth N*50um from dorsal-most (elec0) to ventral-most (elec31)
    end

    % --- Concatenate into ONE combined electrode table ---
    allLocations  = [abrLocations;  icLocations];
    allGroups     = [abrGroupRefs;  icGroupRefs];
    allGroupNames = [abrGroupNames; icGroupNames];
    allDepths     = [abrDepths;     icDepths];
    
    % Electrode table: one row per physical electrode.
    % Every column (VectorData) MUST have both 'data' and 'description' -
%     % missing 'description' will cause export to fail with a required-property error.
%     combinedElecTable = types.hdmf_common.DynamicTable(...
%         'description', 'All electrodes across ABR and IC recordings for this session', ...
%         'colnames', {'location', 'depth_on_array', 'group', 'group_name'});
%     
%     combinedElecTable.vectordata.set('location', types.hdmf_common.VectorData(...
%         'data', cellstr(allLocations), 'description', 'Anatomical location/placement of electrode'));
%     combinedElecTable.vectordata.set('depth_on_array', types.hdmf_common.VectorData(...
%         'data', allDepths, 'description', 'Depth in um along linear array from dorsal-most contact'));
%     combinedElecTable.vectordata.set('group', types.hdmf_common.VectorData(...
%         'data', allGroups, 'description', 'Reference to the ElectrodeGroup'));
%     combinedElecTable.vectordata.set('group_name', types.hdmf_common.VectorData(...
%         'data', allGroupNames, 'description', 'Name of the ElectrodeGroup'));
% 
% 
% 
%     % Row identifiers - required for every DynamicTable (0-indexed, int64)
%     combinedElecTable.id = types.hdmf_common.ElementIdentifiers('data', int64(0:(numel(allLocations)-1))');
% %     
    % create electrode table as ElectrodesTable object (new since NWB 2.8.0
    combinedElecTable=types.core.ElectrodesTable('description', 'All electrodes across ABR and IC recordings for this session' , ...
        'colnames', {'location', 'rel_z', 'group', 'group_name'},...
        'rel_z', types.hdmf_common.VectorData(...
        'data', allDepths, 'description', 'Depth in um along linear array from dorsal-most contact'),...
        'group_name', types.hdmf_common.VectorData(...
        'data', allGroupNames, 'description', 'Name of the ElectrodeGroup'),...
        'group', types.hdmf_common.VectorData(...
        'data', allGroups, 'description', 'Reference to the ElectrodeGroup'),...
        'id',types.hdmf_common.ElementIdentifiers('data', int64(0:(numel(allLocations)-1))'),...
        'location', types.hdmf_common.VectorData( 'data', cellstr(allLocations), 'description', 'Anatomical location/placement of electrode'));



    %  attach the table to the NWB file's canonical electrodes slot.
    nwb.general_extracellular_ephys_electrodes = combinedElecTable;

    % --- DynamicTableRegions ---
    abrElecRegion = types.hdmf_common.DynamicTableRegion(...
        'table', types.untyped.ObjectView(combinedElecTable), ...
        'description', 'differential ABR channel: vertex (active) vs retroauricular (reference)', ...
        'data', int64(0)); % row 0 = vertex

    icElecTableOffset = nABRelec; % IC electrodes start right after ABR's 3 rows
end