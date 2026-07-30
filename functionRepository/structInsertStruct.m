function S = structinsertstruct(S, newS, tf, Flag);
% structinsertstruct - insert a struct into a struct or struct
%   S = structinsertfield(S, T, 'Foo') inserts the fields of struct T into
%   struct S at a position that immediately follows existing field Foo.
%
%   S = structinsertstruct(S, T, 'Foo', 'pre') puts T where it just preceeds
%   field Foo. 
%   S = structinsertstruct(S, T, 'Foo', 'post') is the same as 
%   S = structinsertstruct(S, T, 'Foo').
%
%   In case S is a struct array, if T is a struct it will be duplicated and
%   if it is a struct array its compoents will be inerted into the
%   corresponding components of S.
%
%   See also structinsertfield, structPart, structmovefield.

[Flag] = arginDefaults('Flag', 'post');
[Flag, Mess] = keywordMatch(Flag, {'pre' 'post'}, 'position flag');
error(Mess);

if nargout<1,
    error('No argout used.');
end

[S,newS] = samesize(S,newS);

if any(ismember(fieldnames(S), fieldnames(newS))),
    error('S and T are not allowed to have any fieldnames in common.');
end

% locate target field
FNS = fieldnames(S);
it = strmatch(tf, FNS, 'exact');
if isempty(it),
    error(['Field ''' tf ''' not found in struct.']);
end

if isequal('pre', Flag),
    it = it-1;
end
S1 = structpart(S, FNS(1:it));
S2 = structpart(S, FNS(it+1:end));
S = structjoin(S1, newS, S2);
  
% split and patch





