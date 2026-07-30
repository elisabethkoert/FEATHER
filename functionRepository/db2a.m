function A=db2a(dB);
% dB2A - convert dB to amplitude ratio
%    db2a(X) is the amplitude ratio corresponding to the dB value X, which is 10.^(X/20)

A = 10.^(0.05*dB);
