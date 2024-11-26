function gen_mem_file(input_files, scale, fs_target, output_file, mem_size)
  % Generate a memory file from a list of input files.
  % Writes the output out to a single file
  %
  % scale: from 0 to 1, percent of max that can be represented in 16-bit 2's complment
  % fs_target: target samle rate

  fd = fopen(output_file, 'w');

  count = 0;
  address = 0;
  for jj = 1:numel(input_files)
    disp(input_files(jj));
    [audio, fs] = audioread(input_files(jj));

    % resample if necessary
    if fs ~= fs_target 
      fprintf("Changing sample rate from %d Hz to %d Hz", fs, fs_target);
      audio = change_sample_rate(audio, fs, fs_target);
    end

    % convert to mono
    audio = convert_to_mono(audio);
    
    % scale audio vector
    scale_factor = scale * (2^15 - 1);
    audio = audio .* scale_factor;

    % trim trailing zeros 
    ii = find(audio, 1, 'last');  % last non-zero
    fprintf("stripping %d samples off end\n", numel(audio) - ii)
    audio = audio(1:ii,1);

    % convert to hex 
    hexstr = cellstr(dec2hex(int16(floor(audio)), 4));
    % hexstr = cellstr(dec2bin(int32(audio), 16));

    sample_length = numel(hexstr);

    % write to file 
    fprintf(fd, "%s\n", hexstr{:});

    fprintf("Sample %d start address: %x \n", count, address);
    fprintf("End address: %x \n", address + sample_length - 1);
    fprintf("Length: %x \n", sample_length);
    fprintf("-------------------------------------\n");

    address = address + sample_length;
    count = count + 1;
  end

  % pad with zeros
  extra_size = mem_size - address;
  zero_padding = zeros(extra_size, 1); 
  hexstr = cellstr(dec2hex(int32(zero_padding), 4));
  % hexstr = cellstr(dec2bin(int32(zero_padding), 16));
  fprintf(fd, "%s\n", hexstr{:});

  fclose(fd);

end
