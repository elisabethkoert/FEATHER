function testSafeDir(in_dir)
% testSafeDir - test if the raw directory includes 'archiv'.

if contains(in_dir,'archiv')==1
    error('YOU ARE TRYING TO STORE FEATHER DATA IN THE ARCHIV DOMAIN!!! ABORT' )
    return
end
end
