function output = uLEDParser7x7 (input)
% output = uLEDParser (input)
% if input size is (x,1) input is considered emitter, and the output is
% line and rows.
% is input size is (x,2) in put is consedered rows and lines and output is
% emitter.
%
% LED    Row  Line
% 1	    1	1
% 2	    2	1
% 3 	3	1
% 4	    4	1
% 5	    5	1
% 6	    6	1
% 7 	7	1
% 8	    7	2
% 9 	6	2
% 10	5	2
% 11	4	2
% 12	3	2
% 13	2	2
% 14	1	2
% 15	1	3
% 16	2	3
% 17	3	3
% 18	4	3
% 19	5	3
% 20	6	3
% 21	7	3
% 22	7	4
% 23	6	4
% 24	5	4
% 25	4	4
% 26	3	4
% 27	2	4
% 28	1	4
% 29	1	5
% 30	2	5
% 31	3	5
% 32	4	5
% 33	5	5
% 34	6	5
% 35	7	5
% 36	7	6
% 37	6	6
% 38	5	6
% 39	4	6
% 40	3	6
% 41	2	6
% 42	1	6
% 43	1	7
% 44	2	7
% 45	3	7
% 46	4	7
% 47	5	7
% 48	6	7
% 49	7	7

% 

emitterDistToProx = [1:49];
rowAddressed= [ 1 2 3 4 5 6 7 7 6 5 4 3 2 1 1 2 3 4 5 6 7 7 6 5 4 3 2 1 1 2 3 4 5 6 7 7 6 5 4 3 2 1 1 2  3 4 5 6 7  ];

lineAddressed= [   1     1     1     1     1     1     1     2     2     2     2     2     2     2     3     3     3     3     3     3     3     4     4     4     4     4     4     4     5 ...
    5     5     5     5     5     5     6     6     6     6     6     6     6     7     7     7     7     7     7 7];


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


