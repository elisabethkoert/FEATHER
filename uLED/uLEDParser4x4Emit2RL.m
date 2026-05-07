function output = uLEDParser4x4Emit2RL (input)
% output = uLEDParser (input)
% input is emitter, and the output is line and row.
%
%     LED    Row  Line
%      1     7     4
%      2     6     4
%      3     3     4
%      4     4     4
%      5     4     1
%      6     3     1
%      7     6     1
%      8     7     1
%      9     7     5
%     10     6     5
%     11     3     5
%     12     4     5
%     13     4     7
%     14     3     7
%     15     6     7
%     16     7     7

emitterDistToProx = [1:16]';
rowAddressed= [7 6 3 4 4 3 6 7 7 6 3 4 4 3 6 7]';
lineAddressed= [4 4 4 4 1 1 1 1 5 5 5 5 7 7 7 7]';
output = nan(numel(input),2);
output(1:numel(input),1) = rowAddressed (input);%row
output(1:numel(input),2) = lineAddressed(input);%line

end





