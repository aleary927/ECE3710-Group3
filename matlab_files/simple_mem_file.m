files = ["../sound_files/wavbvkery - dreams hip hop drum kit/claps/wavbvkery - dreams clap 01.wav" 
        "../sound_files/wavbvkery - dreams hip hop drum kit/kicks/wavbvkery - dreams kick 05.wav" 
        "../sound_files/wavbvkery - dreams hip hop drum kit/cymbals/hats open/wavbvkery - dreams open hat 01.wav"
        "../sound_files/wavbvkery - dreams hip hop drum kit/snares/wavbvkery - dreams snare 08.wav"]; 

% files = cellstr(files);

gen_mem_file(files, 0.9, 44100, '../mem_files/basic_drums.dat', 2^16)

