function D = gen_dir_name (Din)
% gen_dir_name - concatinates the mapped ukon drive letter with the
% directory string array.
% input:
% Din (1×n string array): name of the folders along the path
% output:
% D: (string): one single string wiht the path including the ukonmap and
% the appropiate / or \ depending on the operating system

D = fullfile(ukonmap, Din{:});

end