function [FN, X] = kiwiFile(ee);
% anex/kiwifile - full path of kiwi file for anex
%    kiwiFile(EE) returns the full path of the kiwi file anex EE.
%
%    [FN, Exists] = kiwiFile(EE) also returns logical Exists which equals
%    logical(exist(FN,'file')).
%
%    See also ./kiwifile, ./initKiwi, 

FN = fullfile(char(expProcDataDir),[char(ee.ExpID) '_kiwi.m']);
X = logical(exist(FN, 'file'));






