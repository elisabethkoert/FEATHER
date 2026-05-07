function output = creeLEDParser10x1RL2Emit (inRow, inLine)
% output = uLEDParser (input)
% input is rows and lines and output is emitter.
%
%     LED    Row  Line
%      1     1     1
%      2     1     2
%      3     1     3
%      4     1     4
%      5     1     5
%      6     1     6
%      7     1     7
%      8     1     8
%      9     1     9
%     10     1     10


emitterDistToProx = [1:10]';
rowAddressed= [1 1 1 1 1 1 1 1 1 1]';
lineAddressed= [1 2 3 4 5 6 7 8 9 10]';


pinline = [rowAddressed,lineAddressed];
output = nan( numel(inRow),1);
for ii = 1 : numel(inRow)
    output(ii) = emitterDistToProx(all(pinline == [inRow(ii),inLine(ii)], 2));

end

end





