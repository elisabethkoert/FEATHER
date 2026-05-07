function D = expProcDataDir(ExperimenterID,ExpID)
% genProcessedDataDir - generates the directory where the processed data
% for each experiment, under a specific user.
% Required inputs: ExperimenterID, expID
% The ukon mapp is retrieved by ukonmap function. It is a persistent variable.
% The path to the processedDataDir is also read out form the persistent
% variable
% example: for userID EK, experimenter 'test' and ExpID 'GEK030' 
%  'Z:\UKON100\public\Data\invivoelectrophysiologyFEATHER\EKdata\test\f_GEK030'

persistent Dstate

if nargin==2 %set
    % get the default path for IAN users
    Dstate = fullfile(processedDataMap,processedDataDirPath(),[userID 'data'],ExperimenterID,strcat('f_',ExpID));
end

if isempty(Dstate)
    Dstate = ''; %default is empty, saving things directly in the scripts folder
end

testSafeDir(Dstate)

D = Dstate;

end


