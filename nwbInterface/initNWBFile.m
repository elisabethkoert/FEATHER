function [nwb, sessionStart] = initNWBFile(ee)
% initNWBFile  Creates the NwbFile object and populates session/subject metadata.
%% ========================================================================
%  SESSION & SUBJECT METADATA
%  Creates the top-level NWB file container (session) and describes the
%  animal (subject connected to the session)
%  ========================================================================

    %% Session Start Time
    % Use the earliest ABR date as the session anchor
    L = listBerabr(ee);
    if isempty(L.dateID_ABR) || ~isa(L.dateID_ABR, 'datetime') 
        warning('No ABR data found to determine session_start_time. Using now().');
        enablecache off
        L_IC=listIcme(ee);
        enablecache on
         if isempty(L_IC.IC_SeriesID) 
                warning('No IC data found to determine session_start_time. Using dummy time.');
                sessionStart =datetime('01.01.1111');
            else
                sessionStart = min(L_IC.allDates_IC);
            end
    else
        sessionStart = L.dateID_ABR;
    end

    %% Create NWB Session
    nwb = NwbFile( ...
        'session_description', sprintf(...
        ['Evaluating Optogenetic Stimulation of Auditory System for %s. ' ...
         'session_start_time corresponds to onset of first ABR recording; ' ...
         'anesthesia induction preceded this by approximately 10-20 minutes (not precisely logged).'], ...
        ee.ExpID), ...   
        'identifier', sprintf('%s', ee.ExpID), ...
        'session_start_time', sessionStart, ...
        'general_experimenter', {char(ee.ExperimenterID)}, ...
        'general_lab', 'Institute for Auditory Neuroscience', ...
        'general_institution', 'University Medical Center Goettingen');

    %% Species/sex mapping
    if ee.Species == 'gerbil'
        species = 'Meriones unguiculatus';
    elseif ee.Species == 'mouse'
        species = 'Mus musculus';
    else
        species = 'unknown';
    end

    if isfield(ee.ExpMetaData,'Gender')
        if strcmp(ee.ExpMetaData.Gender,'female')
            sex = 'F';
        elseif strcmp(ee.ExpMetaData.Gender,'male')
            sex = 'M';
        else
            sex = 'unknown';
        end
    else
        sex = 'unknown';    
    end

    %% Construct / Injection Info
    if isfield(ee.ExpMetaData, 'Construct') && ~isempty(ee.ExpMetaData.Construct)
        if isfield(ee.ExpMetaData, 'DateOfInjection') && ~isempty(ee.ExpMetaData.DateOfInjection) && ~strcmp(ee.ExpMetaData.DateOfInjection,'unknown')
            injectionAgeStr = sprintf('P%iD', days(ee.ExpMetaData.DateOfInjection - ee.ExpMetaData.DateOfBirth));
        else
            injectionAgeStr = 'unknown age';
            warning('%s: DateOfInjection missing.', ee.ExpID);
        end
        constructDescr = sprintf('virus injected with %s at %s', ee.ExpMetaData.Construct, injectionAgeStr);
        if isfield(ee.ExpMetaData, 'Titer') && ~isempty(ee.ExpMetaData.Titer)  && ~strcmp(ee.ExpMetaData.Titer,'unknown')
            constructDescr = sprintf('%s (titer: %s)', constructDescr, string(ee.ExpMetaData.Titer));
        end
    else
        constructDescr = 'no virus injection recorded';
    end

    if isfield(ee.ExpMetaData, 'AgeDays') && ~isempty(ee.ExpMetaData.AgeDays)  && ~strcmp(ee.ExpMetaData.AgeDays,'unknown')
        ageStr=sprintf('P%iD', ee.ExpMetaData.AgeDays);
    else
        ageStr='unknown';
    end

    if isfield(ee.ExpMetaData, 'AgeDays') && ~isempty(ee.ExpMetaData.AgeDays)  && ~strcmp(ee.ExpMetaData.AgeDays,'unknown')
        ageStr=sprintf('P%iD', ee.ExpMetaData.AgeDays);
    else
        ageStr='unknown';
    end
    
    if isfield(ee.ExpMetaData, 'AgeDays') && ~isempty(ee.ExpMetaData.AgeDays)  && ~strcmp(ee.ExpMetaData.AgeDays,'unknown')
        DoB=ee.ExpMetaData.DateOfBirth;
    else
        DoB=sessionStart;% dummy value if it is missing
    end


    %% Create Subject
    subject = types.core.Subject( ...
        'subject_id', sprintf('%s', ee.ExpID), ...
        'age',ageStr , ...
        'age_reference', 'birth', ...
        'date_of_birth', DoB, ...
        'species', species, ...
        'genotype', 'WT', ...
        'description', constructDescr, ...
        'sex', sex ...
    );

   


    nwb.general_subject = subject;
end