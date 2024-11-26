function mono_vector = convert_to_mono(stereo_vector) 
  % Convert multi-channel vector to mono.

  num_samples = numel(stereo_vector(:,1));

  mono_vector = zeros(num_samples, 1);
  for ii = 1:num_samples
    mono_vector(ii, 1) = mean(stereo_vector(ii,:));
  end


end
