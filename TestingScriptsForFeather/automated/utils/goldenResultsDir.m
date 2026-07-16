function d = goldenResultsDir(testType)
here = fileparts(mfilename('fullpath'));       % .../automated/utils
d = fullfile(here, '..', 'golden', testType);
end