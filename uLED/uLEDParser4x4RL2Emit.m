function output = uLEDParser4x4RL2Emit (inRow, inLine)
% output = uLEDParser (input)
% input is rows and lines and output is emitter.
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


pinline = [rowAddressed,lineAddressed];
output = nan( numel(inRow),1);
for ii = 1 : numel(inRow)
    output(ii) = emitterDistToProx(all(pinline == [inRow(ii),inLine(ii)], 2));

end

end





