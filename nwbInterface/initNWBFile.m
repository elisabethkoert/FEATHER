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
    if isempty(L.dateID_ABR)
        warning('No ABR data found to determine session_start_time. Using now().');
        sessionStart = datetime('now');
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

    if ee.ExpMetaData.Gender == 'female'
        sex = 'F';
    elseif ee.ExpMetaData.Gender == 'male'
        sex = 'M';
    else
        sex = 'unknown';
    end

    %% Construct / Injection Info
    if isfield(ee.ExpMetaData, 'Construct') && ~isempty(ee.ExpMetaData.Construct)
        if isfield(ee.ExpMetaData, 'DateOfInjection') && ~isempty(ee.ExpMetaData.DateOfInjection)
            injectionAgeStr = sprintf('P%iD', days(ee.ExpMetaData.DateOfInjection - ee.ExpMetaData.DateOfBirth));
        else
            injectionAgeStr = 'unknown age';
            warning('%s: DateOfInjection missing.', ee.ExpID);
        end
        constructDescr = sprintf('virus injected with %s at %s', ee.ExpMetaData.Construct, injectionAgeStr);
        if isfield(ee.ExpMetaData, 'Titer') && ~isempty(ee.ExpMetaData.Titer)
            constructDescr = sprintf('%s (titer: %s)', constructDescr, string(ee.ExpMetaData.Titer));
        end
    else
        constructDescr = 'no virus injection recorded';
    end

    %% Create Subject
    subject = types.core.Subject( ...
        'subject_id', sprintf('%s', ee.ExpID), ...
        'age', sprintf('P%iD', ee.ExpMetaData.AgeDays), ...
        'age_reference', 'birth', ...
        'date_of_birth', ee.ExpMetaData.DateOfBirth, ...
        'species', species, ...
        'genotype', 'WT', ...
        'description', constructDescr, ...
        'sex', sex ...
    );
    nwb.general_subject = subject;
end