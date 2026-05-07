function output = uLEDParser4x4 (input)
% output = uLEDParser (input)
% if input size is (x,1) input is considered emitter, and the output is
% line and rows.
% is input size is (x,2) in put is consedered rows and lines and output is
% emitter.
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

inputSize = size(input,2); % the collumn size is indicatine of the input nature

switch inputSize

    case 1
        output = nan(inputSize(1),2);
        output(inputSize(1), 1) = rowAddressed (input);%row
        output(inputSize(1), 2) = lineAddressed(input);%line
    case 2
        output = nan(inputSize(1),1);
        pinline = [rowAddressed,lineAddressed];
        output = nan( size(input,1),1)
        for ii = 1 : size(input,1)
            output(ii) = emitterDistToProx(all(pinline == input(ii,:), 2));

        end
end
end





