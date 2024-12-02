function change_file_sample_rate(input_file, output_file, fs_out) 
  % Take an input signal with given sample rate, and 
  % print it out to file with new sample rate.

  [original_signal, fs_in] = audioread(input_file);

  if fs_in == fs_out 
    disp("Sample rate matches orignal (%dHz).", fs_in)
    disp("no action taken.")
    return
  end

  resampled_signal = change_sample_rate(original_signal, fs_in, fs_out);

  audiowrite(output_file, resampled_signal, fs_out)


end
