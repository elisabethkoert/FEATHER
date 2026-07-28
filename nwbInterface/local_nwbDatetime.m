function dt = local_nwbDatetime(val)
% local_nwbDatetime  Robustly convert an NWB date/time value to a MATLAB
% datetime, regardless of whether matNWB returns it as:
%   - a native datetime          (newer matNWB versions)
%   - a DataStub                 (older matNWB versions, scalar HDF5 strings)
%   - a char / string            (edge case)
%
% NWB stores datetimes as ISO 8601 strings, e.g.:
%   '2024-03-12T09:15:00.000000+01:00'
%   '2024-03-12T09:15:00+00:00'
%   '2024-03-12'                        (date_of_birth, no time component)
%
% The returned datetime is always unzoned (TimeZone removed) so that
% arithmetic with other unzoned datetimes in the pipeline works without
% timezone mismatch errors.

if isa(val, 'datetime')
    dt = val;
    dt.TimeZone = '';
    return
end

% DataStub or char/string: load the raw value
if isa(val, 'types.untyped.DataStub')
    raw = val.load();
else
    raw = val;
end

% raw may be char, string, or a cell wrapping one of those
if iscell(raw)
    raw = raw{1};
end
raw = strtrim(char(raw));

% Try full ISO 8601 datetime first, then date-only fallback
try
    % Remove timezone offset for unzoned parsing
    % Strip trailing +HH:MM or -HH:MM or Z
    rawClean = regexprep(raw, '([+-]\d{2}:\d{2}|Z)$', '');
    if contains(rawClean, 'T')
        dt = datetime(rawClean, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS');
    else
        % Date only (e.g. date_of_birth stored without time component)
        dt = datetime(rawClean, 'InputFormat', 'yyyy-MM-dd');
    end
catch
    % Last resort: let MATLAB guess
    dt = datetime(raw);
end

dt.TimeZone = '';
end