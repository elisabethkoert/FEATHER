function str = trimSpace(str);
% TRIMSPACE - remove leading and trailing space and substitute single space for multiple space
%     TRIMSPACE(S) removes any leading or trailing whitespace from S and
%     replaces any multiple blanks by single blank.
%     is S is cellstring, its elements are trimspaced.
%
%     See also FixLenStr.

if iscellstr(str),
    for ii=1:numel(str),
        str{ii} = trimspace(str{ii});
    end
end
if ~ischar(str), return; end;
if isempty(str), return; end;

% remove heading space
while isspace(str(1)),
   str(1) = '';
   if isempty(str), str=''; return; end
end
% remove trailing space
while isspace(str(end)),
   str(end) = '';
   if isempty(str), str=''; return; end
end

% iterate substitution '  ' -> ' '
while 1,
   dd = findstr('  ',str);
   if isempty(dd), break ; end
   str(dd(1)) = '';
end

