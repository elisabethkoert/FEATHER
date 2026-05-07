function output = uLEDBin2N (input)
% output = uLEDParser (input)
% transfors the binary adress of the rows and collumns to numerical.
%      out   in
%      1     1
%      2     2
%      3     4
%      4     8
%      5    16
%      6    32
%      7    64
%      8   128
%for ii = 1 : numel()
output = log2(input)+1;

end