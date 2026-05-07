function output = uLEDParser7x7RL2Emit (inRow, inLine)
% output = uLEDParser (input)
% input is rows and lines and output is emitter.
% LED	N(line)	P (row)
% 1	    1	1
% 2	    1	2
% 3 	1	3
% 4	    1	4
% 5	    1	5
% 6	    1	6
% 7	    1	7
% 8	    2	7
% 9	    2	6
% 10	2	5
% 11	2	4
% 12	2	3
% 13	2	2
% 14	2	1
% 15	3	1
% 16	3	2
% 17	3	3
% 18	3	4
% 19	3	5
% 20	3	6
% 21	3	7
% 22	4	7
% 23	4	6
% 24	4	5
% 25	4	4
% 26	4	3
% 27	4	2
% 28	4	1
% 29	5	1
% 30	5	2
% 31	5	3
% 32	5	4
% 33	5	5
% 34	5	6
% 35	5	7
% 36	6	7
% 37	6	6
% 38	6	5
% 39	6	4
% 40	6	3
% 41	6	2
% 42	6	1
% 43	7	1
% 44	7	2
% 45	7	3
% 46	7	4
% 47	7	5
% 48	7	6
% 49	7	7



emitterDistToProx = [1:49]';
rowAddressed= [ 1 2 3 4 5 6 7 7 6 5 4 3 2 1 1 2 3 4 5 6 7 7 6 5 4 3 2 1 1 2 3 4 5 6 7 7 6 5 4 3 2 1 1 2  3 4 5 6 7  ]'
lineAddressed= [   1     1     1     1     1     1     1     2     2     2     2     2     2     2     3     3     3     3     3     3     3     4     4     4     4     4     4     4     5 ...
    5     5     5     5     5     5     6     6     6     6     6     6     6     7     7     7     7     7     7 7]';

pinline = [rowAddressed,lineAddressed];
output = nan( numel(inRow),1);
for ii = 1 : numel(inRow)
    output(ii) = emitterDistToProx(all(pinline == [inRow(ii),inLine(ii)], 2));

end

end

