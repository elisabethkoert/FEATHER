function initKiwi(ee);
% anex/initKiwi - create and edit kiwi file for this anex
%    initkiwi(ee) creates (if needed) and edits kiwi file for OCT exp ee
%
%    See also octloc/kiwifile, ./edit.

[FN, Exists] = kiwiFile(ee);
if ~Exists,
    textWrite(FN, {['%======== ' char(ee.ExpID), ' kiwi =========='] ' '  ' '  ' '});
end
edit(FN);






