function FV = MyFlag(flagName, FV);
% MyFlag - collection of persistent variables for private use
%   set: MyFlag(flagName, FV);
%   get: val = MyFlag(flagName)
%   Default return value is [] (if flag has not been initialized).
%
%   Myflag('-all') lists all stored flags
%   Myflag('-clearall') clears all stored flags

persistent Flags
if isempty(Flags),
    Flags = struct;
end
if (nargin>1), % set
    Flags.(flagName) = FV;
elseif isequal('-all', flagName), % get all
    FV = Flags;
elseif isequal('-clearall', flagName), % get all
    clear Flags
elseif isfield(Flags, flagName), % get requested field
    FV = Flags.(flagName);
else % flagName not known yet; initialize to & return []
    Flags.(flagName) = [];
    FV = Flags.(flagName);
end

mlock; % prevent this file from being cleared by CLEAR
