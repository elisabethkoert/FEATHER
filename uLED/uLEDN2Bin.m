function output = uLEDN2Bin (input)
% output = uLEDParser (input)
% transfors the numerical adress of the rows and collumns to binary.
%      in   out
%      1     1
%      2     2
%      3     4
%      4     8
%      5    16
%      6    32
%      7    64
%      8   128
output = 2^(input-1);
end