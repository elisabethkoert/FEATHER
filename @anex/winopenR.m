function winopenR (ee, dataType ) 
% WINOPENR(EE, DATATYPE) opens the directory window for raw data. This
% function is used to access the folder containing raw data for a specified
% data type.
%
%
% Parameters:
%   ee         - An ANEX (Animal Experiment) object
%
%   dataType   - (Optional) A string specifying the type of data. Possible
%   values include:
%                - "ABR": Auditory Brainstem Response - "IC": Inferior
%                Colliculus Electrophysiology Defaults to "ABR" if not
%                provided (nargin == 1).
%
% Usage:
%  winopenR(ee)                 % Opens the directory for "ABR" data by
%  default. 
%  winopenR(ee, "IC")           % Opens the directory for "IC" data.
%
% Notes:
%   - The function relies on `ee.RawDataDir.type` being correctly
%   structured
%     and containing valid paths for the specified data type.
%   - The directory window will only open if the specified dataType exists
%   in
%     `ee.RawDataDir.type`. Otherwise, an error is thrown.
%
% Author: Anna Vavakou, January 2025

if nargin==1
    dataType ="ABR";
end

winopen(gen_dir_name(ee.RawDataDir(find([ee.RawDataDir.type] ==dataType)).dir));

