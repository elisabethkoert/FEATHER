function IC = loadArtWave(IC, filtFlag )
% the raw wavform following the trigger for 500ms is stored in R

load_name = strcat(IC.SeriesID,"_","filt",num2str(filtFlag),".mat");

LO = load(fullfile(expProcDataDir,load_name));%loaded object
IC.R(1).artWav = LO.artWav;



end
