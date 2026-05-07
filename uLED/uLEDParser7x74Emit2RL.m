function output = uLEDParser7x74Emit2RL (input)
% output = uLEDParser (input)
% input is emitter, and the output is line and row.
%
%     LED    Row  Line
%      1     1     1
%      2     2     1
%      3     3     1
%      4     4     1
%      5     5     1
%      6     6     1
%      7     7     1
%      8     1     2
%      9     2     2
%     10     3     2
%     11     4     2
%     12     5     2
%     13     6     2
%     14     7     2
%     15     1     3
%     16     2     3
%     17     3     3
%     18     4     3
%     19     5     3
%     20     6     3
%     21     7     3
%     22     1     4
%     23     2     4
%     24     3     4
%     25     4     4
%     26     5     4
%     27     6     4
%     28     7     4
%     29     1     5
%     30     2     5
%     31     3     5
%     32     4     5
%     33     5     5
%     34     6     5
%     35     7     5
%     36     1     6
%     37     2     6
%     38     3     6
%     39     4     6
%     40     5     6
%     41     6     6
%     42     7     6
%     43     1     7
%     44     2     7
%     45     3     7
%     46     4     7
%     47     5     7
%     48     6     7
%     49     7     7
% 

emitterDistToProx = [1:49];
rowAddressed= [ 1 2 3 4 5 6 7 7 6 5 4 3 2 1 1 2 3 4 5 6 7 7 6 5 4 3 2 1 1 2 3 4 5 6 7 7 6 5 4 3 2 1 1 2  3 4 5 6 7  ];

lineAddressed= [   1     1     1     1     1     1     1     2     2     2     2     2     2     2     3     3     3     3     3     3     3     4     4     4     4     4     4     4     5 ...
    5     5     5     5     5     5     6     6     6     6     6     6     6     7     7     7     7     7     7 7];


output = nan(numel(input),2);
output(1:numel(input),1) = rowAddressed (input);%row
output(1:numel(input),2) = lineAddressed(input);%line

end


