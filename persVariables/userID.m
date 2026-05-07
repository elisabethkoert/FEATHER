function E = userID(flag)
% userID - the initials of the user. 
%   AV: Anna vavakou
%   TH: Tori Hunninford
%   The cache state is remembered (using a global variable) during the
%   current matlab session, but not across sessions.


persistent Estate
if isempty(Estate)
    Estate = 'AV'; %default is on
end

if nargin>0, %set
    flag = upper(flag);
    Estate = flag;
end

if nargout>0 || nargin <1,
    E = Estate;
end
end


