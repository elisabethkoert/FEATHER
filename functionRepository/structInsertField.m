function S = structinsertfield(S, newf, X, tf, Flag);
% structinsertfield - insert a field into a struct or struct array
%   S = structinsertfield(S, 'Foo1', X, 'Foo2') inserts field Foo1 having
%   value X into struct S. Foo1 immediately follows existing field Foo2.
%
%   S = structinsertfield(S, 'Foo1', X, 'Foo2', 'pre') puts Foo1 where it
%   just preceeds field Foo2.
%   S = structinsertfield(S, 'Foo1', X, 'Foo2', 'post') is the same as 
%   S = structinsertfield(S, 'Foo1', X, 'Foo2').
%
%   In case S is a struct array, X must be a cell array having the same
%   number of components as S.
%
%   See also structinstertstruct structPart, structmovefield.

[Flag] = arginDefaults('Flag', 'post');
[Flag, Mess] = keywordMatch(Flag, {'pre' 'post'}, 'position flag');
error(Mess);

if nargout<1,
    error('No argout used.');
end

if ~isstruct(S),
    error('S input arg must be struct.')
end
if numel(S)>1 && ~iscell(X),
    error('When S is an array, X must be a cell array.');
end
X = cellify(X); % now numel(S)==1 is no longer an exception

if isfield(S, newf),
    error(['S aready contains a field named ''' newf '''.']);
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
[S1.(newf)] = deal(X{:});
S2 = structpart(S, FNS(it+1:end));
S = structjoin(S1, S2);
  
% split and patch





